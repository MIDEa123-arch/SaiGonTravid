import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/place.dart';
import 'package:travel_app/screens/place_detail/place_detail_screen.dart';
import 'package:travel_app/widgets/custom_image.dart';
import 'package:travel_app/services.dart/recent_places_service.dart';
import 'package:travel_app/services.dart/favorite_places_service.dart';

class ExperienceList extends StatelessWidget {
  final List<Place> places;
  const ExperienceList({super.key, required this.places});

  @override
  Widget build(BuildContext context) {
    // 1. Dùng PageController với viewportFraction nhỏ hơn để hiện được gần 2 thẻ
    final PageController controller = PageController(viewportFraction: 0.55);

    return SizedBox(
      height: 380, // Tăng chiều cao đủ cho ảnh dọc và cụm chữ
      child: PageView.builder(
        controller: controller,
        padEnds: false, // Dịch sát lề trái
        itemCount: places
            .length, // Lấy list 209 thay vì lặp vô tận (nếu ông muốn vô tận thì sửa thành 1000)
        itemBuilder: (context, index) {
          final p = places[index];

          return GestureDetector(
            onTap: () {
              RecentPlacesService.addRecentPlace(p);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PlaceDetailScreen(placeId: p.id, heroImageUrl: p.imageUrl),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. ẢNH ĐỊA ĐIỂM + NÚT TIM
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CustomImage(
                          imageUrl: p.imageUrl,
                          width: double.infinity,
                          height: 240, // Ảnh cao dọc
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Nút tim trắng ở góc phải
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => FavoritePlacesService.toggleFavorite(context, p.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: ValueListenableBuilder<List<int>>(
                              valueListenable: FavoritePlacesService.notifier,
                              builder: (context, favorites, _) {
                                final isFav = favorites.contains(p.id);
                                return Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border_rounded,
                                  size: 20,
                                  color: isFav ? Colors.red : Colors.black,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. TIÊU ĐỀ: 17, bold, trắng, tối đa 2 dòng (Giữ nguyên định dạng của ông)
                  Text(
                    p.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // 3. HÀNG ĐÁNH GIÁ: Số 14 + Chấm tròn 14 + Số lượt đánh giá
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "${p.avgRating}",
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        children: List.generate(5, (dotIndex) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Icon(
                              Icons.circle,
                              size: 14,
                              color: (p.avgRating > dotIndex)
                                  ? AppColors.accentMint
                                  : const Color.fromARGB(
                                      255,
                                      218,
                                      217,
                                      217,
                                    ).withOpacity(0.3),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 4),
                      // Hiển thị tổng số đánh giá
                      Text(
                        "(${(p.totalReviews).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')})",
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 4. GIÁ (Hoặc Miễn phí): 16, trắng
                  Text(
                    // Kiểm tra kỹ: Nếu null HOẶC chuỗi rỗng thì in "Miễn phí", ngược lại in giá tiền
                    (p.priceRange == null || p.priceRange!.trim().isEmpty)
                        ? "Miễn phí"
                        : p.priceRange!,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
