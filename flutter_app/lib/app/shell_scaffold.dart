import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScaffold({super.key, required this.navigationShell});

  /// CLAUDE.md: 최대 너비 512px, 데스크톱에서 중앙 정렬
  static const double kMaxContentWidth = 512;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= kMaxContentWidth) {
            return navigationShell;
          }
          return Center(
            child: SizedBox(
              width: kMaxContentWidth,
              child: navigationShell,
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: BottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) {
                navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
                if (index == 0) context.go('/');
                if (index == 1) context.go('/favorites');
                if (index == 2) context.go('/settings');
              },
              iconSize: 24,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(navigationShell.currentIndex == 0 ? Icons.menu_book : Icons.menu_book_outlined),
                  label: '홈',
                ),
                BottomNavigationBarItem(
                  icon: Icon(navigationShell.currentIndex == 1 ? Icons.favorite : Icons.favorite_border),
                  label: '즐겨찾기',
                ),
                BottomNavigationBarItem(
                  icon: Icon(navigationShell.currentIndex == 2 ? Icons.settings : Icons.settings_outlined),
                  label: '설정',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
