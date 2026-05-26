import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/place.dart';
import 'package:travel_app/screens/trips/widgets/place_selection.dart';
import 'package:travel_app/widgets/custom_image.dart';

class Step2ItineraryWidget extends StatelessWidget {
  final int numDays;
  final DateTime startDate;
  final Map<int, List<Place>> dayPlaces;
  final List<Place> popularPlaces;
  final Function(int, List<Place>) onPlacesUpdated;

  const Step2ItineraryWidget({
    super.key, 
    required this.numDays, 
    required this.startDate, 
    required this.dayPlaces, 
    required this.popularPlaces, 
    required this.onPlacesUpdated
  });

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  void _openPlacePicker(BuildContext context, int dayIndex, List<Place> alreadySelected) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaceSelectionScreen(
          availablePlaces: popularPlaces,
          initiallySelected: alreadySelected,
        ),
      ),
    );

    if (result != null && result is List<Place>) {
      onPlacesUpdated(dayIndex, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: numDays,
      itemBuilder: (context, dayIndex) {
        DateTime currentDate = startDate.add(Duration(days: dayIndex));
        List<Place> placesForThisDay = dayPlaces[dayIndex] ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Ngày ${dayIndex + 1}", style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(_formatDate(currentDate), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF00D186), size: 28),
                    onPressed: () => _openPlacePicker(context, dayIndex, placesForThisDay),
                  )
                ],
              ),
              const SizedBox(height: 15),

              if (placesForThisDay.isEmpty)
                GestureDetector(
                  onTap: () => _openPlacePicker(context, dayIndex, placesForThisDay),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[800]!, style: BorderStyle.solid),
                    ),
                    child: const Center(child: Text("+ Bấm để thêm địa điểm", style: TextStyle(color: Colors.grey))),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: placesForThisDay.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final updatedList = List<Place>.from(placesForThisDay);
                    final item = updatedList.removeAt(oldIndex);
                    updatedList.insert(newIndex, item);
                    onPlacesUpdated(dayIndex, updatedList);
                  },
                  itemBuilder: (context, index) {
                    final place = placesForThisDay[index];
                    return Dismissible(
                      key: ValueKey('${place.id}_$index'), 
                      direction: DismissDirection.startToEnd, 
                      background: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        color: Colors.redAccent,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        final updatedList = List<Place>.from(placesForThisDay);
                        updatedList.removeAt(index);
                        onPlacesUpdated(dayIndex, updatedList);
                      },
                      child: _buildSelectedPlaceItem(place, index),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedPlaceItem(Place place, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), 
      padding: const EdgeInsets.all(10), // Căn chỉnh nhỏ gọn lại
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C), // Vibe tối xám trầm
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // --- 1. ẢNH ĐỊA ĐIỂM + SỐ THỨ TỰ ---
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomImage(
                  imageUrl: place.imageUrl,
                  width: 65,
                  height: 65,
                  fit: BoxFit.cover,
                ),
              ),
              // Huy hiệu số thứ tự (Vibe màu Info Blue cho dịu)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.9), 
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    "${index + 1}", 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // --- 2. THÔNG TIN CHI TIẾT ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tên địa điểm (Đúng biến p.name)
                Text(
                  place.name, 
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 6),
                
                // Điểm (avgRating) + 5 Chấm tròn + Lượt Review
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "${place.avgRating}", // Đúng biến avgRating
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    // Logic vẽ 5 chấm tròn y hệt code của ông giáo
                    Row(
                      children: List.generate(5, (dotIndex) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Icon(
                            Icons.circle,
                            size: 10,
                            color: (place.avgRating > dotIndex)
                                ? AppColors.primaryEmerald // Tone xanh dương
                                : Colors.grey.withOpacity(0.3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 4),
                    // Format phần ngàn y chang code cũ
                    Text(
                      "(${(place.totalReviews).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')})",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Địa chỉ + Mức giá (priceRange) gom gọn 1 dòng
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        place.address ?? 'Đang cập nhật', 
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Kẹp thêm biến priceRange của ông giáo vào đuôi (nếu có)
                    if (place.priceRange != null && place.priceRange!.trim().isNotEmpty) ...[
                      Text(" • ", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text(
                        place.priceRange!,
                        style: TextStyle(color: Colors.blue[300], fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ]
                  ],
                ),
              ],
            ),
          ),
          
          // --- 3. ICON KÉO THẢ ---
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.drag_handle_rounded, color: Colors.grey, size: 24),
          ), 
        ],
      ),
    );
  }
}