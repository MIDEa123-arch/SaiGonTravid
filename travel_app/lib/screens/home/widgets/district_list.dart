import 'package:flutter/material.dart';
import 'package:travel_app/models/district.dart';
import '../../../core/constants.dart';

class DistrictList extends StatelessWidget {
  final List<District> districts;

  const DistrictList({super.key, required this.districts});

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController(viewportFraction: 0.8);

    return SizedBox(
      height: 250,
      child: PageView.builder(
        controller: controller,
        padEnds: false, // Giúp thẻ đầu tiên nằm sát lề trái
        itemCount: districts.length,
        itemBuilder: (context, index) {
          final district = districts[index];
          final String imageUrl = '1.jpg'; // Just in case district has imageUrl later
          final String encodedPath = imageUrl.split('/').map((e) => Uri.encodeComponent(e)).join('/');
          final String fullUrl = '${ApiConstants.baseUrl.replaceAll('/api', '')}/static/images/$encodedPath';

          return Container(
            margin: const EdgeInsets.only(right: 15),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    fullUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade800),
                  ),
                ),
                Container(
                  // LỚP PHỦ BÓNG ĐEN GIỮ NGUYÊN
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        district.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        "Thành phố Hồ Chí Minh",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
