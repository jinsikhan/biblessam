import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final String? emoji;

  const EmptyState({super.key, required this.message, this.emoji});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji ?? '📖',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
