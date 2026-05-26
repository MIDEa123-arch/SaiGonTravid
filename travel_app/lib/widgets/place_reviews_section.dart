import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/place_detail.dart';
import 'package:travel_app/models/review.dart';
import 'package:travel_app/services.dart/api_service.dart';

class PlaceReviewsSection extends StatefulWidget {
  final PlaceDetail place;
  final VoidCallback onReplyPosted;

  const PlaceReviewsSection({super.key, required this.place, required this.onReplyPosted});

  @override
  State<PlaceReviewsSection> createState() => _PlaceReviewsSectionState();
}

class _PlaceReviewsSectionState extends State<PlaceReviewsSection> {
  final ApiService _api = ApiService();
  final TextEditingController _replyController = TextEditingController();

  void _showReplyDialog(Review review) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text('Trả lời đánh giá', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: _replyController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Nhập câu trả lời...',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
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
              child: const Text('Gửi', style: TextStyle(color: AppColors.primaryEmerald)),
            ),
          ],
        );
      },
    );
  }

  String _formatName(ReviewUser? user) {
    if (user == null) return 'Người dùng ẩn danh';
    String name = user.fullName;
    if (user.googleId != null) {
      name += ' (Google)';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final reviews = widget.place.reviews;
    if (reviews.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đánh giá (${widget.place.totalReviews})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white24, height: 32),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey.shade800,
                        backgroundImage: review.user?.avatarUrl != null
                            ? NetworkImage(review.user!.avatarUrl!)
                            : null,
                        child: review.user?.avatarUrl == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatName(review.user),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (review.stars != null)
                              Row(
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < review.stars! ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (review.content != null && review.content!.isNotEmpty)
                    Text(
                      review.content!,
                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                    ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showReplyDialog(review),
                    child: const Text('Trả lời', style: TextStyle(color: AppColors.primaryEmerald, fontWeight: FontWeight.bold)),
                  ),
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
                                  child: const Icon(Icons.reply, size: 14, color: Colors.white54),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatName(reply.user),
                                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        reply.content,
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  ]
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
