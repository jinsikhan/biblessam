import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/config.dart';
import '../../app/theme.dart';
import '../../models/daily_chapter.dart';
import '../../utils/daily_chapter_fallback.dart';
import '../../models/emotion_theme.dart';
import '../../models/streak.dart';
import '../../services/storage_service.dart';
import '../../services/bible_api_service.dart';
import '../../services/ai_api_service.dart';
import '../../widgets/app_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DailyChapter? _daily;
  String? _dailyError;
  List<EmotionTheme> _emotionThemes = [];
  List<Map<String, dynamic>> _otRefs = [];
  List<Map<String, dynamic>> _ntRefs = [];
  String? _prayer;
  bool _loadingDaily = true;
  bool _loadingPrayer = false;
  String? _selectedEmotionId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final bible = context.read<BibleApiService>();
    final ai = context.read<AiApiService>();
    final storage = context.read<StorageService>();

    setState(() {
      _loadingDaily = true;
      _dailyError = null;
    });

    try {
      final daily = await bible.getDaily();
      if (!mounted) return;
      setState(() {
        _daily = daily ?? getDailyChapterFallback();
        _dailyError = daily == null ? null : null;
        _loadingDaily = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _daily = getDailyChapterFallback();
        _dailyError = null;
        _loadingDaily = false;
      });
    }

    List<EmotionTheme> themes = [];
    try {
      themes = await bible.getEmotionThemes();
      if (!mounted) return;
      setState(() => _emotionThemes = themes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _emotionThemes = []);
    }

    // 구약/신약 추천: 테마 refs에서 한 번에 수집 후 구/신약 구분
    final allRefs = <Map<String, dynamic>>[];
    for (final t in themes) {
      if (t.refs == null || t.refs!.isEmpty) continue;
      for (final r in t.refs!) {
        allRefs.add({
          'book': r.book,
          'chapter': r.chapter,
          'reference': r.reference ?? '${r.book} ${r.chapter}',
          'referenceKo': r.referenceKo ?? r.reference ?? '${r.book} ${r.chapter}',
          'highlight': r.highlight,
          'themeLabel': t.labelKo,
        });
      }
    }
    final ot = allRefs.where((r) => _isOt(r['book'])).take(5).toList();
    final nt = allRefs.where((r) => !_isOt(r['book'])).take(5).toList();
    if (!mounted) return;
    setState(() {
      _otRefs = ot;
      _ntRefs = nt;
    });

    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final prayer = await ai.getPrayer(date: today);
      if (!mounted) return;
      setState(() => _prayer = prayer);
    } catch (_) {
      if (!mounted) return;
      setState(() => _prayer = null);
    }

    storage.notifyListeners();
  }

  bool _isOt(dynamic book) {
    final b = book?.toString().toLowerCase() ?? '';
    const otBooks = [
      'genesis', 'exodus', 'leviticus', 'numbers', 'deuteronomy',
      'joshua', 'judges', 'ruth', '1 samuel', '2 samuel', '1 kings', '2 kings',
      '1 chronicles', '2 chronicles', 'ezra', 'nehemiah', 'esther', 'job',
      'psalms', 'proverbs', 'ecclesiastes', 'song of solomon', 'isaiah',
      'jeremiah', 'lamentations', 'ezekiel', 'daniel', 'hosea', 'joel',
      'amos', 'obadiah', 'jonah', 'micah', 'nahum', 'habakkuk', 'zephaniah',
      'haggai', 'zechariah', 'malachi',
    ];
    return otBooks.any((x) => b == x || b.replaceAll('_', ' ') == x);
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final streak = storage.streak;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildStitchHeader()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: _buildStreakBanner(streak)),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(child: _buildDailyCard(storage)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildEmotionChips(storage)),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _buildSectionTitle('구약 추천', _otRefs, true)),
            SliverToBoxAdapter(child: _buildRecommendationStrip(_otRefs, true)),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _buildSectionTitle('신약 추천', _ntRefs, false)),
            SliverToBoxAdapter(child: _buildRecommendationStrip(_ntRefs, false)),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _buildRecentChapters(storage)),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(child: _buildPrayerCard()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  /// Stitch: 헤더(로고 + BibleSsam + 프로필) + 검색바
  Widget _buildStitchHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.backgroundDark.withOpacity(0.8) : AppColors.backgroundLight.withOpacity(0.8);
    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.point,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.menu_book, color: Theme.of(context).colorScheme.onPrimary, size: 22),
              ),
              const SizedBox(width: 8),
              Text('BibleSsam', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              const Spacer(),
              IconButton(
                onPressed: () => context.push('/settings'),
                icon: Icon(Icons.account_circle, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                style: IconButton.styleFrom(backgroundColor: isDark ? AppColors.dividerDark : const Color(0xFFE2E8F0)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/search'),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 22, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 12),
                  Text('성경, 기도, 주제 검색', style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Stitch: 스트릭 카드 — 불꽃 아이콘, 연속 일수, View Stats, 진행률
  Widget _buildStreakBanner(StreakData streak) {
    final minutes = streak.totalMinutesToday.clamp(0, kStreakTargetMinutes);
    final progress = kStreakTargetMinutes > 0 ? minutes / kStreakTargetMinutes : 0.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.dividerDark : const Color(0xFFF1F5F9)),
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.point.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.local_fire_department, color: AppColors.point, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        streak.currentStreak > 0 ? '${streak.currentStreak}일 연속 읽는 중!' : '오늘 말씀을 읽어 보세요',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text('잘 하고 있어요. 이대로만 해요.', style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('통계 보기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.point)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('오늘 목표 진행', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500)),
                Text('$minutes/${kStreakTargetMinutes}분', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? AppColors.dividerDark : const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.point),
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Stitch: 오늘의 말씀 — 섹션 타이틀 + 다크 카드(그라데이션), 참조, 구절, Read Full Chapter
  Widget _buildDailyCard(StorageService storage) {
    if (_loadingDaily) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.auto_awesome, color: AppColors.point, size: 20), const SizedBox(width: 8), Text('오늘의 말씀', style: Theme.of(context).textTheme.titleMedium)]),
            const SizedBox(height: 12),
            Container(height: 180, decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16)), child: const Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    if (_daily == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_dailyError ?? '오늘의 말씀을 불러올 수 없어요'),
              const SizedBox(height: 12),
              TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh, size: 18), label: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

    final d = _daily!;
    final refLabel = d.displayReference;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.point, size: 20),
              const SizedBox(width: 8),
              Text('오늘의 말씀', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                storage.addRecentChapter(d.book, d.chapter, referenceLabel: refLabel);
                context.push('/reader/${Uri.encodeComponent(d.book)}/${d.chapter}?ref=${Uri.encodeComponent(refLabel)}');
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 180,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.2), Colors.black.withOpacity(0.85)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(refLabel, style: const TextStyle(color: AppColors.point, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                          const SizedBox(height: 6),
                          Text(
                            refLabel,
                            style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () {
                              storage.addRecentChapter(d.book, d.chapter, referenceLabel: refLabel);
                              context.push('/reader/${Uri.encodeComponent(d.book)}/${d.chapter}?ref=${Uri.encodeComponent(refLabel)}');
                            },
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text('전체 장 읽기'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.point,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Stitch: 지금 어떤 마음인가요? — 가로 스크롤 pill 칩
  Widget _buildEmotionChips(StorageService storage) {
    if (_emotionThemes.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 0, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('지금 어떤 마음인가요?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _horizontalScrollWithFadeHint(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 0, right: 48),
              itemCount: _emotionThemes.length,
              itemBuilder: (context, i) {
                final t = _emotionThemes[i];
                final selected = _selectedEmotionId == t.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Material(
                    color: selected ? AppColors.point : unselectedBg,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedEmotionId = t.id);
                        _openEmotionTheme(t, storage);
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: selected ? null : Border.all(color: borderColor),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          t.labelKo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                            color: selected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 가로 스크롤 영역 오른쪽에 페이드(스크롤 힌트) 적용 — "더 있음" 시각적 안내
  static const double _kScrollFadeWidth = 32;

  Widget _horizontalScrollWithFadeHint({required double height, required Widget child}) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          child,
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: _kScrollFadeWidth,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [bg.withValues(alpha: 0), bg],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEmotionTheme(EmotionTheme theme, StorageService storage) {
    if (theme.refs == null || theme.refs!.isEmpty) return;
    final ref = theme.refs!.first;
    final book = ref.book; // API 형식: "2 corinthians", "psalms" 등
    storage.addRecentChapter(book, ref.chapter, referenceLabel: ref.reference);
    context.push(
      '/reader/${Uri.encodeComponent(book)}/${ref.chapter}?ref=${Uri.encodeComponent(ref.reference ?? '')}&verse=${ref.verse ?? 1}',
    );
  }

  Widget _buildSectionTitle(String title, List<Map<String, dynamic>> list, bool isOt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (list.isNotEmpty)
            TextButton(
              onPressed: () => context.push('/books'),
              child: const Text('모두 보기'),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationStrip(List<Map<String, dynamic>> refs, bool isOt) {
    if (refs.isEmpty) return const SizedBox.shrink();

    return _horizontalScrollWithFadeHint(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 48),
        itemCount: refs.length,
        itemBuilder: (context, i) {
          final r = refs[i];
          final book = r['book'] as String? ?? '';
          final chapter = r['chapter'] as int? ?? 1;
          final reference = r['reference'] as String? ?? '$book $chapter';
          final referenceKo = r['referenceKo'] as String? ?? reference;
          final highlight = r['highlight'] as String? ?? '';
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 144,
              child: AppCard(
                onTap: () {
                  context.read<StorageService>().addRecentChapter(book, chapter, referenceLabel: referenceKo);
                  context.push('/reader/${Uri.encodeComponent(book)}/$chapter?ref=${Uri.encodeComponent(referenceKo)}');
                },
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(referenceKo, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        highlight,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentChapters(StorageService storage) {
    final recent = storage.recentChapters;
    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text('최근 읽은 장', style: Theme.of(context).textTheme.titleMedium),
        ),
        _horizontalScrollWithFadeHint(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 48),
            itemCount: recent.length,
            itemBuilder: (context, i) {
              final r = recent[i];
              final ref = r.referenceLabel ?? '${r.book} ${r.chapter}';
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 144,
                  child: AppCard(
                    onTap: () => context.push('/reader/${Uri.encodeComponent(r.book)}/${r.chapter}?ref=${Uri.encodeComponent(ref)}'),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(ref, style: Theme.of(context).textTheme.titleSmall),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Stitch: 오늘의 한 줄 기도 — 왼쪽 primary 보더, 인용 아이콘, 공유 버튼
  Widget _buildPrayerCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('오늘의 한 줄 기도', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.point.withOpacity(0.1),
              borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
              border: Border(left: BorderSide(color: AppColors.point, width: 4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote, color: AppColors.point, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_prayer != null)
                        Text(_prayer!, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, fontStyle: FontStyle.italic))
                      else
                        Text('로딩 중...', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.share, size: 16, color: AppColors.point),
                        label: Text('기도문 공유', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.point)),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
