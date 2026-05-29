import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/place_detail.dart';
import 'package:travel_app/services.dart/api_service.dart';
import 'package:travel_app/services.dart/favorite_places_service.dart';
import 'package:travel_app/screens/place_detail/place_detail_screen.dart';
import 'package:travel_app/widgets/custom_image.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ApiService _api = ApiService();

  final List<LinearGradient> _cardGradients = [
    const LinearGradient(
      colors: [Color(0xFF0C2419), Color(0xFF1A1F1C)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    const LinearGradient(
      colors: [Color(0xFF1B0C24), Color(0xFF1F1A21)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    const LinearGradient(
      colors: [Color(0xFF0C1924), Color(0xFF1A1D1F)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ];

  Future<List<PlaceDetail>> _loadFavoritePlaces(List<int> ids) async {
    if (ids.isEmpty) return [];
    
    // Fetch details of all favorite places in parallel
    final futures = ids.map((id) => _api.getPlaceDetail(id));
    final results = await Future.wait(futures);
    
    // Filter out null results
    return results.whereType<PlaceDetail>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yêu thích',
          style: GoogleFonts.beVietnamPro(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<int>>(
        valueListenable: FavoritePlacesService.notifier,
        builder: (context, favoriteIds, _) {
          if (favoriteIds.isEmpty) {
            return _buildEmptyState();
          }

          return FutureBuilder<List<PlaceDetail>>(
            future: _loadFavoritePlaces(favoriteIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryEmerald,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final places = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final p = places[index];
                  final gradient = _cardGradients[index % _cardGradients.length];
                  return _buildFavoriteCard(p, gradient);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFavoriteCard(PlaceDetail p, LinearGradient gradient) {
    // Generate star string matching standard Tripadvisor layout in screen-favorites.png
    String stars = '★' * p.avgRating.round();
    if (stars.isEmpty) stars = '★';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceDetailScreen(
              placeId: p.placeId,
              heroImageUrl: p.images.isNotEmpty ? p.images.first.imageUrl : null,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        height: 240,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.04), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Cover image
            Expanded(
              flex: 12,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                    child: CustomImage(
                      imageUrl: p.images.isNotEmpty ? p.images.first.imageUrl : null,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  
                  // Premium Heart Button (positioned on top-right, aligned with screen-favorites.png)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: GestureDetector(
                      onTap: () async {
                        await FavoritePlacesService.toggleFavorite(context, p.placeId);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.4),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Info Footer
            Expanded(
              flex: 9,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        Text(
                          p.placeType ?? 'Địa điểm',
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        
                        // Render Tripadvisor stars
                        Text(
                          stars,
                          style: GoogleFonts.beVietnamPro(
                            color: AppColors.primaryEmerald,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        
                        Text(
                          '${p.avgRating}',
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    
                    // Dummy TripAdvisor trip details matching screen-favorites.png
                    Text(
                      'Đã thêm vào 1 chuyến đi',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white30,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryEmerald.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_outline_rounded,
                color: AppColors.primaryEmerald,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Danh sách yêu thích trống',
              style: GoogleFonts.beVietnamPro(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Những địa điểm bạn yêu thích sẽ hiển thị tại đây để bạn có thể lên kế hoạch cho chuyến đi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                color: Colors.white38,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
