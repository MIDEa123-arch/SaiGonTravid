import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/user.dart';
import 'package:travel_app/services.dart/auth_service.dart';
import 'package:travel_app/screens/auth/login_screen.dart';
import 'package:travel_app/screens/auth/register_screen.dart';
import 'package:travel_app/screens/account/favorites_screen.dart';
import 'package:travel_app/screens/auth/edit_profile_screen.dart';
import 'package:travel_app/services.dart/api_service.dart';



/// AccountScreen – Màn hình Tài khoản theo phong cách Tripadvisor Dark Theme
/// Tích hợp đầy đủ Reactive State từ AuthService.currentUserNotifier
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Tài khoản',
          style: GoogleFonts.beVietnamPro(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ValueListenableBuilder<AppUser?>(
        valueListenable: AuthService.currentUserNotifier,
        builder: (context, user, child) {
          if (user == null) {
            return _buildGuestView(context);
          } else {
            return _buildProfileView(context, user);
          }
        },
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Trạng thái CHƯA ĐĂNG NHẬP (Guest View)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildGuestView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Icon minh họa lớn phong cách Tripadvisor
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(
                color: AppColors.primaryEmerald.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.person_outline_rounded,
                color: AppColors.accentMint,
                size: 56,
              ),
            ),
          ),
          const SizedBox(height: 36),
          // Tiêu đề chào mừng
          Text(
            'Chào mừng bạn đến với SaiGonTravid!',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          // Text phụ giới thiệu tính năng
          Text(
            'Đăng nhập để lưu địa điểm yêu thích, gửi đánh giá và quản lý chuyến đi của bạn.',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              color: Colors.white60,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          // Nút Đăng nhập (Emerald)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryEmerald,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Đăng nhập',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Nút Đăng ký (Outlined)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Tạo tài khoản mới',
                style: GoogleFonts.beVietnamPro(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Trạng thái ĐÃ ĐĂNG NHẬP (Profile View)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildProfileView(BuildContext context, AppUser user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Khung thông tin cá nhân (Profile Header Card) ──
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Avatar tròn nâng cấp với ClipRRect và NetworkImage fallback
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentMint,
                    ),
                    child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(36),
                            child: Image.network(
                              user.avatarUrl!.startsWith('/static')
                                  ? ApiService().getAvatarFullUrl(user.avatarUrl!)
                                  : user.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    user.initials,
                                    style: GoogleFonts.beVietnamPro(
                                      color: Colors.black,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Text(
                              user.initials,
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.black,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 18),
                  // Tên và email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Tiêu đề mục quản lý ──
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'CÁ NHÂN HÓA TRẢI NGHIỆM',
              style: GoogleFonts.beVietnamPro(
                color: Colors.white30,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // ── Danh sách tùy chọn (Tripadvisor Style) ──
          _buildSettingsItem(
            icon: Icons.favorite_border_rounded,
            title: 'Địa điểm yêu thích của tôi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.map_outlined,
            title: 'Chuyến đi của tôi',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang được phát triển')),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.settings_outlined,
            title: 'Cài đặt tài khoản',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang được phát triển')),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.help_outline_rounded,
            title: 'Trợ giúp & Hỗ trợ',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang được phát triển')),
              );
            },
          ),

          const SizedBox(height: 48),

          // ── Nút Đăng xuất ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () async {
                await AuthService.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã đăng xuất thành công.',
                        style: GoogleFonts.beVietnamPro(),
                      ),
                      backgroundColor: AppColors.surface,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: Colors.redAccent.withOpacity(0.3),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Đăng xuất',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Helper builder cho hàng tùy chọn cài đặt ──
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.white70, size: 22),
        title: Text(
          title,
          style: GoogleFonts.beVietnamPro(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white24,
          size: 14,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
