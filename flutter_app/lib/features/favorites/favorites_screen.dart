import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/favorite.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../reader/chapter_reader_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final list = storage.favorites;

    return Scaffold(
      appBar: AppBar(title: const Text('즐겨찾기')),
      body: list.isEmpty
          ? const EmptyState(
              message: '아직 저장한 말씀이 없어요',
              emoji: '❤️',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final f = list[i];
                return _FavoriteTile(
                  favorite: f,
                  onTap: () => context.push(
                    '/reader/${Uri.encodeComponent(f.book)}/${f.chapter}?ref=${Uri.encodeComponent(f.reference)}',
                  ),
                  onDismiss: () => _removeWithUndo(context, storage, f),
                );
              },
            ),
    );
  }

  void _removeWithUndo(BuildContext context, StorageService storage, Favorite f) {
    storage.removeFavorite(f.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('즐겨찾기에서 제거했어요'),
        action: SnackBarAction(
          label: '취소',
          onPressed: () => storage.addFavorite(f),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  final Favorite favorite;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _FavoriteTile({
    required this.favorite,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(favorite.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.errorContainer,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                favorite.reference,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (favorite.verseText != null && favorite.verseText!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  favorite.verseText!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                favorite.createdAt.length >= 10 ? favorite.createdAt.substring(0, 10) : favorite.createdAt,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
