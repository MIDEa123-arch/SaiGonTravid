import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:travel_app/models/category.dart';
import 'package:travel_app/models/district.dart';
import 'package:travel_app/models/place.dart';
import 'package:travel_app/models/place_detail.dart';
import 'package:travel_app/models/user_review.dart';
import 'package:travel_app/core/constants.dart';

class ApiService {
  // 1. Nhà hàng lân cận (Có GPS) (Lấy các category group: 114, 116, 121)
  Future<List<Place>> getBestNearbyRestaurants(double lat, double lng) async {
    final url =
        '${ApiConstants.placesEndpoint}?category_group_ids=114,116,121&lat=$lat&lng=$lng&limit=10';
    return _fetchPlaces(url);
  }

  // Lấy địa điểm lân cận theo Category Tầng 1
  Future<List<Place>> getPlacesByCategoryAndLocation(
    int categoryId,
    double lat,
    double lng, {
    int limit = 10,
  }) async {
    final url =
        '${ApiConstants.placesEndpoint}?category_id=$categoryId&lat=$lat&lng=$lng&limit=$limit';
    return _fetchPlaces(url);
  }

  // Lấy địa điểm gợi ý động
  Future<List<Place>> getSuggestedPlaces(
    String filterQuery,
    double lat,
    double lng, {
    int limit = 20, // Xa xa xíu
  }) async {
    final url =
        '${ApiConstants.placesEndpoint}?$filterQuery&lat=$lat&lng=$lng&limit=$limit';
    return _fetchPlaces(url);
  }

  // 2. Trải nghiệm (Category 5 - Du lịch)
  Future<List<Place>> getExperiences() async {
    final url = '${ApiConstants.placesEndpoint}?category_id=5&limit=10';
    return _fetchPlaces(url);
  }

  // 3. Quán nước (CategoryGroup 113 - Cà phê & Trà)
  Future<List<Place>> getDrinkShop() async {
    final url =
        '${ApiConstants.placesEndpoint}?category_group_id=113&sort_by=total_reviews&order=desc&limit=10';
    return _fetchPlaces(url);
  }

  // Khách sạn / Nơi nghỉ ngơi cuối tuần (Category 2 - Lưu trú, type: Khách sạn)
  Future<List<Place>> getHotels() async {
    final type = Uri.encodeComponent('Khách sạn');
    final url =
        '${ApiConstants.placesEndpoint}?category_id=2&place_type=$type&sort_by=total_reviews&order=desc&limit=10';
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
  Future<bool> postReviewReply(
    int placeId,
    int reviewId,
    String content,
    int userId,
  ) async {
    try {
      final url =
          '${ApiConstants.placesEndpoint}/$placeId/reviews/$reviewId/reply';
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

  // 8. Like review
  Future<int?> likeReview(int placeId, int reviewId, int userId) async {
    try {
      final url =
          '${ApiConstants.placesEndpoint}/$placeId/reviews/$reviewId/like';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_id': userId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['likes'];
      }
      return null;
    } catch (e) {
      print("Lỗi like review: $e");
      return null;
    }
  }

  // 9. Lấy giờ đông khách
  Future<Map<String, dynamic>?> getPopularTimes(int placeId) async {
    try {
      final url = '${ApiConstants.placesEndpoint}/$placeId/popular_times';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      print("Lỗi lấy popular times: $e");
      return null;
    }
  }

  // 10. Tạo đánh giá địa điểm (Post Review)
  Future<String?> createReview({
    required int placeId,
    required int userId,
    required int rating,
    String? title,
    required String comment,
    String? imageUrl,
  }) async {
    try {
      final url = '${ApiConstants.placesEndpoint}/$placeId/reviews';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'user_id': userId,
          'rating': rating,
          'title': title,
          'comment': comment,
          'image_url': imageUrl,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // Thành công
      } else {
        final body = json.decode(utf8.decode(response.bodyBytes));
        return body['detail'] ?? 'Không thể gửi đánh giá';
      }
    } catch (e) {
      print("Lỗi createReview: $e");
      return 'Không thể kết nối đến server';
    }
  }

  // 11. Lấy danh sách đánh giá của một User
  Future<List<UserReview>> getUserReviews(int userId) async {
    try {
      final url = '${ApiConstants.baseUrl}/users/$userId/reviews';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => UserReview.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Lỗi getUserReviews: $e");
      return [];
    }
  }

  // 12. Xóa đánh giá địa điểm
  Future<bool> deleteReview(int placeId, int reviewId, int userId) async {
    try {
      final url = '${ApiConstants.placesEndpoint}/$placeId/reviews/$reviewId?user_id=$userId';
      final response = await http.delete(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi deleteReview: $e");
      return false;
    }
  }

  // 13. Cập nhật thông tin cá nhân (Họ và tên & Email)
  Future<String?> updateUserProfile(int userId, String fullName, String email) async {
    try {
      final url = '${ApiConstants.baseUrl}/users/$userId';
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'full_name': fullName,
          'email': email,
        }),
      );
      if (response.statusCode == 200) {
        return null; // Thành công
      } else {
        final body = json.decode(utf8.decode(response.bodyBytes));
        return body['detail'] ?? 'Cập nhật thất bại';
      }
    } catch (e) {
      print("Lỗi updateUserProfile: $e");
      return 'Không thể kết nối đến server';
    }
  }

  // 14. Upload ảnh đại diện (avatar)
  Future<String?> uploadAvatar(int userId, String filePath) async {
    try {
      final url = '${ApiConstants.baseUrl}/users/$userId/avatar';
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final body = json.decode(utf8.decode(response.bodyBytes));
        return body['avatar_url'];
      }
      return null;
    } catch (e) {
      print("Lỗi uploadAvatar: $e");
      return null;
    }
  }

  // 15. Upload ảnh Review
  Future<String?> uploadReviewImage(String filePath) async {
    try {
      final url = '${ApiConstants.placesEndpoint}/reviews/upload-image';
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final body = json.decode(utf8.decode(response.bodyBytes));
        return body['image_url'];
      }
      return null;
    } catch (e) {
      print("Lỗi uploadReviewImage: $e");
      return null;
    }
  }

  // 16. Lấy đường dẫn đầy đủ của avatar từ relative path
  String getAvatarFullUrl(String relativeUrl) {
    return 'http://${ApiConstants.ip}:8000$relativeUrl';
  }
}

