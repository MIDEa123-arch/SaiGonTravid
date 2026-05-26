import 'package:flutter/material.dart';

class OpeningHoursStatus {
  final bool isOpen;
  final String primaryText;
  final String secondaryText;

  OpeningHoursStatus({
    required this.isOpen,
    required this.primaryText,
    required this.secondaryText,
  });
}

class OpeningHoursHelper {
  // Chuyển đổi weekday của Dart (1 = Thứ Hai, 7 = Chủ Nhật) sang chuỗi tiếng Việt
  static const List<String> _vnDays = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật'
  ];

  static String getDayName(int dartWeekday) {
    return _vnDays[dartWeekday - 1];
  }

  // Hàm xử lý chung để tính toán trạng thái đóng/mở cửa
  static OpeningHoursStatus getStatus(Map<String, dynamic>? hoursMap) {
    if (hoursMap == null || hoursMap.isEmpty) {
      return OpeningHoursStatus(
        isOpen: false,
        primaryText: 'Không rõ giờ mở cửa',
        secondaryText: '',
      );
    }

    final now = DateTime.now();
    final todayName = getDayName(now.weekday);
    final tomorrowName = getDayName(now.weekday == 7 ? 1 : now.weekday + 1);

    String? todayHours = findHoursForDay(hoursMap, todayName);

    if (todayHours == null || todayHours.toLowerCase() == 'đóng cửa') {
      // Đóng cửa cả ngày hôm nay
      String? tomorrowHours = findHoursForDay(hoursMap, tomorrowName);
      if (tomorrowHours != null && RegExp(r'[-–]').hasMatch(tomorrowHours)) {
        final parts = tomorrowHours.split(RegExp(r'[-–]'));
        return OpeningHoursStatus(
          isOpen: false,
          primaryText: 'Đóng cửa',
          secondaryText: 'Mở cửa ngày mai ${parts[0].trim()}',
        );
      }
      return OpeningHoursStatus(
        isOpen: false,
        primaryText: 'Đóng cửa hôm nay',
        secondaryText: '',
      );
    }

    // Nếu mở cả ngày 24/24 hoặc cả ngày
    if (todayHours.toLowerCase().contains('mở cả ngày') ||
        todayHours.toLowerCase().contains('mở cửa cả ngày') ||
        todayHours.toLowerCase().contains('24/24')) {
      return OpeningHoursStatus(
        isOpen: true,
        primaryText: 'Đang mở cửa',
        secondaryText: 'Mở cửa cả ngày',
      );
    }

    // Format điển hình: "09:00 - 21:30" hoặc "07:00–22:30"
    if (RegExp(r'[-–]').hasMatch(todayHours)) {
      final parts = todayHours.split(RegExp(r'[-–]'));
      if (parts.length >= 2) {
        final openTimeStr = parts[0].trim();
        final closeTimeStr = parts[1].trim();

        final openTime = _parseTime(openTimeStr);
        final closeTime = _parseTime(closeTimeStr);

        if (openTime != null && closeTime != null) {
          final nowMin = now.hour * 60 + now.minute;
          final openMin = openTime.hour * 60 + openTime.minute;
          var closeMin = closeTime.hour * 60 + closeTime.minute;

          // Xử lý mở qua đêm (ví dụ: 18:00 - 02:00)
          if (closeMin < openMin) {
            closeMin += 24 * 60;
          }

          var currentMin = nowMin;
          if (currentMin < openMin && closeMin > 24 * 60) {
              currentMin += 24 * 60;
          }

          if (currentMin >= openMin && currentMin <= closeMin) {
            // Đang mở
            return OpeningHoursStatus(
              isOpen: true,
              primaryText: 'Đang mở cửa',
              secondaryText: 'Đóng cửa lúc $closeTimeStr',
            );
          } else if (currentMin < openMin) {
            // Chưa mở (sắp mở hôm nay)
            return OpeningHoursStatus(
              isOpen: false,
              primaryText: 'Đóng cửa',
              secondaryText: 'Mở cửa lúc $openTimeStr',
            );
          } else {
            // Đã đóng cửa hôm nay, lấy giờ mở cửa ngày mai
            String? tomorrowHours = findHoursForDay(hoursMap, tomorrowName);
            if (tomorrowHours != null && RegExp(r'[-–]').hasMatch(tomorrowHours)) {
              final tmrParts = tomorrowHours.split(RegExp(r'[-–]'));
              return OpeningHoursStatus(
                isOpen: false,
                primaryText: 'Đóng cửa',
                secondaryText: 'Mở cửa ngày mai ${tmrParts[0].trim()}',
              );
            }
          }
        }
      }
    }

    return OpeningHoursStatus(
      isOpen: false,
      primaryText: 'Giờ mở cửa',
      secondaryText: todayHours,
    );
  }

  static String? findHoursForDay(Map<String, dynamic> hoursMap, String vnDay) {
    final lowerMap = <String, dynamic>{};
    for (var key in hoursMap.keys) {
      lowerMap[key.toLowerCase()] = hoursMap[key];
    }

    if (lowerMap.containsKey(vnDay.toLowerCase())) return lowerMap[vnDay.toLowerCase()];
    
    // Fallback english mappings
    final enMap = {
      'thứ hai': 'monday',
      'thứ ba': 'tuesday',
      'thứ tư': 'wednesday',
      'thứ năm': 'thursday',
      'thứ sáu': 'friday',
      'thứ bảy': 'saturday',
      'chủ nhật': 'sunday'
    };
    
    final enDay = enMap[vnDay.toLowerCase()];
    if (enDay != null && lowerMap.containsKey(enDay)) {
      return lowerMap[enDay];
    }
    
    // Tìm key tương đối
    for (var key in lowerMap.keys) {
      if (key.contains(vnDay.toLowerCase())) {
        return lowerMap[key];
      }
    }

    return null;
  }

  static TimeOfDay? _parseTime(String timeStr) {
    // timeStr ví dụ: "09:00", "21:30"
    final regex = RegExp(r'(\d{1,2}):(\d{2})');
    final match = regex.firstMatch(timeStr);
    if (match != null) {
      final h = int.tryParse(match.group(1)!);
      final m = int.tryParse(match.group(2)!);
      if (h != null && m != null) {
        return TimeOfDay(hour: h, minute: m);
      }
    }
    return null;
  }
}
