import 'dart:async';
import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/place_detail.dart';
import 'package:travel_app/services.dart/api_service.dart';
import 'package:travel_app/widgets/custom_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:travel_app/widgets/tripadvisor_rating_bar.dart';
import 'package:travel_app/utils/opening_hours_helper.dart';
import 'package:travel_app/widgets/opening_hours_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_app/services.dart/favorite_places_service.dart';
import 'package:travel_app/widgets/about_place_section.dart';
import 'package:travel_app/widgets/place_reviews_section.dart';

class PlaceDetailScreen extends StatefulWidget {
  final int placeId;
  final String? heroImageUrl;

  const PlaceDetailScreen({
    super.key,
    required this.placeId,
    this.heroImageUrl,
  });

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final ApiService _api = ApiService();
  PlaceDetail? _place;
  bool _isLoading = true;
  int _currentImageIndex = 0;
  final PageController _imagePageController = PageController();
  Timer? _timer;
  double? _distanceInKm;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_place != null && _place!.images.length > 1) {
        int nextPage = _currentImageIndex + 1;
        if (nextPage >= _place!.images.length) {
          nextPage = 0;
        }
        if (_imagePageController.hasClients) {
          _imagePageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final detail = await _api.getPlaceDetail(widget.placeId);
    if (mounted) {
      setState(() {
        _place = detail;
        _isLoading = false;
      });
      if (detail != null) {
        _calculateDistance(detail);
      }
    }
  }

  Future<void> _calculateDistance(PlaceDetail p) async {
    if (p.lat == null || p.lng == null) return;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        p.lat!,
        p.lng!,
      );

      if (mounted) {
        setState(() {
          _distanceInKm = distanceInMeters / 1000;
        });
      }
    } catch (e) {
      debugPrint('Lỗi lấy GPS: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentMint),
            )
          : _place == null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background),
      body: const Center(
        child: Text(
          'Không tìm thấy địa điểm',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final p = _place!;
    final images = p.images.isNotEmpty ? p.images : null;

    return CustomScrollView(
      slivers: [
        // ============ SLIVER APP BAR + ẢNH ============
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppColors.background,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Center(
              child: _circleButton(
                Icons.arrow_back_ios_new_rounded,
                () => Navigator.pop(context),
              ),
            ),
          ),
          actions: [
            _circleButton(Icons.share_outlined, () => _shareGoogleMaps(p)),
            const SizedBox(width: 8),
            ValueListenableBuilder<List<int>>(
              valueListenable: FavoritePlacesService.notifier,
              builder: (context, favorites, _) {
                final isFav = favorites.contains(p.placeId);
                return _circleButton(
                  isFav ? Icons.favorite : Icons.favorite_border_rounded,
                  () =>
                      FavoritePlacesService.toggleFavorite(context, p.placeId),
                  iconColor: isFav ? Colors.red : Colors.white,
                );
              },
            ),
            const SizedBox(width: 12),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: images != null
                ? _buildImageGallery(images)
                : _buildPlaceholderImage(),
          ),
        ),

        // ============ NỘI DUNG ============
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER SECTION ---
              _buildHeaderSection(p),

              // --- GIỜ MỞ CỬA ---
              if (p.openingHours != null && p.openingHours!.isNotEmpty) ...[
                _buildOpeningHoursSection(p.openingHours!),
              ],

              // --- GIỚI THIỆU (ABOUT) ---
              AboutPlaceSection(place: p),

              // --- ĐÁNH GIÁ (REVIEWS) ---
              PlaceReviewsSection(
                place: p,
                onReplyPosted: _loadDetail,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // IMAGE GALLERY
  // ============================================================
  Widget _buildImageGallery(List<PlaceImage> images) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _imagePageController,
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _currentImageIndex = i),
          itemBuilder: (_, i) => CustomImage(
            imageUrl: images[i].imageUrl,
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
          ),
        ),
        // Gradient phía dưới ảnh
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.background, Colors.transparent],
              ),
            ),
          ),
        ),
        // Bộ đếm ảnh
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentImageIndex + 1}/${images.length}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return CustomImage(
      imageUrl: widget.heroImageUrl,
      width: double.infinity,
      height: 300,
      fit: BoxFit.cover,
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeaderSection(PlaceDetail p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên địa điểm + Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  p.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24, // Giảm cỡ chữ xuống 24
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (p.reviewPopularityLevel == 'popular' ||
                  true) // Mock showing it
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Icon(Icons.verified, color: Colors.white, size: 24),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Rating + Distance
          Row(
            children: [
              Text(
                p.avgRating.toStringAsFixed(1).replaceAll('.', ','),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              TripAdvisorRatingBar(rating: p.avgRating, size: 16),
              const SizedBox(width: 8),
              Text(
                '(${_formatNumber(p.totalReviews)} đánh giá)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Khoảng cách GPS
              if (_distanceInKm != null)
                Text(
                  '${_distanceInKm!.toStringAsFixed(1).replaceAll('.', ',')} km',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Sub rating line 2
          Text(
            _formatCategories(p),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // Các nút thao tác text
          Row(
            children: [
              if (p.website != null && p.website!.isNotEmpty) ...[
                _linkText('Truy cập trang web', () => _launchUrl(p.website!)),
                const SizedBox(width: 16),
              ],
              if (p.phone != null && p.phone!.isNotEmpty) ...[
                _linkText('Gọi', () => _launchUrl('tel:${p.phone!}')),
                const SizedBox(width: 16),
              ],
            ],
          ),
          const SizedBox(height: 16),

          _linkText('Viết đánh giá', () {}),
        ],
      ),
    );
  }

  String _formatCategories(PlaceDetail p) {
    String priceStr = p.priceRange?.toLowerCase() ?? '';
    String priceSymbol = '';

    if (priceStr.isNotEmpty && !priceStr.contains('miễn phí')) {
      // Phân tích khoảng giá để hiện $ tương ứng
      final numbers = RegExp(r'\d+').allMatches(priceStr.replaceAll('.', ''));
      if (numbers.isNotEmpty) {
        int maxPrice = numbers
            .map((m) => int.parse(m.group(0)!))
            .reduce((a, b) => a > b ? a : b);
        if (maxPrice >= 1000000) {
          priceSymbol = '\$\$\$';
        } else if (maxPrice >= 100000) {
          priceSymbol = '\$\$';
        } else {
          priceSymbol = '\$';
        }
      } else {
        priceSymbol = '\$\$'; // Default if has price but no numbers parsed
      }
    }

    String cat = p.categoryGroup?.name ?? 'Nhà hàng';

    String type = p.placeType ?? 'Kiểu Việt';
    if (type.isEmpty) type = 'Kiểu Việt';

    if (priceSymbol.isNotEmpty) {
      return '$priceSymbol • $cat • $type';
    } else {
      return '$cat • $type';
    }
  }

  Widget _linkText(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    String finalUrl = urlString;
    // Tự động thêm https:// nếu db chỉ lưu tên miền (ví dụ: tansonnhatsaigon.com)
    if (!urlString.startsWith('http') && !urlString.startsWith('tel:')) {
      finalUrl = 'https://$urlString';
    }

    final Uri url = Uri.parse(finalUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $finalUrl');
      }
    } catch (e) {
      debugPrint('Lỗi mở link: $e');
    }
  }

  // ============================================================
  // GIỜ MỞ CỬA
  // ============================================================
  Widget _buildOpeningHoursSection(Map<String, dynamic> hours) {
    final status = OpeningHoursHelper.getStatus(hours);

    return InkWell(
      onTap: () => OpeningHoursBottomSheet.show(context, hours),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white24, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.primaryText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (status.secondaryText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      status.secondaryText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  void _shareGoogleMaps(PlaceDetail p) {
    if (p.lat != null && p.lng != null) {
      final url =
          'https://www.google.com/maps/search/?api=1&query=${p.lat},${p.lng}';
      Share.share('Khám phá ${p.name} trên Google Maps: $url');
    } else {
      Share.share('Khám phá ${p.name} cùng TravelApp!');
    }
  }

  Widget _circleButton(
    IconData icon,
    VoidCallback onTap, {
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _divider() {
    return const Divider(color: Colors.white10, height: 1, thickness: 1);
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
