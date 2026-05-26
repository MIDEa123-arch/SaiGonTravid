import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/place.dart';
import 'package:travel_app/models/place_detail.dart';
import 'package:travel_app/services.dart/api_service.dart';
import 'package:travel_app/widgets/custom_image.dart';
import 'package:travel_app/screens/place_detail/place_detail_screen.dart';

class NearbyPlacesSection extends StatefulWidget {
  final PlaceDetail place;
  final double? userLat;
  final double? userLng;

  const NearbyPlacesSection({
    super.key,
    required this.place,
    this.userLat,
    this.userLng,
  });

  @override
  State<NearbyPlacesSection> createState() => _NearbyPlacesSectionState();
}

class _NearbyPlacesSectionState extends State<NearbyPlacesSection> {
  final ApiService _api = ApiService();
  List<Place> _categoryPlaces = [];
  List<Place> _topPlaces = [];
  bool _isLoadingCategory = true;
  bool _isLoadingTop = true;
  String _suggestCategoryName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Phân tích gợi ý địa điểm theo logic tâm lý người dùng
    if (widget.place.categoryGroup != null &&
        widget.place.lat != null &&
        widget.place.lng != null) {
      int currentId = widget.place.categoryGroup!.categoryGroupId;
      int suggestId;
      String suggestName;

      switch (currentId) {
        case 59: // Văn hóa & Lịch sử -> Ẩm thực
          suggestId = 63;
          suggestName = 'Nhà hàng';
          break;
        case 64: // Thiên nhiên & Công viên -> Đồ uống & Ăn vặt
          suggestId = 62;
          suggestName = 'Đồ uống & Ăn vặt';
          break;
        case 60: // Thể thao & Thư giãn -> Đồ uống & Ăn vặt
          suggestId = 62;
          suggestName = 'Đồ uống & Ăn vặt';
          break;
        case 63: // Ẩm thực -> Đồ uống & Ăn vặt
          suggestId = 62;
          suggestName = 'Đồ uống & Ăn vặt';
          break;
        case 62: // Đồ uống & Ăn vặt -> Giải trí
          suggestId = 61;
          suggestName = 'Giải trí';
          break;
        case 65: // Lưu trú -> Ẩm thực
          suggestId = 63;
          suggestName = 'Nhà hàng';
          break;
        case 61: // Giải trí
        case 66: // Mua sắm
          suggestId = 62; // Đồ uống & Ăn vặt
          suggestName = 'Đồ uống & Ăn vặt';
          break;
        default:
          suggestId = 63;
          suggestName = 'Nhà hàng';
          break;
      }

      final places = await _api.getPlacesByCategoryAndLocation(
        suggestId,
        widget.place.lat!,
        widget.place.lng!,
      );
      // Lọc bỏ chính địa điểm đang xem (nếu vô tình trùng)
      places.removeWhere((p) => p.id == widget.place.placeId);
      
      if (mounted) {
        setState(() {
          _categoryPlaces = places;
          _suggestCategoryName = suggestName;
          _isLoadingCategory = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingCategory = false);
      }
    }

    // 2. Top nearby tourist places (near user's location, or near the place if user location unknown)
    double searchLat = widget.userLat ?? widget.place.lat ?? 10.7769;
    double searchLng = widget.userLng ?? widget.place.lng ?? 106.7009;

    // Use category 59 (Văn hoá & Lịch sử) as "Điểm du lịch" or just get all nearby places
    final top = await _api.getAllNearbyPlaces(searchLat, searchLng);
    top.removeWhere((p) => p.id == widget.place.placeId);

    if (mounted) {
      setState(() {
        _topPlaces = top;
        _isLoadingTop = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_isLoadingCategory && _categoryPlaces.isNotEmpty)
          _buildListSection('$_suggestCategoryName lân cận', _categoryPlaces),
        if (!_isLoadingTop && _topPlaces.isNotEmpty)
          _buildListSection('Điểm du lịch lân cận', _topPlaces),
      ],
    );
  }

  Widget _buildListSection(String title, List<Place> places) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 0), // Đã giảm padding để sát nhau hơn
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80, // Chiều cao của thẻ nhỏ lại
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: places.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                return _buildPlaceCard(places[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Place place) {
    // 1. Khoảng cách
    String distanceStr = place.getDistanceDisplay(widget.userLat, widget.userLng);
    if (distanceStr.isEmpty) {
      // Nếu không có khoảng cách GPS, tạm dùng distance=0 hoặc không hiện
      distanceStr = 'Gần đây';
    }

    // 2. Khoảng giá (hiện trực tiếp từ DB)
    String priceStr = place.priceRange != null && place.priceRange!.isNotEmpty
        ? ' • ${place.priceRange}'
        : '';

    // 3. Loại hình (placeType)
    String typeStr = place.placeType != null && place.placeType!.isNotEmpty
        ? ' • ${place.placeType}'
        : '';

    String subtitle = '$distanceStr$priceStr$typeStr';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceDetailScreen(
              placeId: place.id,
              heroImageUrl: place.imageUrl,
            ),
          ),
        );
      },
      child: Container(
        width: 260, // Nhỏ lại
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CustomImage(
                imageUrl: place.imageUrl,
                width: 70, // Ảnh nhỏ lại
                height: 70, // Ảnh nhỏ lại
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            // Thông tin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Rating
                  Row(
                    children: [
                      Text(
                        place.avgRating.toStringAsFixed(1).replaceAll('.', ','),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildRatingDots(place.avgRating),
                      const SizedBox(width: 4),
                      Text(
                        '(${place.totalReviews})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Details (Khoảng cách • Khoảng giá • Loại hình)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingDots(double rating) {
    int fullDots = rating.floor();
    bool hasHalfDot = (rating - fullDots) >= 0.5;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullDots) {
          return const Padding(
            padding: EdgeInsets.only(right: 2),
            child: Icon(Icons.circle, color: AppColors.primaryEmerald, size: 10),
          );
        } else if (index == fullDots && hasHalfDot) {
          return const Padding(
            padding: EdgeInsets.only(right: 2),
            child: Icon(Icons.incomplete_circle, color: AppColors.primaryEmerald, size: 10),
          );
        } else {
          return const Padding(
            padding: EdgeInsets.only(right: 2),
            child: Icon(Icons.circle_outlined, color: AppColors.primaryEmerald, size: 10),
          );
        }
      }),
    );
  }
}
