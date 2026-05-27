import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/place_detail.dart';
import 'package:travel_app/models/review.dart';
import 'package:travel_app/services.dart/api_service.dart';
import 'package:travel_app/widgets/tripadvisor_rating_bar.dart';
import 'package:travel_app/widgets/login_bottom_sheet.dart';
import 'package:travel_app/services.dart/favorite_places_service.dart';
import 'package:travel_app/widgets/review_filter_bottom_sheet.dart';

class PlaceReviewsSection extends StatefulWidget {
  final PlaceDetail place;
  final VoidCallback onReplyPosted;

  const PlaceReviewsSection({
    super.key,
    required this.place,
    required this.onReplyPosted,
  });

  @override
  State<PlaceReviewsSection> createState() => _PlaceReviewsSectionState();
}

class _PlaceReviewsSectionState extends State<PlaceReviewsSection> {
  final ApiService _api = ApiService();
  final TextEditingController _replyController = TextEditingController();

  List<int> _selectedRatings = [];
  String _selectedDate = 'Tất cả đánh giá';
  List<int> _selectedMonths = [];

  void _showReplyDialog(Review review) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text(
            'Trả lời đánh giá',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: _replyController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Nhập câu trả lời...',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                if (_replyController.text.trim().isNotEmpty) {
                  final success = await _api.postReviewReply(
                    widget.place.placeId,
                    review.reviewId,
                    _replyController.text.trim(),
                    1, // Mặc định là user 1 tạm thời
                  );
                  if (success) {
                    _replyController.clear();
                    Navigator.pop(context);
                    widget.onReplyPosted();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lỗi khi gửi câu trả lời')),
                    );
                  }
                }
              },
              child: const Text(
                'Gửi',
                style: TextStyle(color: AppColors.primaryEmerald),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatName(ReviewUser? user) {
    if (user == null) return 'Người dùng ẩn danh';
    return user.fullName;
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Xuất sắc';
    if (rating >= 4.0) return 'Tốt';
    if (rating >= 3.0) return 'Trung bình';
    if (rating >= 2.0) return 'Kém';
    return 'Rất tệ';
  }

  Widget _buildRatingBar(String label, int count, int total) {
    final ratio = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 75,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              if (ratio > 0)
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.accentMint,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 20,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviews = widget.place.reviews;
    if (reviews.isEmpty) return const SizedBox.shrink();

    int r5 = 0, r4 = 0, r3 = 0, r2 = 0, r1 = 0;
    for (var r in reviews) {
      if (r.stars == 5)
        r5++;
      else if (r.stars == 4)
        r4++;
      else if (r.stars == 3)
        r3++;
      else if (r.stars == 2)
        r2++;
      else if (r.stars == 1)
        r1++;
    }

    int totalCount = r5 + r4 + r3 + r2 + r1;
    if (totalCount == 0 && widget.place.totalReviews > 0) {
      r5 = widget.place.totalReviews;
      totalCount = r5;
    }

    // Lọc reviews dựa trên các điều kiện
    List<Review> filteredReviews = reviews;

    if (_selectedRatings.isNotEmpty) {
      filteredReviews = filteredReviews.where((r) => r.stars != null && _selectedRatings.contains(r.stars)).toList();
    }

    if (_selectedDate != 'Tất cả đánh giá') {
      final now = DateTime.now();
      if (_selectedDate == '3 tháng trước') {
        filteredReviews = filteredReviews.where((r) => r.createdAt != null && now.difference(r.createdAt!).inDays <= 90).toList();
      } else if (_selectedDate == '6 tháng trước') {
        filteredReviews = filteredReviews.where((r) => r.createdAt != null && now.difference(r.createdAt!).inDays <= 180).toList();
      } else if (_selectedDate == '12 tháng qua') {
        filteredReviews = filteredReviews.where((r) => r.createdAt != null && now.difference(r.createdAt!).inDays <= 365).toList();
      }
    }

    if (_selectedMonths.isNotEmpty) {
      filteredReviews = filteredReviews.where((r) => r.createdAt != null && _selectedMonths.contains(r.createdAt!.month)).toList();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin cho khách du lịch',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.place.avgRating
                        .toStringAsFixed(1)
                        .replaceAll('.', ','),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 54,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _getRatingText(widget.place.avgRating),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TripAdvisorRatingBar(
                        rating: widget.place.avgRating,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.place.totalReviews}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 32),

              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar('Xuất sắc', r5, totalCount),
                    const SizedBox(height: 6),
                    _buildRatingBar('Tốt', r4, totalCount),
                    const SizedBox(height: 6),
                    _buildRatingBar('Trung bình', r3, totalCount),
                    const SizedBox(height: 6),
                    _buildRatingBar('Kém', r2, totalCount),
                    const SizedBox(height: 6),
                    _buildRatingBar('Rất tệ', r1, totalCount),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Nút Viết đánh giá
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Xử lý sự kiện Viết đánh giá
              },
              icon: const Icon(
                Icons.edit_outlined,
                color: Colors.black87,
                size: 20,
              ),
              label: const Text(
                'Viết đánh giá',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE0E0E0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // "Tất cả đánh giá" header
          const Text(
            'Tất cả đánh giá',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Disclaimer text
          const SizedBox(
            width: double.infinity,
            child: Text(
              'Các đánh giá là ý kiến chủ quan của thành viên SaiGontravid, không phải của SaiGontravid LLC.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
          const SizedBox(height: 16),

          // Bộ lọc button
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await ReviewFilterBottomSheet.show(
                    context,
                    r5: r5,
                    r4: r4,
                    r3: r3,
                    r2: r2,
                    r1: r1,
                    initialSelectedRatings: _selectedRatings,
                    initialSelectedDate: _selectedDate,
                    initialSelectedMonths: _selectedMonths,
                  );
                  if (result != null) {
                    setState(() {
                      _selectedRatings = result['ratings'];
                      _selectedDate = result['date'];
                      _selectedMonths = result['months'];
                    });
                  }
                },
                icon: const Icon(Icons.tune, color: Colors.white, size: 18),
                label: const Text(
                  'Bộ lọc',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search bar
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm đánh giá',
                      hintStyle: TextStyle(color: Colors.white70, fontSize: 15),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredReviews.length > 3 ? 3 : filteredReviews.length,
            separatorBuilder: (context, index) =>
                const Divider(color: Colors.white24, height: 32),
            itemBuilder: (context, index) {
              final review = filteredReviews[index];
              return _ReviewItem(
                review: review,
                onReplyPosted: widget.onReplyPosted,
                placeId: widget.place.placeId,
              );
            },
          ),
          if (filteredReviews.length > 3) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2A12),
                  side: const BorderSide(color: Colors.white, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () {
                  // TODO: Navigate to all reviews screen
                },
                child: Text(
                  'Xem tất cả ${filteredReviews.length} đánh giá',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewItem extends StatefulWidget {
  final Review review;
  final VoidCallback onReplyPosted;
  final int placeId;

  const _ReviewItem({
    required this.review,
    required this.onReplyPosted,
    required this.placeId,
  });

  @override
  State<_ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends State<_ReviewItem> {
  bool _isExpanded = false;
  late int _likes;
  final ApiService _api = ApiService();
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _likes = widget.review.likes;
  }

  void _showReplyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text(
            'Trả lời đánh giá',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: _replyController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Nhập câu trả lời...',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                if (_replyController.text.trim().isNotEmpty) {
                  final success = await _api.postReviewReply(
                    widget.placeId,
                    widget.review.reviewId,
                    _replyController.text.trim(),
                    1, // Mặc định là user 1 tạm thời
                  );
                  if (success) {
                    _replyController.clear();
                    Navigator.pop(context);
                    widget.onReplyPosted();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lỗi khi gửi câu trả lời')),
                    );
                  }
                }
              },
              child: const Text(
                'Gửi',
                style: TextStyle(color: AppColors.primaryEmerald),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleLike() async {
    if (!FavoritePlacesService.isLoggedIn) {
      LoginBottomSheet.show(context);
      return;
    }

    setState(() {
      _likes++;
    });
    final newLikes = await _api.likeReview(
      widget.placeId,
      widget.review.reviewId,
      1,
    );
    if (newLikes == null) {
      setState(() {
        _likes--;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lỗi khi thích đánh giá')));
      }
    } else {
      setState(() {
        _likes = newLikes;
      });
    }
  }

  String _formatName(ReviewUser? user) {
    if (user == null) return 'Người dùng ẩn danh';
    return user.fullName;
  }

  String _formatDate(DateTime date) {
    return '${date.day} thg ${date.month}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final isContentLong =
        review.content != null && review.content!.length > 150;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Avatar, Name
        Row(
          children: [
            ClipOval(
              child: review.user?.avatarUrl != null
                  ? Image.network(
                      review.user!.avatarUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _formatName(review.user),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Stars & Date
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (review.stars != null)
              Row(
                children: List.generate(
                  5,
                  (i) => Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < review.stars!
                          ? Colors.greenAccent[400]
                          : Colors.transparent,
                      border: Border.all(
                        color: i < review.stars!
                            ? Colors.greenAccent[400]!
                            : Colors.white30,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            if (review.createdAt != null)
              Text(
                _formatDate(review.createdAt!),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Title
        if (review.title != null && review.title!.isNotEmpty) ...[
          Text(
            review.title!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Content
        if (review.content != null && review.content!.isNotEmpty) ...[
          Text(
            review.content!,
            maxLines: _isExpanded ? null : 4,
            overflow: _isExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          if (isContentLong && !_isExpanded) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = true;
                });
              },
              child: const Row(
                children: [
                  Text(
                    'Đọc thêm',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ],

        // Images
        if (review.images.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: review.images.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    review.images[index].imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey.shade800,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Like and Reply actions
        Row(
          children: [
            GestureDetector(
              onTap: _handleLike,
              child: Row(
                children: [
                  const Icon(
                    Icons.thumb_up_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Hữu ích $_likes',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: _showReplyDialog,
              child: const Text(
                'Phản hồi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        // Replies
        if (review.replies.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Column(
              children: review.replies.map((reply) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey.shade800,
                        child: const Icon(
                          Icons.reply,
                          size: 14,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatName(reply.user),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reply.content,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
