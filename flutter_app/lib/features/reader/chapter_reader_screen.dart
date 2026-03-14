import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../app/config.dart';
import '../../app/theme.dart';
import '../../models/chapter_content.dart';
import '../../models/favorite.dart';
import '../../services/storage_service.dart';
import '../../services/bible_api_service.dart';
import '../../services/ai_api_service.dart';
import 'ai_explanation.dart';
import 'reader_action_bar.dart';

class ChapterReaderScreen extends StatefulWidget {
  final String book;
  final int chapter;
  final String? referenceLabel;
  final int? verseHighlight;

  const ChapterReaderScreen({
    super.key,
    required this.book,
    required this.chapter,
    this.referenceLabel,
    this.verseHighlight,
  });

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen>
    with WidgetsBindingObserver {
  ChapterContent? _content;
  String? _error;
  bool _loading = true;
  Timer? _streakTimer;
  int _elapsedSeconds = 0;
  bool _explanationExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadChapter();
    _startStreakTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _streakTimer?.cancel();
    _saveStreakIfNeeded();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _streakTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _startStreakTimer();
    }
  }

  void _startStreakTimer() {
    _streakTimer?.cancel();
    _streakTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  void _saveStreakIfNeeded() {
    if (_elapsedSeconds >= kStreakTargetMinutes * 60) {
      final minutes = _elapsedSeconds ~/ 60;
      context.read<StorageService>().recordReadingMinutes(minutes);
    }
  }

  Future<void> _loadChapter() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final bible = context.read<BibleApiService>();
    final content = await bible.getChapter(widget.book, widget.chapter);
    if (!mounted) return;
    setState(() {
      _content = content;
      _error = content == null ? '본문을 불러올 수 없어요' : null;
      _loading = false;
    });
    if (content != null) {
      context.read<StorageService>().addRecentChapter(
            widget.book,
            widget.chapter,
            referenceLabel: widget.referenceLabel ?? content.displayReference,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final isFavorite = storage.isFavorite(widget.book, widget.chapter);
    final title = widget.referenceLabel ?? _content?.displayReference ?? '${widget.book} ${widget.chapter}';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? const Color(AppColors.heart) : null,
            ),
            onPressed: () => _toggleFavorite(storage),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.point),
                  const SizedBox(height: 16),
                  Text(
                    '본문을 불러오는 중...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loadChapter,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                )
              : _content == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            itemCount: _content!.verses.length + 1,
                            itemBuilder: (context, i) {
                              if (i == _content!.verses.length) {
                                return _buildActionAndExplanation();
                              }
                              final v = _content!.verses[i];
                              final highlight =
                                  widget.verseHighlight != null && v.verse == widget.verseHighlight;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '${v.verse}',
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.point,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        v.text,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              height: 2.0,
                                              letterSpacing: 0.2,
                                              backgroundColor: highlight
                                                  ? AppColors.point.withOpacity(0.15)
                                                  : null,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildActionAndExplanation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReaderActionBar(
          isFavorite: context.watch<StorageService>().isFavorite(widget.book, widget.chapter),
          onFavorite: () => _toggleFavorite(context.read<StorageService>()),
          onExplanation: () => setState(() => _explanationExpanded = !_explanationExpanded),
          onShare: () {},
          explanationExpanded: _explanationExpanded,
        ),
        if (_explanationExpanded)
          AiExplanationPanel(
            book: widget.book,
            chapter: widget.chapter,
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _toggleFavorite(StorageService storage) {
    if (storage.isFavorite(widget.book, widget.chapter)) {
      storage.removeFavoriteByBookChapter(widget.book, widget.chapter);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('즐겨찾기에서 제거했어요'),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      final id = '${widget.book}_${widget.chapter}_${DateTime.now().millisecondsSinceEpoch}';
      final label = widget.referenceLabel ?? _content?.displayReference;
      storage.addFavorite(Favorite(
        id: id,
        book: widget.book,
        chapter: widget.chapter,
        verseText: null,
        referenceLabel: label,
        createdAt: DateTime.now().toIso8601String(),
      ));
    }
  }
}
