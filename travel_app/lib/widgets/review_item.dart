import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/review.dart';
import 'package:travel_app/services.dart/api_service.dart';
import 'package:travel_app/widgets/login_bottom_sheet.dart';
import 'package:travel_app/services.dart/favorite_places_service.dart';

class ReviewItem extends StatefulWidget {
  final Review review;
  final VoidCallback onReplyPosted;
  final int placeId;

  const ReviewItem({
    super.key,
    required this.review,
    required this.onReplyPosted,
    required this.placeId,
  });

  @override
  State<ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends State<ReviewItem> {
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
