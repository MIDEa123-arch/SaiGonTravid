import 'package:travel_app/models/review.dart';

class PlaceImage {
  final int imageId;
  final String imageUrl;

  PlaceImage({required this.imageId, required this.imageUrl});

  factory PlaceImage.fromJson(Map<String, dynamic> json) {
    return PlaceImage(
      imageId: json['image_id'],
      imageUrl: json['image_url'],
    );
  }
}

class PlaceCategory {
  final int categoryGroupId;
  final String name;

  PlaceCategory({required this.categoryGroupId, required this.name});

  factory PlaceCategory.fromJson(Map<String, dynamic> json) {
    return PlaceCategory(
      categoryGroupId: json['category_group_id'],
      name: json['name'],
    );
  }
}

class PlaceDistrict {
  final int districtId;
  final String name;

  PlaceDistrict({required this.districtId, required this.name});

  factory PlaceDistrict.fromJson(Map<String, dynamic> json) {
    return PlaceDistrict(
      districtId: json['district_id'],
      name: json['name'],
    );
  }
}

class PlaceDetail {
  final int placeId;
  final String name;
  final String? placeType;
  final String? address;
  final String? priceRange;
  final double avgRating;
  final int totalReviews;
  final double? lat;
  final double? lng;
  final String? description;
  final Map<String, dynamic>? openingHours;
  final dynamic utilities;
  final String? phone;
  final String? website;
  final PlaceCategory? categoryGroup;
  final PlaceDistrict? district;
  final List<PlaceImage> images;
  final List<Review> reviews;
  final String? googleMapsUrl;
  final String? reviewPopularityLevel;
  final Map<String, dynamic>? popularTimes;

  PlaceDetail({
    required this.placeId,
    required this.name,
    this.placeType,
    this.address,
    this.priceRange,
    this.avgRating = 0.0,
    this.totalReviews = 0,
    this.lat,
    this.lng,
    this.description,
    this.openingHours,
    this.utilities,
    this.phone,
    this.website,
    this.categoryGroup,
    this.district,
    this.images = const [],
    this.reviews = const [],
    this.googleMapsUrl,
    this.reviewPopularityLevel,
    this.popularTimes,
  });

  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    final coords = json['lat_lng'];
    return PlaceDetail(
      placeId: json['place_id'],
      name: json['name'] ?? 'Chưa có tên',
      placeType: json['place_type'],
      address: json['address'],
      priceRange: json['price_range'],
      avgRating: json['avg_rating'] != null
          ? double.tryParse(json['avg_rating'].toString()) ?? 0.0
          : 0.0,
      totalReviews: json['total_reviews'] ?? 0,
      lat: (coords != null && coords['lat'] != null)
          ? double.tryParse(coords['lat'].toString())
          : null,
      lng: (coords != null && coords['lng'] != null)
          ? double.tryParse(coords['lng'].toString())
          : null,
      description: json['description'],
      openingHours: json['opening_hours'] is Map
          ? Map<String, dynamic>.from(json['opening_hours'])
          : null,
      phone: json['phone'],
      website: json['website'],
      utilities: json['utilities'],
      categoryGroup: json['category_group'] != null
          ? PlaceCategory.fromJson(json['category_group'])
          : null,
      district: json['district'] != null
          ? PlaceDistrict.fromJson(json['district'])
          : null,
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => PlaceImage.fromJson(e))
          .toList(),
      reviews: (json['reviews'] as List<dynamic>? ?? [])
          .map((e) => Review.fromJson(e))
          .toList(),
      googleMapsUrl: json['google_maps_url'],
      reviewPopularityLevel: json['review_popularity_level'],
      popularTimes: json['popular_times'] is Map
          ? Map<String, dynamic>.from(json['popular_times'])
          : null,
    );
  }
}
