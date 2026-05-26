import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/place.dart';
import 'package:travel_app/screens/place_detail/place_detail_screen.dart';
import 'package:travel_app/widgets/custom_image.dart';
class RecentList extends StatelessWidget {
  final List<Place> places;
  const RecentList({super.key, required this.places});

  @override
  Widget build(BuildContext context) {
    // 1. Dùng PageController để tạo hiệu ứng dừng đúng vị trí
    // viewportFraction: 0.85 giúp hiện 85% item chính và lộ một chút item tiếp theo
    final PageController controller = PageController(viewportFraction: 0.85);

    return SizedBox(
      height: 140,
      // 2. Chuyển ListView thành PageView để kích hoạt tính năng Snap (cuộn dính)
      child: PageView.builder(
        controller: controller,
        itemCount: 1000, // Vòng lặp vô tận của ông giáo
        padEnds: false, // Giúp item đầu tiên nằm sát lề trái
        itemBuilder: (context, index) {
          final p = places[index % places.length];

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaceDetailScreen(
                  placeId: p.id,
                  heroImageUrl: p.imageUrl,
                ),
              ),
            ),
            child: Container(
            margin: const EdgeInsets.only(right: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ẢNH ĐỊA ĐIỂM
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomImage(
                    imageUrl: p.imageUrl,
                    width: 100,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 15),

                // THÔNG TIN CHI TIẾT (Giữ nguyên định dạng của ông)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // TIÊU ĐỀ: 18, bold, trắng, tối đa 2 dòng
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

                      // HÀNG ĐÁNH GIÁ: Số 15 + Chấm tròn 15
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
                          const SizedBox(width: 8),
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
                        ],
                      ),

                      const SizedBox(height: 8),

                      // HIỂN THỊ PLACE_TYPE: 17, trắng
                      Text(
                        p.placeType ?? "Địa điểm",
                        style: const TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
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
          );
        },
      ),
    );
  }
}
