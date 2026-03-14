import 'package:flutter/material.dart';
import '../app/theme.dart';

class EmotionChip extends StatelessWidget {
  final String label;
  final String? emoji;
  final bool selected;
  final VoidCallback? onTap;

  const EmotionChip({
    super.key,
    required this.label,
    this.emoji,
    this.selected = false,
    this.onTap,
  });

  static const double size = 64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = selected
        ? (isDark ? Color(AppColors.pointDark) : AppColors.point)
        : theme.dividerColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.cardColor,
                border: Border.all(color: borderColor, width: selected ? 2 : 1),
              ),
              alignment: Alignment.center,
              child: Text(
                emoji ?? '✨',
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
