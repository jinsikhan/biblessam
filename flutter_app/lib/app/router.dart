import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/reader/chapter_reader_screen.dart';
import '../features/search/search_screen.dart';
import '../features/search/book_list_screen.dart';
import '../features/search/chapter_list_screen.dart';
import 'shell_scaffold.dart';

enum AppRoute {
  home,
  favorites,
  settings,
  reader,
  search,
  bookList,
  chapterList,
}

final GlobalKey<NavigatorState> _rootNavKey = GlobalKey<NavigatorState>();

/// 앱 전체에서 하나만 사용 (매번 생성 시 라우트 재생성 → initState 반복 → 무한 호출 방지)
final GoRouter appRouter = _createAppRouter();

GoRouter _createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: FavoritesScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/reader/:book/:chapter',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (context, state) {
          final book = state.pathParameters['book']!;
          final chapter = int.tryParse(state.pathParameters['chapter'] ?? '1') ?? 1;
          final ref = state.uri.queryParameters['ref'];
          final verseHighlight = state.uri.queryParameters['verse'];
          return MaterialPage(
            key: state.pageKey,
            child: ChapterReaderScreen(
              book: book,
              chapter: chapter,
              referenceLabel: ref,
              verseHighlight: verseHighlight != null ? int.tryParse(verseHighlight) : null,
            ),
          );
        },
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const SearchScreen(),
        ),
      ),
      GoRoute(
        path: '/books',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: const BookListScreen(),
        ),
      ),
      GoRoute(
        path: '/books/:bookId',
        parentNavigatorKey: _rootNavKey,
        pageBuilder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          return MaterialPage(
            key: state.pageKey,
            child: ChapterListScreen(bookId: bookId),
          );
        },
      ),
    ],
  );
}

@Deprecated('Use appRouter instead')
GoRouter createAppRouter() => _createAppRouter();
