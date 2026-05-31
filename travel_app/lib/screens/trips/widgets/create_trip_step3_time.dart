import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/place.dart';
import 'package:travel_app/widgets/custom_image.dart';

class Step3TimeSelectionWidget extends StatelessWidget {
  final int numDays;
  final DateTime startDate;
  final Map<int, List<Place>> dayPlaces;
  final Map<String, String> placeTimes; // key: "${dayIndex}_${place.id}"
  final Function(int dayIndex, int placeId, String time) onTimeSelected;

  const Step3TimeSelectionWidget({
    super.key,
    required this.numDays,
    required this.startDate,
    required this.dayPlaces,
    required this.placeTimes,
    required this.onTimeSelected,
  });

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Future<void> _pickTime(BuildContext context, int dayIndex, int placeId, String? currentTime) async {
    TimeOfDay initialTime = TimeOfDay.now();
    if (currentTime != null && currentTime.isNotEmpty) {
      try {
        final parts = currentTime.split(':');
        initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {}
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryEmerald,
              onPrimary: Colors.black,
              surface: Color(0xFF1C1C1C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      onTimeSelected(dayIndex, placeId, formattedTime);
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ngày ${dayIndex + 1}", 
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  Text(
                    _formatDate(currentDate), 
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)
                  ),
                ],
              ),
              const SizedBox(height: 15),

              if (placesForThisDay.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!, style: BorderStyle.solid),
                  ),
                  child: const Center(
                    child: Text("Chưa có địa điểm nào", style: TextStyle(color: Colors.grey))
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: placesForThisDay.length,
                  itemBuilder: (context, index) {
                    final place = placesForThisDay[index];
                    final timeKey = "${dayIndex}_${place.id}";
                    final timeValue = placeTimes[timeKey];
                    return _buildPlaceItem(context, place, index, dayIndex, timeValue);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceItem(BuildContext context, Place place, int index, int dayIndex, String? timeValue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), 
      padding: const EdgeInsets.all(10), 
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: timeValue == null ? Colors.red.withOpacity(0.5) : Colors.transparent,
          width: 1,
        )
      ),
      child: Row(
        children: [
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name, 
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _pickTime(context, dayIndex, place.id, timeValue),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, color: Colors.white70, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          timeValue ?? "Chọn giờ bắt đầu",
                          style: TextStyle(
                            color: timeValue == null ? Colors.red[300] : Colors.white,
                            fontSize: 13,
                            fontWeight: timeValue == null ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
