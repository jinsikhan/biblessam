import 'package:flutter/material.dart';
import '../app/theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppColors.cardDark : AppColors.cardLight);
    final borderColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: child,
    );

    if (onTap != null) {
      content = _TapScaleChild(onTap: onTap!, child: content);
    }

    return content;
  }
}

/// 탭 시 scale(0.98) — CLAUDE.md "active:scale-[0.98]"
class _TapScaleChild extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _TapScaleChild({required this.onTap, required this.child});

  @override
  State<_TapScaleChild> createState() => _TapScaleChildState();
}

class _TapScaleChildState extends State<_TapScaleChild> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 150),
        child: widget.child,
      ),
    );
  }
}
