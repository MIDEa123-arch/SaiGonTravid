import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/user.dart';
import 'package:travel_app/services.dart/auth_service.dart';
import 'package:travel_app/screens/auth/login_screen.dart';
import 'package:travel_app/widgets/login_bottom_sheet.dart';
import 'package:travel_app/screens/trips/create_trip_screen.dart';
import 'package:travel_app/models/trip.dart';
import 'package:travel_app/services.dart/api_service.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen>
    with SingleTickerProviderStateMixin {
  bool _isFabOpen = false;
  final ApiService _apiService = ApiService();

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ValueListenableBuilder<AppUser?>(
        valueListenable: AuthService.currentUserNotifier,
        builder: (context, user, child) {
          final isLoggedIn = user != null;
          return Stack(
            children: [
              // 1. NỘI DUNG CHÍNH CỦA MÀN HÌNH
              SafeArea(
                child: isLoggedIn
                    ? _buildTripsList()
                    : _buildGuestView(context),
              ),

              // 2. LỚP PHỦ MÀU ĐEN MỜ KHI MỞ MENU FAB (Dim background)
              AnimatedOpacity(
                opacity: _isFabOpen ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: _isFabOpen
                    ? GestureDetector(
                        onTap: _toggleFab, // Bấm ra ngoài để đóng
                        child: Container(color: Colors.black.withOpacity(0.7)),
                      )
                    : const SizedBox.shrink(),
              ),
              if (isLoggedIn)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_isFabOpen)
                        Column(
                          children: [
                            // 1. NÚT TẠO CHUYẾN ĐI THỦ CÔNG
                            _buildFabOption(
                              title: "Tạo một chuyến đi",
                              icon: Icons.add_location_alt_outlined,
                              heroTag: "btn_create_trip_manual",
                              onPressed: () async {
                                _toggleFab();
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CreateTripScreen(),
                                  ),
                                );
                                setState(() {}); // Refresh future
                              },
                            ),

                            const SizedBox(height: 20),

                            // 2. NÚT TẠO CHUYẾN ĐI VỚI AI
                            _buildFabOption(
                              title: "Tạo chuyến đi với AI",
                              icon: Icons.auto_awesome,
                              heroTag: "btn_create_trip_ai",
                              onPressed: () {
                                _toggleFab();
                                // Gọi qua màn hình AI ở đây
                              },
                            ),
                          ],
                        ),

                      if (_isFabOpen) const SizedBox(height: 15),

                      FloatingActionButton(
                        heroTag: "btn_main_toggle",
                        backgroundColor: Colors.white,
                        onPressed: _toggleFab,
                        shape: const CircleBorder(),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            _isFabOpen ? Icons.close : Icons.add,
                            key: ValueKey<bool>(_isFabOpen),
                            color: Colors.black,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGuestView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const SizedBox(height: 10),
        Text(
          "Chuyến đi",
          style: GoogleFonts.beVietnamPro(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 30),
        _buildEmptyStateBox(
          buttonText: "Đăng nhập",
          onPressed: () {
            LoginBottomSheet.show(context);
          },
        ),
      ],
    );
  }

  Widget _buildTripsList() {
    final user = AuthService.currentUserNotifier.value;
    if (user == null) return const SizedBox.shrink(); // Đề phòng lỗi

    return FutureBuilder<List<Trip>>(
      future: _apiService.getUserTrips(user.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi tải dữ liệu',
              style: GoogleFonts.beVietnamPro(color: Colors.white),
            ),
          );
        }

        final trips = snapshot.data ?? [];
        final upcomingTrips = trips.where((t) => !t.isCompleted).toList();
        final completedTrips = trips.where((t) => t.isCompleted).toList();

        return ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            const SizedBox(height: 10),
            Text(
              "Chuyến đi",
              style: GoogleFonts.beVietnamPro(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 30),

            if (upcomingTrips.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildEmptyStateBox(
                  buttonText: "Tạo một chuyến đi",
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateTripScreen(),
                      ),
                    );
                    setState(() {}); // Refresh future
                  },
                ),
              ),

            ...upcomingTrips.map(
              (trip) => _buildTripCard(
                trip.name,
                '${trip.numDays} ngày',
                trip.coverImageUrl ??
                    'https://images.unsplash.com/photo-1583417319070-4a69db38a482?q=80&w=200&auto=format&fit=crop',
              ),
            ),

            const SizedBox(height: 10),

            if (completedTrips.isNotEmpty) ...[
              Text(
                "Chuyến đi đã hoàn tất",
                style: GoogleFonts.beVietnamPro(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              ...completedTrips.map(
                (trip) => _buildTripCard(
                  trip.name,
                  '${trip.numDays} ngày',
                  trip.coverImageUrl ??
                      'https://images.unsplash.com/photo-1583417319070-4a69db38a482?q=80&w=200&auto=format&fit=crop',
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTripCard(String title, String duration, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 75,
              height: 75,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      duration,
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.grey,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert, color: Colors.grey),
        ],
      ),
    );
  }

  // Hàm dùng chung để tạo nút FAB có text (Đồng nhất giao diện)
  Widget _buildFabOption({
    required String title,
    required IconData icon,
    required String heroTag,
    required VoidCallback onPressed,
  }) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 250, // Cố định chiều dài cho cả 2 nút
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              title,
              style: GoogleFonts.beVietnamPro(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              heroTag: heroTag, // Tránh lỗi trùng heroTag
              backgroundColor: Colors.white,
              onPressed: onPressed,
              shape: const CircleBorder(),
              child: Icon(icon, color: Colors.black, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateBox({required String buttonText, required VoidCallback onPressed}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.favorite, color: Colors.redAccent, size: 28),
              SizedBox(width: 8),
              Icon(Icons.language, color: Colors.tealAccent, size: 28),
              SizedBox(width: 8),
              Icon(Icons.flight, color: Colors.white70, size: 28),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "Lập kế hoạch theo cách của bạn\nvới Chuyến đi...",
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Xây dựng chuyến đi bằng các mục đã lưu hoặc sử dụng AI để nhận đề xuất tùy chỉnh và sắp xếp ý tưởng cho chuyến đi.",
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Text(
                buttonText,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
