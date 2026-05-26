import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:travel_app/models/place.dart';
import 'package:travel_app/widgets/custom_image.dart';

class Step3ConfirmationWidget extends StatefulWidget {
  final String? currentAddress;
  final double? lat;
  final double? lng;
  final DateTime startDate;
  final int numDays;
  final Map<int, List<Place>> dayPlaces;
  final TextEditingController nameController;
  final TextEditingController noteController;
  final VoidCallback onRefreshLocation;

  const Step3ConfirmationWidget({
    super.key,
    this.currentAddress,
    this.lat,
    this.lng,
    required this.startDate,
    required this.numDays,
    required this.dayPlaces,
    required this.nameController,
    required this.noteController,
    required this.onRefreshLocation,
  });

  @override
  State<Step3ConfirmationWidget> createState() =>
      _Step3ConfirmationWidgetState();
}

class _Step3ConfirmationWidgetState extends State<Step3ConfirmationWidget> {
  int _selectedDay = 0; // Ngày đang được chọn để hiển thị trên map
  final MapController _mapController = MapController();

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  // Lấy các địa điểm có toạ độ của ngày đang chọn
  List<Place> get _placesWithCoords {
    final places = widget.dayPlaces[_selectedDay] ?? [];
    return places.where((p) => p.lat != null && p.lng != null).toList();
  }

  // Tính trung tâm map từ các điểm
  LatLng get _mapCenter {
    if (_placesWithCoords.isNotEmpty) {
      final avgLat =
          _placesWithCoords.map((p) => p.lat!).reduce((a, b) => a + b) /
          _placesWithCoords.length;
      final avgLng =
          _placesWithCoords.map((p) => p.lng!).reduce((a, b) => a + b) /
          _placesWithCoords.length;
      return LatLng(avgLat, avgLng);
    }
    return LatLng(widget.lat ?? 10.8231, widget.lng ?? 106.6297);
  }

  void _selectDay(int dayIndex) {
    setState(() => _selectedDay = dayIndex);
    // Fly map tới trung tâm ngày mới
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_placesWithCoords.isNotEmpty) {
        _mapController.move(_mapCenter, 14.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF00D186);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ══════════════════════════════════════════════════
        // 1. MAP PREVIEW
        // ══════════════════════════════════════════════════
        SizedBox(
          height: 260,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _mapCenter,
                  initialZoom: 13.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),

                  // Đường nối các địa điểm theo thứ tự bằng dấu ---
                  if (_placesWithCoords.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _placesWithCoords
                              .map((p) => LatLng(p.lat!, p.lng!))
                              .toList(),
                          color: primaryColor,
                          strokeWidth: 2.5,
                          strokeCap: StrokeCap
                              .round, // Thêm cái này cho đầu đường nối nó tròn, đẹp hơn
                          strokeJoin: StrokeJoin.round,
                        ),
                      ],
                    ),

                  // Markers địa điểm với số thứ tự
                  MarkerLayer(
                    markers: _placesWithCoords.asMap().entries.map((entry) {
                      final i = entry.key;
                      final place = entry.value;
                      return Marker(
                        point: LatLng(place.lat!, place.lng!),
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 4),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Label ngày hiện tại trên map
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _placesWithCoords.isEmpty
                        ? 'Ngày ${_selectedDay + 1} – Chưa có địa điểm'
                        : 'Ngày ${_selectedDay + 1} · ${_placesWithCoords.length} địa điểm',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ══════════════════════════════════════════════════
        // 2. TÊN CHUYẾN ĐI & GHI CHÚ
        // ══════════════════════════════════════════════════
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Tên chuyến đi ---
              Row(
                children: [
                  const Text(
                    'Tên chuyến đi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_note_rounded,
                    color: Colors.blue.withOpacity(0.7),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: widget.nameController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Đặt tên để lưu giữ kỷ niệm...',
                  hintStyle: TextStyle(color: Colors.grey[700]),
                  filled: true,
                  fillColor: const Color(0xFF1C1C1C),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Ghi chú ---
              const Text(
                'Ghi chú thêm',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: widget.noteController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Ngân sách, yêu cầu đặc biệt, lưu ý...',
                  hintStyle: TextStyle(color: Colors.grey[700]),
                  filled: true,
                  fillColor: const Color(0xFF1C1C1C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 0.8,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),

        // ══════════════════════════════════════════════════
        // 3. DANH SÁCH NGÀY – bấm vào ngày để xem map
        // ══════════════════════════════════════════════════
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.numDays,
            itemBuilder: (context, dayIndex) {
              final currentDate = widget.startDate.add(
                Duration(days: dayIndex),
              );
              final places = widget.dayPlaces[dayIndex] ?? [];
              final isSelected = _selectedDay == dayIndex;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header ngày (bấm vào để chọn hiển thị map)
                    GestureDetector(
                      onTap: () => _selectDay(dayIndex),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Ngày ${dayIndex + 1}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Đang xem',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                _formatDate(currentDate),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.map_outlined,
                            color: isSelected ? primaryColor : Colors.grey[600],
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (places.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: const Center(
                          child: Text(
                            'Chưa có địa điểm nào',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: places.length,
                        itemBuilder: (context, index) {
                          final place = places[index];
                          final isLast = index == places.length - 1;
                          return Column(
                            children: [
                              _buildPlaceItem(place, index),
                              // Dấu --- nối giữa các địa điểm
                              if (!isLast)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 27),
                                      ...List.generate(
                                        6,
                                        (_) => Padding(
                                          padding: const EdgeInsets.only(
                                            right: 3,
                                          ),
                                          child: Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: primaryColor.withOpacity(
                                                0.5,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.transparent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPlaceItem(Place place, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Ảnh + Badge số thứ tự
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomImage(
                  imageUrl: place.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00D186),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFF00D186),
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${place.avgRating}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        place.address ?? 'Đang cập nhật',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
