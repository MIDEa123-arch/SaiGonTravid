import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/place.dart';
import 'package:travel_app/services.dart/api_service.dart';
import 'package:travel_app/screens/home/widgets/experience_list.dart';
import 'package:travel_app/screens/home/widgets/drink_list.dart';
import 'package:travel_app/screens/home/widgets/restaurant_list.dart';
import 'package:travel_app/models/category.dart';

class DiscoverBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final List<Place> nearbyPlaces;
  final bool isLoading;
  final Function(int?) onFilterChanged;

  // BỔ SUNG TỌA ĐỘ
  final double? userLat;
  final double? userLng;
  final List<CategoryGroup> categories;

  const DiscoverBottomSheet({
    super.key,
    required this.scrollController,
    required this.nearbyPlaces,
    required this.isLoading,
    required this.categories,
    required this.onFilterChanged,
    this.userLat, // BỔ SUNG
    this.userLng, // BỔ SUNG
  });

  @override
  State<DiscoverBottomSheet> createState() => _DiscoverBottomSheetState();
}

class _DiscoverBottomSheetState extends State<DiscoverBottomSheet> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();

  IconData _getIconForCategory(CategoryGroup cat) {
    String name = cat.name.toLowerCase();
    if (name.contains('ẩm thực')) return Icons.restaurant_outlined;
    if (name.contains('lưu trú')) return Icons.hotel_outlined;
    if (name.contains('giải trí')) return Icons.local_activity_outlined;
    if (name.contains('thể thao')) return Icons.sports_soccer_outlined;
    if (name.contains('du lịch')) return Icons.explore_outlined;
    if (name.contains('tôn giáo')) return Icons.church_outlined;
    if (name.contains('mua sắm')) return Icons.shopping_bag_outlined;
    if (name.contains('dịch vụ')) return Icons.design_services_outlined;
    return Icons.category_outlined; 
  }

  List<Map<String, dynamic>> get _dynamicFilterOptions {
    List<Map<String, dynamic>> options = [
      {'id': null, 'label': 'Khám phá', 'icon': null},
      {'id': -1, 'label': 'Mục đã lưu', 'icon': Icons.favorite_border},
    ];
    
    for (var cat in widget.categories) {
      options.add({
        'id': cat.id, 
        'label': cat.name,
        'icon': _getIconForCategory(cat),
      });
    }
    
    return options;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.background),
      child: SafeArea(
        top: false,
        child: ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // THANH DANH MỤC CUỘN NGANG ĐÃ HIỂN THỊ FULL
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _dynamicFilterOptions.length,                
                itemBuilder: (context, index) {
                  final option = _dynamicFilterOptions[index];
                  final isSelected = _selectedIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      widget.onFilterChanged(option['id']);
                      // Mẹo: Sau này ông giáo lấy cái option['id'] ở đây truyền lên Map để lọc
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF0B2114),
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.green.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          if (option['icon'] != null) ...[
                            Icon(
                              option['icon'],
                              size: 16,
                              color: isSelected ? Colors.black : Colors.white,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            option['label'],
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 25),

            Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      "Cà phê sáng gần đây",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
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
            Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      "Đặt bàn",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // API LẤY DANH SÁCH 209
            FutureBuilder<List<Place>>(
              // BỔ SUNG TỌA ĐỘ VÀO HÀM NÀY
              future: (widget.userLat != null && widget.userLng != null)
                  ? _apiService.getBestNearbyRestaurants(
                      widget.userLat!,
                      widget.userLng!,
                    )
                  : Future.value(
                      [],
                    ), // Nếu chưa có tọa độ thì trả về rỗng để khỏi lỗi đỏ
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentMint,
                    ),
                  );
                }
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return RestaurantList(places: snapshot.data!);
                }
                return const Text(
                  "Đang cập nhật...",
                  style: TextStyle(color: AppColors.textSecondary),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      "Địa điểm du lịch không thể bỏ qua",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // API LẤY DANH SÁCH 209
            FutureBuilder<List<Place>>(
              // BỔ SUNG TỌA ĐỘ VÀO HÀM NÀY
              future: (widget.userLat != null && widget.userLng != null)
                  ? _apiService.getExperiences()
                  : Future.value(
                      [],
                    ), // Nếu chưa có tọa độ thì trả về rỗng để khỏi lỗi đỏ
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
          ],
        ),
      ),
    );
  }
}
