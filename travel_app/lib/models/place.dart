import 'package:geolocator/geolocator.dart';

class Place {
  final int id;
  final String name;
  final String? address;
  final String? placeType;
  final double avgRating;
  final String? imageUrl;
  final int totalReviews;
  final String? priceRange;
  final int? categoryId;

  // Tọa độ
  final double? lat;
  final double? lng;
  
  // ĐÃ THÊM: Khoảng cách do Backend tính sẵn trả về
  final double? backendDistance; 

  Place({
    required this.id,
    required this.name,
    this.address,
    this.placeType,
    this.avgRating = 0.0,
    this.imageUrl,
    this.totalReviews = 0,
    this.priceRange,
    this.lat,
    this.lng,
    this.backendDistance,
    this.categoryId,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    // 1. Phải bóc cái lat_lng ra trước
    final coords = json['lat_lng']; 

    return Place(
      id: json['place_id'],
      name: json['name'] ?? "Chưa có tên",
      address: json['address'],
      placeType: json['place_type'],
      categoryId: json['category_group_id'],
      avgRating: (json['avg_rating'] != null)
          ? double.tryParse(json['avg_rating'].toString()) ?? 0.0
          : 0.0,
      imageUrl: json['image_url'],
      totalReviews: json['total_reviews'] as int? ?? 0,
      priceRange: json['price_range'],

      // 2. Lấy lat, lng từ cục coords
      lat: (coords != null && coords['lat'] != null)
          ? double.tryParse(coords['lat'].toString())
          : null,
      lng: (coords != null && coords['lng'] != null)
          ? double.tryParse(coords['lng'].toString())
          : null,
          
      // 3. Lấy distance từ Backend gửi lên
      backendDistance: (json['distance'] != null)
          ? double.tryParse(json['distance'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'place_id': id,
      'name': name,
      'address': address,
      'place_type': placeType,
      'category_group_id': categoryId,
      'avg_rating': avgRating,
      'image_url': imageUrl,
      'total_reviews': totalReviews,
      'price_range': priceRange,
      'lat_lng': {'lat': lat, 'lng': lng},
      'distance': backendDistance,
    };
  }

  // Hàm hiển thị khoảng cách thông minh
  String getDistanceDisplay(double? userLat, double? userLng) {
    double distanceInMeters = 0.0;

    // Ưu tiên 1: Lấy khoảng cách Backend đã tính cực chuẩn bằng PostGIS
    if (backendDistance != null) {
      distanceInMeters = backendDistance!;
    } 
    // Ưu tiên 2: Backend không có, tự tính bằng Geolocator 
    else if (userLat != null && userLng != null && lat != null && lng != null) {
      distanceInMeters = Geolocator.distanceBetween(userLat, userLng, lat!, lng!);
    } 
    // Không có data thì để trống
    else {
      return "";
    }
    
    if (distanceInMeters < 1000) {
      return "${distanceInMeters.toStringAsFixed(0)}m";
    } else {
      return "${(distanceInMeters / 1000).toStringAsFixed(1)}km";
    }
  }
}