import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/models/place_detail.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPlaceScreen extends StatelessWidget {
  final PlaceDetail place;

  const AboutPlaceScreen({super.key, required this.place});

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

  Future<void> _launchUrl(String urlString) async {
    String finalUrl = urlString;
    if (!urlString.startsWith('http') && !urlString.startsWith('tel:')) {
      finalUrl = 'https://$urlString';
    }

    final Uri url = Uri.parse(finalUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $finalUrl');
      }
    } catch (e) {
      debugPrint('Lỗi mở link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final validUtilities = _getValidUtilities();
    final hasDescription =
        place.description != null && place.description!.isNotEmpty;
    final hasContact =
        (place.website != null && place.website!.isNotEmpty) ||
        (place.phone != null && place.phone!.isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Giới thiệu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 40, // Đảm bảo luôn có khoảng trống an toàn
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasDescription) ...[
                Text(
                  place.description!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
              ],

              if (validUtilities.isNotEmpty) ...[
                ...validUtilities.map((u) => _buildUtilityItem(u)).toList(),
                const SizedBox(height: 20),
              ],

              if (hasContact) ...[
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 24),
                const Text(
                  'Liên hệ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (place.website != null && place.website!.isNotEmpty)
                  _buildContactRow(
                    title: 'Truy cập trang web',
                    onTap: () => _launchUrl(place.website!),
                  ),

                if (place.phone != null && place.phone!.isNotEmpty)
                  _buildContactRow(
                    title: 'Gọi ${place.phone!}',
                    onTap: () => _launchUrl('tel:${place.phone!}'),
                  ),

                if (place.googleMapsUrl != null &&
                    place.googleMapsUrl!.isNotEmpty)
                  _buildContactRow(
                    title: 'Xem trên Google Maps',
                    onTap: () => _launchUrl(place.googleMapsUrl!),
                  ),

                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityItem(Map<String, dynamic> utility) {
    final title = utility['title']?.toString() ?? 'Tiện ích';
    final tags = (utility['tags'] as List).map((e) => e.toString()).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: tags.map((rawTag) {
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
                  icon = const Icon(
                    Icons.check_circle,
                    color: Colors.white70,
                    size: 16,
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[icon, const SizedBox(width: 8)],
                      Expanded(
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.4,
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

  Widget _buildContactRow({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_outward, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
