import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_app/screens/nearby/widgets/discover_bottom_sheet.dart';
import 'package:travel_app/services.dart/api_service.dart';
import '../../core/app_colors.dart';
import '../../models/place.dart';
import '../../models/category.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final MapController _mapController = MapController();
  final ValueNotifier<double> _zoomNotifier = ValueNotifier<double>(15.0);

  List<Place> _nearbyPlaces = [];
  bool _isLoading = true;
  LatLng _currentLocation = const LatLng(10.8231, 106.6297);
  int? _selectedCategoryId;
  List<CategoryGroup> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    // Sửa lỗi flutter_map bản mới (v8): Lắng nghe sự kiện zoom qua stream
    _mapController.mapEventStream.listen((event) {
      if (mounted) {
        _zoomNotifier.value = event.camera.zoom;
      }
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final categories = await ApiService().getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }

      // Kiểm tra và xin quyền trước
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Tránh treo trên emulator
      );

      LatLng userLatLng = LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _currentLocation = userLatLng;
      });

      final places = await ApiService().getAllNearbyPlaces(
        userLatLng.latitude,
        userLatLng.longitude,
      );

      if (!mounted) return;
      setState(() {
        _nearbyPlaces = places;
        _isLoading = false;
      });

      _mapController.move(userLatLng, 15.0);
    } catch (e) {
      debugPrint("Lỗi GPS (dùng toạ độ mặc định TP.HCM): $e");
      // FALLBACK: Load API với toạ độ mặc định (TP.HCM) nếu không lấy được GPS
      final places = await ApiService().getAllNearbyPlaces(
        _currentLocation.latitude,
        _currentLocation.longitude,
      );

      if (!mounted) return;
      setState(() {
        _nearbyPlaces = places;
        _isLoading = false;
      });
      _mapController.move(_currentLocation, 15.0);
    }
  }

  // ĐÃ FIX LỖI: Ép kiểu dữ liệu an toàn để không bị văng ra default
  IconData _getIconForCategory(dynamic id) {
    if (id == null) return Icons.place_outlined;

    // Ép về int phòng trường hợp Backend trả về String "250"
    int? categoryId = int.tryParse(id.toString());

    switch (categoryId) {
      case 1952:
        return Icons.local_activity_outlined;
      case 376:
        return Icons.shopping_bag_outlined;
      case 1767:
        return Icons.spa_outlined;
      case 45:
        return Icons.nightlife_outlined;
      case 260:
        return Icons.sports_soccer_outlined;
      case 250:
        return Icons.local_cafe_outlined;
      case 1:
        return Icons.restaurant_outlined;
      case 209:
        return Icons.explore_outlined;
      default:
        return Icons.place_outlined; // Mặc định
    }
  }

  Widget _buildFullMarker(Place place) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 5, spreadRadius: 2),
            ],
          ),
          child: Icon(
            _getIconForCategory(place.categoryId),
            color: Colors.black87,
            size: 20,
          ),
        ),
        Positioned(
          right: -10,
          top: -5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryEmerald,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Text(
              place.avgRating.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDotMarker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryEmerald,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4, spreadRadius: 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 1. MAP
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 15.0,                
              ),
              children: [
                // ĐÃ ĐỔI TỪ dark_all SANG light_all
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.blueAccent, blurRadius: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                ValueListenableBuilder<double>(
                  valueListenable: _zoomNotifier,
                  builder: (context, zoom, child) {
                    return MarkerLayer(
                      markers: _nearbyPlaces
                          .where((p) => p.lat != null && p.lng != null && (_selectedCategoryId == null || p.categoryId == _selectedCategoryId))
                          .map((place) {
                            bool isDetailed = zoom >= 14.5;
                            return Marker(
                              point: LatLng(place.lat!, place.lng!),
                              width: isDetailed ? 60 : 15,
                              height: isDetailed ? 60 : 15,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                // Thêm ValueKey để Flutter biết lúc nào cần đổi Animation
                                child: isDetailed
                                    ? KeyedSubtree(
                                        key: ValueKey('full_${place.id}'),
                                        child: _buildFullMarker(place),
                                      )
                                    : KeyedSubtree(
                                        key: ValueKey('dot_${place.id}'),
                                        child: _buildDotMarker(),
                                      ),
                              ),
                            );
                          })
                          .toList(),
                    );
                  },
                ),
              ],
            ),

            // 2. NÚT ĐỊNH VỊ
            Positioned(
              top: 20,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton(
                    mini: true,
                    heroTag: "btn1",
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.gps_fixed, color: Colors.black),
                    onPressed: () =>
                        _mapController.move(_currentLocation, 16.0),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
                    mini: true,
                    heroTag: "btn2",
                    backgroundColor: Colors.white,
                    child: const Text(
                      "3D",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // 3. THANH SEARCH
            Positioned(
              top: 20,
              left: 16,
              right: 70,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 15),
                    Icon(Icons.search, color: Colors.black54),
                    SizedBox(width: 10),
                    Text(
                      "Thành phố Hồ Chí Minh",
                      style: TextStyle(
                        color: Color.fromARGB(221, 109, 109, 109),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            DraggableScrollableSheet(
              initialChildSize: 0.15,
              minChildSize: 0.15,
              maxChildSize: 1.0,
              snap: true,
              snapSizes: const [0.15, 0.5, 1.0],
              builder: (context, scrollController) {
                return DiscoverBottomSheet(
                  userLat: _currentLocation.latitude,
                  userLng: _currentLocation.longitude,
                  scrollController: scrollController,
                  nearbyPlaces: _nearbyPlaces,
                  isLoading: _isLoading,
                  categories: _categories,
                  onFilterChanged: (int? categoryId) {
                    setState(() {
                      _selectedCategoryId = categoryId;
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
