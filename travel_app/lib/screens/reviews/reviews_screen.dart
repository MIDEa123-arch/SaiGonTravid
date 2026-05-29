import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/place.dart';
import 'package:travel_app/models/user.dart';
import 'package:travel_app/models/user_review.dart';
import 'package:travel_app/services.dart/auth_service.dart';
import 'package:travel_app/services.dart/api_service.dart';
import 'package:travel_app/services.dart/recent_places_service.dart';
import 'package:travel_app/screens/auth/login_screen.dart';
import 'package:travel_app/screens/place_detail/place_detail_screen.dart';
import 'package:travel_app/widgets/custom_image.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final ApiService _api = ApiService();
  bool _isLoadingReviews = false;
  List<UserReview> _userReviews = [];

  @override
  void initState() {
    super.initState();
    _loadUserReviews();
    
    // Listen to login changes to reload reviews
    AuthService.currentUserNotifier.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthService.currentUserNotifier.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    _loadUserReviews();
  }

  Future<void> _loadUserReviews() async {
    final userId = AuthService.currentUser?.userId;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _userReviews = [];
          _isLoadingReviews = false;
        });
      }
      return;
    }

    setState(() => _isLoadingReviews = true);
    final reviews = await _api.getUserReviews(userId);
    if (mounted) {
      setState(() {
        _userReviews = reviews;
        _isLoadingReviews = false;
      });
    }
  }

  void _showReviewOptions(UserReview r) {
    final userId = AuthService.currentUser?.userId;
    if (userId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: Text(
                  'Xóa đánh giá của bạn',
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteReview(r);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteReview(UserReview r) {
    final userId = AuthService.currentUser?.userId;
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Xóa đánh giá?',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn xóa đánh giá này? Thao tác này không thể hoàn tác.',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: GoogleFonts.beVietnamPro(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await _api.deleteReview(r.placeId, r.reviewId, userId);
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã xóa đánh giá thành công.',
                          style: GoogleFonts.beVietnamPro(),
                        ),
                        backgroundColor: AppColors.primaryEmerald,
                      ),
                    );
                    _loadUserReviews();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Không thể xóa đánh giá. Vui lòng thử lại.',
                          style: GoogleFonts.beVietnamPro(),
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Xóa',
                style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'SaiGonTravid',
          style: GoogleFonts.beVietnamPro(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          ValueListenableBuilder<AppUser?>(
            valueListenable: AuthService.currentUserNotifier,
            builder: (context, user, _) {
              if (user == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryEmerald, width: 1.5),
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.surface,
                      backgroundImage: user.avatarUrl != null
                          ? NetworkImage(
                              user.avatarUrl!.startsWith('/static')
                                  ? _api.getAvatarFullUrl(user.avatarUrl!)
                                  : user.avatarUrl!,
                            )
                          : null,
                      child: user.avatarUrl == null
                          ? Text(
                              user.initials,
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryEmerald,
        onRefresh: () async {
          await _loadUserReviews();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section A: Đã xem gần đây (Recent Places)
              _buildRecentPlacesSection(),
              
              const SizedBox(height: 24),
              
              // Section B: Đã đánh giá (My Reviews)
              ValueListenableBuilder<AppUser?>(
                valueListenable: AuthService.currentUserNotifier,
                builder: (context, user, _) {
                  if (user == null) {
                    return _buildLoginPrompt();
                  } else {
                    return _buildMyReviewsSection();
                  }
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentPlacesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            'Đã xem gần đây',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ValueListenableBuilder<int>(
            valueListenable: RecentPlacesService.notifier,
            builder: (context, _, __) {
              return FutureBuilder<List<Place>>(
                future: RecentPlacesService.getRecentPlaces(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyStateHorizontal(
                      icon: Icons.history_rounded,
                      message: 'Lịch sử xem trống.',
                    );
                  }
                  final places = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: places.length,
                    itemBuilder: (context, index) {
                      final p = places[index];
                      return _buildRecentPlaceCard(p);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPlaceCard(Place p) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceDetailScreen(placeId: p.id, heroImageUrl: p.imageUrl),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: CustomImage(
                  imageUrl: p.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildTripAdvisorStars(p.avgRating.round()),
                      const SizedBox(width: 4),
                      Text(
                        '(${p.totalReviews})',
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  if (p.placeType != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      p.placeType!,
                      style: GoogleFonts.beVietnamPro(
                        color: AppColors.primaryEmerald,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đã đánh giá',
                style: GoogleFonts.beVietnamPro(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_isLoadingReviews)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryEmerald,
                  ),
                ),
            ],
          ),
        ),
        if (!_isLoadingReviews && _userReviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: _buildEmptyState(
              icon: Icons.rate_review_outlined,
              title: 'Chưa có đánh giá nào',
              subtitle: 'Những địa điểm bạn đánh giá sẽ hiển thị tại đây.',
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _userReviews.length,
            itemBuilder: (context, index) {
              final r = _userReviews[index];
              return _buildUserReviewCard(r);
            },
          ),
      ],
    );
  }

  Widget _buildUserReviewCard(UserReview r) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceDetailScreen(placeId: r.placeId, heroImageUrl: r.placeImageUrl),
          ),
        ).then((_) => _loadUserReviews()); // reload in case average rating changed
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomImage(
                imageUrl: r.placeImageUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          r.placeName,
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showReviewOptions(r),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white60,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (r.placeAddress != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      r.placeAddress!,
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTripAdvisorStars(r.rating),
                      const SizedBox(width: 8),
                      Text(
                        r.createdAt != null
                            ? '${r.createdAt!.day}/${r.createdAt!.month}/${r.createdAt!.year}'
                            : '',
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (r.title != null && r.title!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      r.title!,
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (r.comment != null && r.comment!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      r.comment!,
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripAdvisorStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final active = i < rating;
        return Container(
          margin: const EdgeInsets.only(right: 2),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.primaryEmerald : Colors.transparent,
            border: Border.all(
              color: active ? AppColors.primaryEmerald : Colors.white24,
              width: 1.2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyStateHorizontal({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white24, size: 36),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.beVietnamPro(
              color: Colors.white30,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryEmerald.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryEmerald, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.beVietnamPro(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: GoogleFonts.beVietnamPro(
                color: Colors.white38,
                fontSize: 12,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryEmerald.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rate_review_outlined,
              color: AppColors.primaryEmerald,
              size: 30,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Xem các đánh giá của bạn',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đăng nhập để chia sẻ trải nghiệm, lưu trữ đánh giá cá nhân và giúp đỡ hàng triệu khách du lịch khác.',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white54,
              fontSize: 12,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => LoginScreen.push(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Đăng nhập ngay',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
