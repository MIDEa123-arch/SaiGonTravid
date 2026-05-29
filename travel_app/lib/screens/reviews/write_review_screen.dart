import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/place_detail.dart';
import 'package:travel_app/services.dart/api_service.dart';
import 'package:travel_app/services.dart/auth_service.dart';

/// WriteReviewScreen – Màn hình viết đánh giá style TripAdvisor
/// Gồm: rating 5 sao (vòng tròn emerald), nội dung, upload ảnh
class WriteReviewScreen extends StatefulWidget {
  final PlaceDetail place;

  const WriteReviewScreen({super.key, required this.place});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen>
    with SingleTickerProviderStateMixin {
  int _selectedRating = 0; // 0 = chưa chọn, 1-5
  final _contentController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _successController;
  late Animation<double> _successScale;

  // Labels cho từng mức rating (style TripAdvisor)
  static const List<String> _ratingLabels = [
    '', // index 0 – chưa chọn
    'Rất tệ 😞',
    'Tệ 😕',
    'Bình thường 😐',
    'Tốt 😊',
    'Xuất sắc 🤩',
  ];

  static const List<Color> _ratingColors = [
    Colors.transparent,
    Color(0xFFE53935), // 1 sao
    Color(0xFFF4511E), // 2 sao
    Color(0xFFFB8C00), // 3 sao
    Color(0xFF43A047), // 4 sao
    Color(0xFF00897B), // 5 sao
  ];

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _successController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _selectedRating > 0 &&
        _contentController.text.trim().length >= 20;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      print("Lỗi chọn ảnh review: $e");
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);

    final userId = AuthService.currentUser?.userId;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vui lòng đăng nhập để viết đánh giá.',
              style: GoogleFonts.beVietnamPro(),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isSubmitting = false);
      }
      return;
    }

    String? uploadedImageUrl;

    // 1. Upload review image first if selected
    if (_selectedImage != null) {
      uploadedImageUrl = await ApiService().uploadReviewImage(_selectedImage!.path);
      if (uploadedImageUrl == null) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi khi tải ảnh đánh giá lên server.',
                style: GoogleFonts.beVietnamPro(),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    }

    // 2. Submit the review to DB
    final errorDetail = await ApiService().createReview(
      placeId: widget.place.placeId,
      userId: userId,
      rating: _selectedRating,
      comment: _contentController.text.trim(),
      imageUrl: uploadedImageUrl,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (errorDetail == null) {
      setState(() {
        _submitted = true;
      });
      _successController.forward();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorDetail,
            style: GoogleFonts.beVietnamPro(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
        title: Text(
          'Viết đánh giá',
          style: GoogleFonts.beVietnamPro(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _submitted ? _buildSuccessState() : _buildFormBody(),
    );
  }

  // ────────────────────────────── Form body ──────────────────────────────
  Widget _buildFormBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên địa điểm
          Text(
            widget.place.name,
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (widget.place.address != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                widget.place.address!,
                style: GoogleFonts.beVietnamPro(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ),

          const SizedBox(height: 32),
          _buildSectionDivider('Xếp hạng tổng thể'),

          // Rating stars (style TripAdvisor – vòng tròn)
          const SizedBox(height: 16),
          _buildRatingRow(),

          // Label mức rating
          if (_selectedRating > 0) ...[
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _ratingLabels[_selectedRating],
                key: ValueKey(_selectedRating),
                style: GoogleFonts.beVietnamPro(
                  color: _ratingColors[_selectedRating],
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),
          _buildSectionDivider('Chia sẻ trải nghiệm'),
          const SizedBox(height: 8),
          Text(
            'Bạn thích / không thích điều gì? Địa điểm này phù hợp với ai?',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),

          // Nội dung
          _buildTextField(
            controller: _contentController,
            hint: 'Viết cảm nhận của bạn về địa điểm này...',
            maxLines: 7,
            maxLength: 2000,
          ),

          // Hint đếm ký tự
          ValueListenableBuilder(
            valueListenable: _contentController,
            builder: (context, val, _) {
              final len = _contentController.text.trim().length;
              final ok = len >= 20;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  ok ? '$len / 2000 ký tự' : 'Cần thêm ${20 - len} ký tự',
                  style: GoogleFonts.beVietnamPro(
                    color: ok ? Colors.white38 : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 28),
          _buildSectionDivider('Thêm ảnh (tuỳ chọn)'),
          const SizedBox(height: 12),
          _buildPhotoRow(),

          const SizedBox(height: 32),

          // Nút Submit
          ValueListenableBuilder(
            valueListenable: _contentController,
            builder: (context, ___, __) {
              final canSubmit = _canSubmit;
              return SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _isSubmitting || !canSubmit ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canSubmit
                        ? AppColors.primaryEmerald
                        : AppColors.surface,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Gửi đánh giá',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: canSubmit ? Colors.white : Colors.white38,
                          ),
                        ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ────────────────────────── Rating row ─────────────────────────────────
  Widget _buildRatingRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        final star = index + 1;
        final isSelected = star <= _selectedRating;
        final color = isSelected ? _ratingColors[_selectedRating] : Colors.white24;

        return GestureDetector(
          onTap: () => setState(() => _selectedRating = star),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? color : Colors.transparent,
              border: Border.all(
                color: isSelected ? color : Colors.white30,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                '$star',
                style: GoogleFonts.beVietnamPro(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ────────────────────────── Photo row ──────────────────────────────────
  Widget _buildPhotoRow() {
    return SizedBox(
      height: 90,
      child: Row(
        children: [
          if (_selectedImage != null) ...[
            Container(
              width: 90,
              height: 90,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(
                      File(_selectedImage!.path),
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: _clearImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryEmerald.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.primaryEmerald,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thêm ảnh',
                      style: GoogleFonts.beVietnamPro(
                        color: AppColors.primaryEmerald,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────── Success state ────────────────────────────────
  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: AnimatedBuilder(
          animation: _successController,
          builder: (context, child) {
            return Transform.scale(
              scale: _successScale.value,
              child: child,
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentMint, AppColors.primaryEmerald],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryEmerald.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Cảm ơn bạn! 🎉',
                style: GoogleFonts.beVietnamPro(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Đánh giá của bạn đã được gửi thành công và đang chờ kiểm duyệt.',
                style: GoogleFonts.beVietnamPro(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryEmerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Xong',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────── Helpers ────────────────────────────────────────────
  Widget _buildSectionDivider(String title) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.beVietnamPro(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: Colors.white12)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int maxLength = 200,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 15),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.beVietnamPro(
          color: Colors.white30,
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(16),
        counterStyle: GoogleFonts.beVietnamPro(
          color: Colors.white24,
          fontSize: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primaryEmerald,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
