import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/place_detail.dart';
import 'package:travel_app/models/review.dart';
import 'package:travel_app/widgets/review_item.dart';
import 'package:travel_app/widgets/rating_summary.dart';
import 'package:travel_app/widgets/review_filter_bottom_sheet.dart';
import 'package:travel_app/widgets/login_bottom_sheet.dart';
import 'package:travel_app/services.dart/favorite_places_service.dart';
import 'package:travel_app/screens/reviews/write_review_screen.dart';
import 'package:travel_app/services.dart/auth_service.dart';

class AllReviewsScreen extends StatefulWidget {
  final PlaceDetail place;
  final VoidCallback onReplyPosted;
  final List<int> initialSelectedRatings;
  final String initialSelectedDate;
  final List<int> initialSelectedMonths;
  final String initialSearchQuery;
  final bool autoFocusSearch;
  final int r5, r4, r3, r2, r1, totalCount;

  const AllReviewsScreen({
    super.key,
    required this.place,
    required this.onReplyPosted,
    this.initialSelectedRatings = const [],
    this.initialSelectedDate = 'Tất cả đánh giá',
    this.initialSelectedMonths = const [],
    this.initialSearchQuery = '',
    this.autoFocusSearch = false,
    required this.r5,
    required this.r4,
    required this.r3,
    required this.r2,
    required this.r1,
    required this.totalCount,
  });

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  late List<int> _selectedRatings;
  late String _selectedDate;
  late List<int> _selectedMonths;
  late String _searchQuery;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _selectedRatings = List.from(widget.initialSelectedRatings);
    _selectedDate = widget.initialSelectedDate;
    _selectedMonths = List.from(widget.initialSelectedMonths);
    _searchQuery = widget.initialSearchQuery;
    _searchController = TextEditingController(text: _searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilter() async {
    final result = await ReviewFilterBottomSheet.show(
      context,
      r5: widget.r5,
      r4: widget.r4,
      r3: widget.r3,
      r2: widget.r2,
      r1: widget.r1,
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
  }

  @override
  Widget build(BuildContext context) {
    int filterCount = _selectedRatings.length + _selectedMonths.length;
    if (_selectedDate != 'Tất cả đánh giá') {
      filterCount += 1;
    }

    List<Review> filteredReviews = widget.place.reviews;

    if (_selectedRatings.isNotEmpty) {
      filteredReviews = filteredReviews
          .where((r) => r.stars != null && _selectedRatings.contains(r.stars))
          .toList();
    }

    if (_selectedDate != 'Tất cả đánh giá') {
      final now = DateTime.now();
      if (_selectedDate == '3 tháng trước') {
        filteredReviews = filteredReviews
            .where(
              (r) =>
                  r.createdAt != null &&
                  now.difference(r.createdAt!).inDays <= 90,
            )
            .toList();
      } else if (_selectedDate == '6 tháng trước') {
        filteredReviews = filteredReviews
            .where(
              (r) =>
                  r.createdAt != null &&
                  now.difference(r.createdAt!).inDays <= 180,
            )
            .toList();
      } else if (_selectedDate == '12 tháng qua') {
        filteredReviews = filteredReviews
            .where(
              (r) =>
                  r.createdAt != null &&
                  now.difference(r.createdAt!).inDays <= 365,
            )
            .toList();
      }
    }

    if (_selectedMonths.isNotEmpty) {
      filteredReviews = filteredReviews
          .where(
            (r) =>
                r.createdAt != null &&
                _selectedMonths.contains(r.createdAt!.month),
          )
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredReviews = filteredReviews.where((r) {
        final titleMatch = r.title?.toLowerCase().contains(query) ?? false;
        final contentMatch = r.content?.toLowerCase().contains(query) ?? false;
        return titleMatch || contentMatch;
      }).toList();
    }

    final hasReviewed = FavoritePlacesService.isLoggedIn &&
        widget.place.reviews.any((r) => r.user?.userId == AuthService.currentUser?.userId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.place.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        actions: [
          if (!hasReviewed)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white, size: 20),
              onPressed: () {
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
            ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đánh giá',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 32),
                RatingSummary(
                  place: widget.place,
                  r5: widget.r5,
                  r4: widget.r4,
                  r3: widget.r3,
                  r2: widget.r2,
                  r1: widget.r1,
                  totalCount: widget.totalCount,
                ),
                const SizedBox(height: 32),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 32),
                const Text(
                  'Tất cả đánh giá',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
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
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _openFilter,
                      icon: const Icon(
                        Icons.tune,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        filterCount > 0 ? 'Bộ lọc • $filterCount' : 'Bộ lọc',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: filterCount > 0
                              ? Colors.white
                              : Colors.white30,
                          width: filterCount > 0 ? 1.5 : 1.0,
                        ),
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
                          controller: _searchController,
                          autofocus: widget.autoFocusSearch,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Tìm kiếm đánh giá',
                            hintStyle: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (filteredReviews.isEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Không tìm thấy kết quả. Hãy thử xóa bộ lọc, thay đổi tìm kiếm hoặc xóa tất cả để đọc đánh giá.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRatings.clear();
                            _selectedDate = 'Tất cả đánh giá';
                            _selectedMonths.clear();
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        child: const Text(
                          'Xóa tất cả các bộ lọc',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredReviews.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Colors.white24, height: 32),
                    itemBuilder: (context, index) {
                      return ReviewItem(
                        review: filteredReviews[index],
                        onReplyPosted: widget.onReplyPosted,
                        placeId: widget.place.placeId,
                      );
                    },
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
