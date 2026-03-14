import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../app/theme.dart';
import '../../models/streak.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final streak = storage.streak;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileCard(storage: storage),
          const SizedBox(height: 24),
          Text('읽기 스트릭', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _StreakCard(streak: streak),
          const SizedBox(height: 24),
          Text('앱 설정', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('다크 모드'),
            subtitle: Text(
              storage.themeMode == ThemeMode.dark
                  ? '켜짐'
                  : storage.themeMode == ThemeMode.light
                      ? '꺼짐'
                      : '시스템 설정 따름',
            ),
            value: storage.themeMode == ThemeMode.dark,
            onChanged: (value) {
              storage.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          ListTile(
            title: const Text('번역본 선택'),
            subtitle: const Text('한국어 (기본)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            title: const Text('AI 설명 언어'),
            subtitle: const Text('한국어'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          const ListTile(
            title: Text('앱 정보'),
            subtitle: Text('바이블쌤 v0.1.0'),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final StorageService storage;

  const _ProfileCard({required this.storage});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.point.withOpacity(0.3),
                child: const Icon(Icons.person, size: 32, color: AppColors.point),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '비로그인',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '로그인하면 기기 간 동기화할 수 있어요',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                // Mock: show dialog
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('로그인'),
                    content: const Text(
                      '구글, 카카오, 애플 로그인은 준비 중이에요. 지금은 로컬에서만 저장됩니다.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.point,
                foregroundColor: Colors.white,
              ),
              child: const Text('로그인'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final StreakData streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final currentStreak = streak.currentStreak;
    final minutesToday = streak.totalMinutesToday;
    final dates = streak.dates;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🔥 $currentStreak일 연속', style: Theme.of(context).textTheme.titleSmall),
              Text('오늘 ${minutesToday}분', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 16),
          _MiniCalendar(dates: dates),
        ],
      ),
    );
  }
}

class _MiniCalendar extends StatelessWidget {
  final List<String> dates;

  const _MiniCalendar({required this.dates});

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: DateTime.now(),
      calendarFormat: CalendarFormat.month,
      headerVisible: true,
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          final ds = date.toIso8601String().substring(0, 10);
          if (dates.contains(ds)) {
            return Positioned(
              bottom: 1,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(AppColors.streak),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
  }
}
