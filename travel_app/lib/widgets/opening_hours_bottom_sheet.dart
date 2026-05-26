import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/utils/opening_hours_helper.dart';

class OpeningHoursBottomSheet extends StatelessWidget {
  final Map<String, dynamic> openingHours;

  const OpeningHoursBottomSheet({super.key, required this.openingHours});

  static void show(BuildContext context, Map<String, dynamic> hours) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OpeningHoursBottomSheet(openingHours: hours),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Thứ tự ngày hiển thị
    final days = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];

    final currentDay = OpeningHoursHelper.getDayName(DateTime.now().weekday);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Nút Đóng
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 24),
            // Tiêu đề
            const Text(
              'Giờ mở cửa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            // Danh sách giờ
            ...days.map((day) {
              final isToday = day == currentDay;
              // Tìm giờ trong DB
              String hoursStr = OpeningHoursHelper.findHoursForDay(openingHours, day) ?? 'Không rõ';

              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hoursStr,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
