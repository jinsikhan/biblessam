import 'package:flutter/material.dart';
import '../../app/theme.dart';

class ReaderActionBar extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onExplanation;
  final VoidCallback onShare;
  final bool explanationExpanded;

  const ReaderActionBar({
    super.key,
    required this.isFavorite,
    required this.onFavorite,
    required this.onExplanation,
    required this.onShare,
    required this.explanationExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _ActionChip(
            icon: isFavorite ? Icons.favorite : Icons.favorite_border,
            label: '좋아요',
            color: isFavorite ? const Color(AppColors.heart) : null,
            onTap: onFavorite,
          ),
          const SizedBox(width: 12),
          _ActionChip(
            icon: Icons.lightbulb_outline,
            label: '설명',
            color: explanationExpanded ? AppColors.point : null,
            onTap: onExplanation,
          ),
          const SizedBox(width: 12),
          _ActionChip(
            icon: Icons.share_outlined,
            label: '공유',
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.iconTheme.color;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: c),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: c)),
        ],
      ),
    );
  }
}
