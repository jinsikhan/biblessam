import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../app/theme.dart';

class AppSkeleton extends StatelessWidget {
  final double width;
  final double height;

  const AppSkeleton({super.key, this.width = double.infinity, this.height = 16});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey[800]! : AppColors.shimmerBase;
    final highlight = isDark ? Colors.grey[700]! : AppColors.shimmerHighlight;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class AiExplanationSkeleton extends StatelessWidget {
  const AiExplanationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.explanationCardBgDark : AppColors.explanationCardBgLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: double.infinity, height: 14),
          const SizedBox(height: 8),
          AppSkeleton(
            width: MediaQuery.sizeOf(context).width * 0.7,
            height: 14,
          ),
          const SizedBox(height: 8),
          AppSkeleton(
            width: MediaQuery.sizeOf(context).width * 0.85,
            height: 14,
          ),
        ],
      ),
    );
  }
}
