import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/place_detail.dart';
import 'package:travel_app/models/review.dart';
import 'package:travel_app/widgets/review_filter_bottom_sheet.dart';
import 'package:travel_app/widgets/review_item.dart';
import 'package:travel_app/widgets/login_bottom_sheet.dart';
import 'package:travel_app/services.dart/favorite_places_service.dart';
import 'package:travel_app/widgets/rating_summary.dart';
import 'package:travel_app/screens/place_detail/all_reviews_screen.dart';
import 'package:travel_app/screens/reviews/write_review_screen.dart';
import 'package:travel_app/services.dart/auth_service.dart';

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

  List<int> _selectedRatings = [];
  String _selectedDate = 'Tất cả đánh giá';
  List<int> _selectedMonths = [];

  void _navigateToAllReviews({
    List<int> initialRatings = const [],
    String initialDate = 'Tất cả đánh giá',
    List<int> initialMonths = const [],
    String initialSearchQuery = '',
    bool autoFocusSearch = false,
    required int r5,
    required int r4,
    required int r3,
    required int r2,
    required int r1,
    required int totalCount,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllReviewsScreen(
          place: widget.place,
          onReplyPosted: widget.onReplyPosted,
          initialSelectedRatings: initialRatings,
          initialSelectedDate: initialDate,
          initialSelectedMonths: initialMonths,
          initialSearchQuery: initialSearchQuery,
          autoFocusSearch: autoFocusSearch,
          r5: r5,
          r4: r4,
          r3: r3,
          r2: r2,
          r1: r1,
          totalCount: totalCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviews = widget.place.reviews;
    if (reviews.isEmpty) return const SizedBox.shrink();

    final hasReviewed = FavoritePlacesService.isLoggedIn &&
        reviews.any((r) => r.user?.userId == AuthService.currentUser?.userId);

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

    List<Review> filteredReviews = reviews;

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

          RatingSummary(
            place: widget.place,
            r5: r5,
            r4: r4,
            r3: r3,
            r2: r2,
            r1: r1,
            totalCount: totalCount,
          ),
          const SizedBox(height: 32),

          // Nút Viết đánh giá
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: hasReviewed ? null : () {
                if (!FavoritePlacesService.isLoggedIn) {
                  LoginBottomSheet.show(context);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WriteReviewScreen(place: widget.place),
                    ),
                  ).then((value) {
                    if (value == true) {
                      widget.onReplyPosted();
                    }
                  });
                }
              },
              icon: Icon(
                Icons.edit_outlined,
                color: hasReviewed ? Colors.white30 : Colors.black87,
                size: 20,
              ),
              label: Text(
                hasReviewed ? 'Bạn đã đánh giá địa điểm này' : 'Viết đánh giá',
                style: TextStyle(
                  color: hasReviewed ? Colors.white30 : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasReviewed ? Colors.white10 : const Color(0xFFE0E0E0),
                disabledBackgroundColor: Colors.white10,
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
                    // Navigate to AllReviewsScreen with applied filters
                    _navigateToAllReviews(
                      initialRatings: result['ratings'],
                      initialDate: result['date'],
                      initialMonths: result['months'],
                      r5: r5,
                      r4: r4,
                      r3: r3,
                      r2: r2,
                      r1: r1,
                      totalCount: totalCount,
                    );
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
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _navigateToAllReviews(
                          initialSearchQuery: val,
                          r5: r5,
                          r4: r4,
                          r3: r3,
                          r2: r2,
                          r1: r1,
                          totalCount: totalCount,
                        );
                      }
                    },
                    decoration: const InputDecoration(
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
              return ReviewItem(
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
                  _navigateToAllReviews(
                    r5: r5,
                    r4: r4,
                    r3: r3,
                    r2: r2,
                    r1: r1,
                    totalCount: totalCount,
                  );
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
