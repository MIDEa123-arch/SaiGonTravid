import 'package:flutter/material.dart';
import 'package:travel_app/core/app_colors.dart';

class TripAdvisorRatingBar extends StatelessWidget {
  final double rating;
  final double size;

  const TripAdvisorRatingBar({super.key, required this.rating, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (rating >= index + 0.75) {
          return _buildBubble(1.0);
        } else if (rating >= index + 0.25) {
          return _buildBubble(0.5);
        } else {
          return _buildBubble(0.0);
        }
      }),
    );
  }

  Widget _buildBubble(double fill) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryEmerald, width: 2),
      ),
      child: fill > 0
          ? ClipOval(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: fill,
                child: Container(color: AppColors.primaryEmerald),
              ),
            )
          : null,
    );
  }
}
