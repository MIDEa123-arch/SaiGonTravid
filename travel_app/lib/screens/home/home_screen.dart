import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_app/models/district.dart';
import 'package:travel_app/models/place.dart';
import 'package:travel_app/screens/home/widgets/district_list.dart';
import 'package:travel_app/screens/home/widgets/experience_list.dart';
import 'package:travel_app/screens/home/widgets/drink_list.dart';
import 'package:travel_app/screens/home/widgets/restaurant_list.dart';
import 'package:travel_app/services.dart/api_service.dart';
import 'package:travel_app/services.dart/location_service.dart';
import '../../../core/app_colors.dart';
import '../../../core/constants.dart';
import 'widgets/recent_list.dart';
import 'package:travel_app/services.dart/recent_places_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  List<Place> nearbyRestaurants = []; // Danh sách để hứng dữ liệu từ API
  bool isLoadingNearby = false; // Biến để hiện loading nếu muốn

  // 2. ĐẶT HÀM ĐÓ Ở ĐÂY NÈ ÔNG GIÁO
  void _loadNearby() async {
    try {
      setState(() => isLoadingNearby = true); // Bắt đầu load thì hiện quay quay

      // Bước A: Lấy vị trí từ Service riêng
      Position position = await LocationService.getUserLocation(context);

      // Bước B: Ném tọa độ qua ApiService để lấy data
      final restaurants = await _apiService.getBestNearbyRestaurants(
        position.latitude,
        position.longitude,
      );

      // Bước C: Cập nhật giao diện
      setState(() {
        nearbyRestaurants = restaurants; // Gán dữ liệu vào list
        isLoadingNearby = false; // Tắt loading
      });
    } catch (e) {
      setState(() => isLoadingNearby = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // 3. Nếu muốn vừa mở App lên là quét vị trí lấy nhà hàng luôn thì gọi ở đây
    _loadNearby();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ĐÃ BỔ SUNG: Bọc Text trong Row và thêm nút Chuông bên phải
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Bạn sắp đến đâu?",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.textPrimary,
                        size: 28,
                      ),
                      onPressed: () {
                        // Nút chuông
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSearchBar(),

              const SizedBox(height: 25), // Khoảng cách mới
              // 3. ĐÃ BỔ SUNG: Khối "Khám phá khu vực lân cận"
              _buildDiscoverySection(),

              const SizedBox(height: 10),

              // PHẦN ĐÃ XEM GẦN ĐÂY (Giữ nguyên của ông)
              const Text(
                "Đã xem gần đây",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: RecentPlacesService.notifier,
                builder: (context, value, child) {
                  return FutureBuilder<List<Place>>(
                    future: RecentPlacesService.getRecentPlaces(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentMint,
                          ),
                        );
                      }
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return RecentList(places: snapshot.data!);
                      }
                      return const Text(
                        "Chưa có dữ liệu. Hãy xem một địa điểm!",
                        style: TextStyle(color: AppColors.textSecondary),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 30),
              const Text(
                "Bạn có thể thích",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              FutureBuilder<List<District>>(
                future: _apiService
                    .getDistricts(), // Đảm bảo hàm này đã có trong ApiService
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentMint,
                      ),
                    );
                  }
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return DistrictList(districts: snapshot.data!);
                  }
                  return const Text(
                    "Không có dữ liệu quận",
                    style: TextStyle(color: AppColors.textSecondary),
                  );
                },
              ),
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.only(top: 30, bottom: 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        "Trải nghiệm không thể bỏ qua tại Thành phố Hồ Chí Minh",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Nút Xem tất cả
                      },
                      child: const Text(
                        "Xem tất cả",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline, // Gạch chân chữ
                          decorationColor: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // API LẤY DANH SÁCH 209
              FutureBuilder<List<Place>>(
                future: _apiService.getExperiences(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentMint,
                      ),
                    );
                  }
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return ExperienceList(places: snapshot.data!);
                  }
                  return const Text(
                    "Đang cập nhật...",
                    style: TextStyle(color: AppColors.textSecondary),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 30, bottom: 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        "Đồ uống tại Thành phố Hồ Chí Minh",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Nút Xem tất cả
                      },
                      child: const Text(
                        "Xem tất cả",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline, // Gạch chân chữ
                          decorationColor: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // API LẤY DANH SÁCH 209
              FutureBuilder<List<Place>>(
                future: _apiService.getDrinkShop(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentMint,
                      ),
                    );
                  }
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return DrinkList(places: snapshot.data!);
                  }
                  return const Text(
                    "Đang cập nhật...",
                    style: TextStyle(color: AppColors.textSecondary),
                  );
                },
              ),
              const Text(
                "Nơi nghỉ ngơi cuối tuần",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),
              FutureBuilder<List<Place>>(
                future: _apiService.getHotels(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentMint,
                      ),
                    );
                  }
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return ExperienceList(places: snapshot.data!);
                  }
                  return const Text(
                    "Đang cập nhật...",
                    style: TextStyle(color: AppColors.textSecondary),
                  );
                },
              ),
              const SizedBox(height: 36),
              // Hiển thị List Nhà hàng hoặc Loading
              Padding(
                padding: const EdgeInsets.only(top: 30, bottom: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Nhà hàng tốt nhất lân cận",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Hành động khi bấm Xem tất cả nhà hàng
                        print("Chuyển sang trang danh sách nhà hàng");
                      },
                      child: const Text(
                        "Xem tất cả",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline, // Gạch chân
                          decorationColor: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // NỘI DUNG: LOADING / EMPTY / LIST
              // ==========================================
              isLoadingNearby
                  ? const SizedBox(
                      height: 200, // Cho cái xoay xoay nằm trong khung cố định
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.accentMint,
                        ),
                      ),
                    )
                  : nearbyRestaurants.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        "Không tìm thấy nhà hàng nào quanh đây",
                        style: TextStyle(color: Colors.white54, fontSize: 15),
                      ),
                    )
                  : RestaurantList(places: nearbyRestaurants),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        // 2. ĐÃ BỔ SUNG: Vẽ viền màu xanh Mint
        border: Border.all(color: AppColors.darkGreen, width: 1.5),
      ),
      child: const TextField(
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          icon: Icon(Icons.search, color: Colors.white),
          hintText: "Tìm kiếm địa điểm...",
          hintStyle: TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDiscoverySection() {
    return InkWell(
      onTap: () {
        // Hành động khi bấm vào
      },
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // 1. ĐÃ THÊM VIỀN CHO HÌNH
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                // Tạo viền màu xanh Emerald, độ dày 2.0
                border: Border.all(
                  color: AppColors
                      .darkGreen, // Ông có thể đổi thành AppColors.accentMint nếu thích sáng hơn
                  width: 2.0,
                ),
              ),
              child: ClipRRect(
                // Bo tròn nhỏ hơn Container một chút (10 thay vì 12) để hình không đè lên viền
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  '${ApiConstants.baseUrl.replaceAll('/api', '')}/static/images/map_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Khám phá khu vực lân cận",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Thành phố Hồ Chí Minh,\nViệt Nam",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      height: 1.4, // Giãn dòng nhẹ
                    ),
                  ),
                ],
              ),
            ),

            // DẤU MŨI TÊN
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
