import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_app/widgets/login_bottom_sheet.dart';
import 'package:travel_app/services.dart/auth_service.dart';
import 'package:travel_app/services.dart/api_service.dart';
import 'package:travel_app/widgets/top_toast.dart';

class FavoritePlacesService {
  static final ValueNotifier<List<int>> notifier = ValueNotifier([]);
  
  static final ApiService _apiService = ApiService();

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

    final user = AuthService.currentUser;
    if (user == null) {
      notifier.value = [];
      return;
    }

    try {
      final savedPlaces = await _apiService.getSavedPlaces(user.userId);
      notifier.value = savedPlaces.map((p) => p.id).toList();
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

    final user = AuthService.currentUser;
    if (user == null) return;

    final List<int> currentFavorites = List<int>.from(notifier.value);
    final isCurrentlyFavorite = currentFavorites.contains(placeId);

    // Optimistic UI update
    if (isCurrentlyFavorite) {
      currentFavorites.remove(placeId);
      notifier.value = currentFavorites;
      TopToast.show(context, "Đã bỏ lưu địa điểm", isError: false);
      
      final success = await _apiService.removeSavedPlace(user.userId, placeId);
      if (!success) {
        // revert on failure
        currentFavorites.add(placeId);
        notifier.value = currentFavorites;
        TopToast.show(context, "Lỗi bỏ lưu địa điểm", isError: true);
      }
    } else {
      currentFavorites.add(placeId);
      notifier.value = currentFavorites;
      TopToast.show(context, "Đã lưu địa điểm", isError: false);
      
      final success = await _apiService.addSavedPlace(user.userId, placeId);
      if (!success) {
        // revert on failure
        currentFavorites.remove(placeId);
        notifier.value = currentFavorites;
        TopToast.show(context, "Lỗi lưu địa điểm", isError: true);
      }
    }
  }

  // Kiểm tra xem một địa điểm có phải là yêu thích không
  static bool isFavorite(int placeId) {
    if (!isLoggedIn) return false;
    return notifier.value.contains(placeId);
  }
}
