import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';
import 'package:travel_app/widgets/tripadvisor_rating_bar.dart';
import 'package:travel_app/models/place_detail.dart';

class RatingSummary extends StatelessWidget {
  final PlaceDetail place;
  final int r5;
  final int r4;
  final int r3;
  final int r2;
  final int r1;
  final int totalCount;

  const RatingSummary({
    super.key,
    required this.place,
    required this.r5,
    required this.r4,
    required this.r3,
    required this.r2,
    required this.r1,
    required this.totalCount,
  });

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Xuất sắc';
    if (rating >= 4.0) return 'Tốt';
    if (rating >= 3.0) return 'Trung bình';
    if (rating >= 2.0) return 'Kém';
    return 'Rất tệ';
  }

  Widget _buildRatingBar(String label, int count, int total) {
    final ratio = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 75,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              if (ratio > 0)
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.accentMint,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 20,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.avgRating.toStringAsFixed(1).replaceAll('.', ','),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 54,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getRatingText(place.avgRating),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TripAdvisorRatingBar(
                  rating: place.avgRating,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  '${place.totalReviews}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            children: [
              _buildRatingBar('Xuất sắc', r5, totalCount),
              const SizedBox(height: 6),
              _buildRatingBar('Tốt', r4, totalCount),
              const SizedBox(height: 6),
              _buildRatingBar('Trung bình', r3, totalCount),
              const SizedBox(height: 6),
              _buildRatingBar('Kém', r2, totalCount),
              const SizedBox(height: 6),
              _buildRatingBar('Rất tệ', r1, totalCount),
            ],
          ),
        ),
      ],
    );
  }
}
