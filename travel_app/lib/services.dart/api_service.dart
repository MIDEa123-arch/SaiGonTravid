import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:travel_app/models/category.dart';
import 'package:travel_app/models/district.dart';
import 'package:travel_app/models/place.dart';
import 'package:travel_app/models/place_detail.dart';
import 'package:travel_app/core/constants.dart';

class ApiService {
  // 1. Nhà hàng lân cận (Có GPS) (Category 63 - Ẩm thực)
  Future<List<Place>> getBestNearbyRestaurants(double lat, double lng) async {
    final url =
        '${ApiConstants.placesEndpoint}?category_group_id=63&lat=$lat&lng=$lng&limit=10';
    return _fetchPlaces(url);
  }

  // 2. Trải nghiệm (Category 59 - Văn hóa & Lịch sử)
  Future<List<Place>> getExperiences() async {
    final url = '${ApiConstants.placesEndpoint}?category_group_id=59&limit=10';
    return _fetchPlaces(url);
  }

  // 3. Quán nước (Category 62 - Đồ uống & Ăn vặt)
  Future<List<Place>> getDrinkShop() async {
    final url =
        '${ApiConstants.placesEndpoint}?category_group_id=62&sort_by=total_reviews&order=desc&limit=10';
    return _fetchPlaces(url);
  }

  // Khách sạn / Nơi nghỉ ngơi cuối tuần (Category 65 - Lưu trú)
  Future<List<Place>> getHotels() async {
    final url =
        '${ApiConstants.placesEndpoint}?category_group_id=65&sort_by=total_reviews&order=desc&limit=10';
    return _fetchPlaces(url);
  }

  // 4. Địa điểm gần đây (Recent)
  Future<List<Place>> getRecentPlaces() async {
    final url = '${ApiConstants.placesEndpoint}?limit=8';
    return _fetchPlaces(url);
  }

  // 5. Danh sách Quận/Huyện
  Future<List<District>> getDistricts() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.placesEndpoint}/districts/all'),
      );
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => District.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Hàm dùng chung để lấy List<Place> cho đỡ lặp code
  Future<List<Place>> _fetchPlaces(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Place.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Lỗi API: $e");
      return [];
    }
  }

  Future<List<Place>> getAllNearbyPlaces(double lat, double lng) async {
    // Gọi API của Backend, bỏ category_group_id để lấy hết, limit 50 cho bản đồ đông đúc
    final url = '${ApiConstants.placesEndpoint}?lat=$lat&lng=$lng&limit=50';
    return _fetchPlaces(url);
  }

  Future<List<CategoryGroup>> getCategories() async {
    try {
      final url = '${ApiConstants.placesEndpoint}/categories/all';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // Giải mã UTF-8 để chữ "Nhà hàng", "Cà phê" không bị lỗi font
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => CategoryGroup.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Lỗi lấy Categories: $e");
      return [];
    }
  }

  // 6. Chi tiết 1 địa điểm (Full: ảnh + reviews)
  Future<PlaceDetail?> getPlaceDetail(int placeId) async {
    try {
      final url = '${ApiConstants.placesEndpoint}/$placeId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return PlaceDetail.fromJson(data);
      }
      return null;
    } catch (e) {
      print("Lỗi lấy chi tiết địa điểm: $e");
      return null;
    }
  }

  // 7. Post Review Reply
  Future<bool> postReviewReply(int placeId, int reviewId, String content, int userId) async {
    try {
      final url = '${ApiConstants.placesEndpoint}/$placeId/reviews/$reviewId/reply';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'content': content, 'user_id': userId}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Lỗi post reply: $e");
      return false;
    }
  }
}

