class ReviewUser {
  final int userId;
  final String fullName;
  final String? avatarUrl;
  final String? googleId;

  ReviewUser({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.googleId,
  });

  factory ReviewUser.fromJson(Map<String, dynamic> json) {
    return ReviewUser(
      userId: json['user_id'],
      fullName: json['full_name'] ?? 'Người dùng ẩn danh',
      avatarUrl: json['avatar_url'],
      googleId: json['google_id'],
    );
  }
}

class ReviewImage {
  final int revImageId;
  final String imageUrl;

  ReviewImage({required this.revImageId, required this.imageUrl});

  factory ReviewImage.fromJson(Map<String, dynamic> json) {
    return ReviewImage(
      revImageId: json['rev_image_id'],
      imageUrl: json['image_url'],
    );
  }
}

class ReviewReply {
  final int replyId;
  final String content;
  final DateTime? createdAt;
  final ReviewUser? user;

  ReviewReply({
    required this.replyId,
    required this.content,
    this.createdAt,
    this.user,
  });

  factory ReviewReply.fromJson(Map<String, dynamic> json) {
    return ReviewReply(
      replyId: json['reply_id'],
      content: json['content'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      user: json['user'] != null ? ReviewUser.fromJson(json['user']) : null,
    );
  }
}

class Review {
  final int reviewId;
  final String? title;
  final String? content;
  final int? stars;
  final double? sentimentScore;
  final DateTime? createdAt;
  final ReviewUser? user;
  final List<ReviewImage> images;
  final List<ReviewReply> replies;
  int likes;

  Review({
    required this.reviewId,
    this.title,
    this.content,
    this.stars,
    this.sentimentScore,
    this.createdAt,
    this.user,
    this.images = const [],
    this.replies = const [],
    this.likes = 0,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['review_id'],
      title: json['title'],
      content: json['content'],
      stars: json['stars'],
      sentimentScore: json['sentiment_score'] != null
          ? double.tryParse(json['sentiment_score'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      user: json['user'] != null ? ReviewUser.fromJson(json['user']) : null,
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => ReviewImage.fromJson(e))
          .toList(),
      replies: (json['replies'] as List<dynamic>? ?? [])
          .map((e) => ReviewReply.fromJson(e))
          .toList(),
      likes: json['likes'] ?? 0,
    );
  }
}
