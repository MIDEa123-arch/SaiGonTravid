import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_app/widgets/login_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritePlacesService {
  static final ValueNotifier<List<int>> notifier = ValueNotifier([]);
  static const String _key = 'favorite_places';

  // Tải danh sách ID các địa điểm yêu thích từ Local Storage
  static Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? placesJson = prefs.getString(_key);

    if (placesJson == null) {
      notifier.value = [];
      return;
    }

    try {
      final List<dynamic> decodedList = json.decode(placesJson);
      notifier.value = decodedList.cast<int>();
    } catch (e) {
      notifier.value = [];
    }
  }

  static bool isLoggedIn = false; // TODO: Cập nhật biến này khi làm chức năng đăng nhập

  // Toggle (Thêm/Xóa) một địa điểm khỏi danh sách yêu thích
  static Future<void> toggleFavorite(BuildContext context, int placeId) async {
    if (!isLoggedIn) {
      LoginBottomSheet.show(context);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final List<int> currentFavorites = List<int>.from(notifier.value);

    if (currentFavorites.contains(placeId)) {
      currentFavorites.remove(placeId);
    } else {
      currentFavorites.add(placeId);
    }

    final String encodedList = json.encode(currentFavorites);
    await prefs.setString(_key, encodedList);

    // Báo hiệu UI cập nhật
    notifier.value = currentFavorites;
  }

  // Kiểm tra xem một địa điểm có phải là yêu thích không
  static bool isFavorite(int placeId) {
    return notifier.value.contains(placeId);
  }
}
