import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/place_detail.dart';
import 'package:travel_app/screens/place_detail/about_place_screen.dart';

class AboutPlaceSection extends StatelessWidget {
  final PlaceDetail place;

  const AboutPlaceSection({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final validUtilities = _getValidUtilities();
    final hasDescription =
        place.description != null && place.description!.isNotEmpty;
    final hasUtilities = validUtilities.isNotEmpty;

    if (!hasDescription && !hasUtilities) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Giới thiệu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (hasDescription) ...[
            Text(
              place.description!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
          ] else if (hasUtilities) ...[
            // Chỉ hiển thị tối đa 2 utilities trong preview khi không có giới thiệu
            ...validUtilities
                .take(2)
                .map((u) => _buildUtilityItem(u, preview: true))
                .toList(),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        AboutPlaceScreen(place: place),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;

                          var tween = Tween(
                            begin: begin,
                            end: end,
                          ).chain(CurveTween(curve: curve));

                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen.withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppColors.primaryEmerald, width: 1),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Xem chi tiết',
                style: TextStyle(
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

  List<Map<String, dynamic>> _getValidUtilities() {
    if (place.utilities == null) return [];

    final valid = <Map<String, dynamic>>[];

    if (place.utilities is Map) {
      final map = place.utilities as Map;
      final tags = map['tags'];
      if (tags is List && tags.isNotEmpty) {
        valid.add({'title': 'Tiện ích', 'tags': tags});
      }
    } else if (place.utilities is List) {
      for (var u in place.utilities) {
        if (u is Map) {
          final tags = u['tags'];
          if (tags is List && tags.isNotEmpty) {
            valid.add(Map<String, dynamic>.from(u));
          }
        }
      }
    }
    return valid;
  }

  Widget _buildUtilityItem(
    Map<String, dynamic> utility, {
    bool preview = false,
  }) {
    final title = utility['title']?.toString() ?? 'Tiện ích';
    final tags = (utility['tags'] as List).map((e) => e.toString()).toList();

    // In preview mode, limit tags to 5
    final displayTags = preview ? tags.take(5).toList() : tags;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: displayTags.map((rawTag) {
                String tag = rawTag;
                Widget? icon;
                final lowerTag = tag.toLowerCase();

                if (lowerTag.contains('(ko có)') ||
                    lowerTag.contains('(không có)')) {
                  icon = const Icon(Icons.block, color: Colors.red, size: 16);
                  tag = tag
                      .replaceAll(
                        RegExp(
                          r'\s*\(\s*ko có\s*\)|\s*\(\s*không có\s*\)',
                          caseSensitive: false,
                        ),
                        '',
                      )
                      .trim();
                } else if (lowerTag.contains('(có)')) {
                  icon = const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  );
                  tag = tag
                      .replaceAll(
                        RegExp(r'\s*\(\s*có\s*\)', caseSensitive: false),
                        '',
                      )
                      .trim();
                } else if (lowerTag.contains('không') ||
                    lowerTag.contains('cấm')) {
                  icon = const Icon(Icons.block, color: Colors.red, size: 16);
                } else if (lowerTag.contains('có')) {
                  icon = const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  );
                } else {
                  // Default tick icon for tags if the user meant "all get ticks"
                  icon = const Icon(
                    Icons.check_circle,
                    color: Colors.white70,
                    size: 16,
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[icon, const SizedBox(width: 6)],
                      Expanded(
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
