import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_app/models/place.dart';

class RecentPlacesService {
  static final ValueNotifier<int> notifier = ValueNotifier(0);
  static const String _key = 'recent_places';
  static const int _maxPlaces = 10;

  // Lấy danh sách đã xem từ Local Storage
  static Future<List<Place>> getRecentPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    final String? placesJson = prefs.getString(_key);
    
    if (placesJson == null) {
      return [];
    }

    try {
      final List<dynamic> decodedList = json.decode(placesJson);
      return decodedList.map((item) => Place.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  // Thêm 1 địa điểm vào danh sách đã xem
  static Future<void> addRecentPlace(Place place) async {
    final prefs = await SharedPreferences.getInstance();
    List<Place> currentPlaces = await getRecentPlaces();

    // Xóa nếu đã tồn tại để đưa lên đầu
    currentPlaces.removeWhere((p) => p.id == place.id);
    
    // Thêm vào đầu danh sách
    currentPlaces.insert(0, place);

    // Giữ tối đa N địa điểm
    if (currentPlaces.length > _maxPlaces) {
      currentPlaces = currentPlaces.sublist(0, _maxPlaces);
    }

    // Lưu lại
    final String encodedList = json.encode(
      currentPlaces.map((p) => p.toJson()).toList(),
    );
    await prefs.setString(_key, encodedList);
    
    // Báo hiệu cho UI cập nhật
    notifier.value++;
  }
}
