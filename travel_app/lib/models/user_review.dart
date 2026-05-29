class UserReview {
  final int reviewId;
  final int placeId;
  final String placeName;
  final String? placeAddress;
  final String? placeImageUrl;
  final int rating;
  final String? title;
  final String? comment;
  final DateTime? createdAt;

  UserReview({
    required this.reviewId,
    required this.placeId,
    required this.placeName,
    this.placeAddress,
    this.placeImageUrl,
    required this.rating,
    this.title,
    this.comment,
    this.createdAt,
  });

  factory UserReview.fromJson(Map<String, dynamic> json) {
    return UserReview(
      reviewId: json['review_id'],
      placeId: json['place_id'],
      placeName: json['place_name'] ?? 'Địa điểm',
      placeAddress: json['place_address'],
      placeImageUrl: json['place_image_url'],
      rating: json['rating'] ?? 0,
      title: json['title'],
      comment: json['comment'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}
