import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_app/widgets/login_bottom_sheet.dart';
import 'package:travel_app/services.dart/auth_service.dart';

class FavoritePlacesService {
  static final ValueNotifier<List<int>> notifier = ValueNotifier([]);
  
  static String? get _key {
    final user = AuthService.currentUser;
    if (user != null) {
      return 'favorite_places_user_${user.userId}';
    }
    return null;
  }

  static bool _listenerAdded = false;

  // Tải danh sách ID các địa điểm yêu thích từ Local Storage
  static Future<void> loadFavorites() async {
    if (!_listenerAdded) {
      AuthService.currentUserNotifier.addListener(() {
        loadFavorites();
      });
      _listenerAdded = true;
    }

    if (!AuthService.isLoggedIn) {
      notifier.value = [];
      return;
    }

    final keyName = _key;
    if (keyName == null) {
      notifier.value = [];
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? placesJson = prefs.getString(keyName);

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

  /// Kiểm tra đăng nhập thông qua AuthService (real-time)
  static bool get isLoggedIn => AuthService.isLoggedIn;

  // Toggle (Thêm/Xóa) một địa điểm khỏi danh sách yêu thích
  static Future<void> toggleFavorite(BuildContext context, int placeId) async {
    if (!isLoggedIn) {
      LoginBottomSheet.show(context);
      return;
    }

    final keyName = _key;
    if (keyName == null) return;

    final prefs = await SharedPreferences.getInstance();
    final List<int> currentFavorites = List<int>.from(notifier.value);

    if (currentFavorites.contains(placeId)) {
      currentFavorites.remove(placeId);
    } else {
      currentFavorites.add(placeId);
    }

    final String encodedList = json.encode(currentFavorites);
    await prefs.setString(keyName, encodedList);

    // Báo hiệu UI cập nhật
    notifier.value = currentFavorites;
  }

  // Kiểm tra xem một địa điểm có phải là yêu thích không
  static bool isFavorite(int placeId) {
    if (!isLoggedIn) return false;
    return notifier.value.contains(placeId);
  }
}
