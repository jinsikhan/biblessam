import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../services/storage_service.dart';
import '../../services/ai_api_service.dart';
import '../../widgets/skeleton.dart';

class AiExplanationPanel extends StatefulWidget {
  final String book;
  final int chapter;

  const AiExplanationPanel({super.key, required this.book, required this.chapter});

  @override
  State<AiExplanationPanel> createState() => _AiExplanationPanelState();
}

class _AiExplanationPanelState extends State<AiExplanationPanel> {
  String? _explanation;
  String? _application;
  bool _loading = false;
  String? _error;
  /// JSON 파싱 실패 후 마크다운으로 온 경우 — 카드 대신 모달로만 표시
  bool _isMarkdownFallback = false;

  @override
  void initState() {
    super.initState();
    _loadFromCacheOrFetch();
  }

  void _loadFromCacheOrFetch() {
    final storage = context.read<StorageService>();
    final cached = storage.getAiExplanation(widget.book, widget.chapter, 'ko');
    if (cached != null) {
      try {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        setState(() {
          _explanation = json['explanation'] as String?;
          _application = json['application'] as String?;
          _isMarkdownFallback = json['_markdownFallback'] == true;
        });
        return;
      } catch (_) {}
    }

    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final ai = context.read<AiApiService>();
    final storage = context.read<StorageService>();
    String? serverError;
    final result = await ai.getExplanation(
      widget.book,
      widget.chapter,
      lang: 'ko',
      onServerError: (msg) => serverError = msg,
    );
    if (!mounted) return;
    if (result != null) {
      setState(() {
        _explanation = result.explanation;
        _application = result.application;
        _isMarkdownFallback = result.isMarkdownFallback;
        _loading = false;
        _error = null;
      });
      await storage.setAiExplanation(
        widget.book,
        widget.chapter,
        jsonEncode({
          'explanation': result.explanation,
          'application': result.application,
          if (result.isMarkdownFallback) '_markdownFallback': true,
        }),
        'ko',
      );
    } else {
      setState(() {
        _loading = false;
        _error = serverError ?? '설명을 불러올 수 없어요';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AiExplanationSkeleton();
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() => _error = null);
                _fetch();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('재시도'),
            ),
          ],
        ),
      );
    }

    if (_explanation == null && _application == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.explanationCardBgDark : AppColors.explanationCardBgLight;

    if (_isMarkdownFallback) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '설명이 마크다운 형식으로 왔어요. 아래 버튼으로 보세요.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 12),
            Center(
              child: FilledButton.icon(
                onPressed: () => _openExplanationModal(context, theme, cardBg),
                icon: const Icon(Icons.article_outlined, size: 20),
                label: const Text('설명 보기'),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_explanation != null && _explanation!.isNotEmpty)
            MarkdownBody(
              data: _explanation!,
              styleSheet: MarkdownStyleSheet(
                textAlign: WrapAlignment.start,
                p: theme.textTheme.bodyLarge?.copyWith(height: 1.6) ?? const TextStyle(height: 1.6),
                h1: theme.textTheme.titleLarge,
                h2: theme.textTheme.titleMedium,
                h3: theme.textTheme.titleSmall,
                listBullet: theme.textTheme.bodyLarge,
                blockquote: theme.textTheme.bodyLarge?.copyWith(color: AppColors.point),
              ),
              selectable: true,
            ),
          if (_application != null && _application!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '오늘 이렇게 적용해 보세요:',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.point,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            MarkdownBody(
              data: _application!,
              styleSheet: MarkdownStyleSheet(
                p: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.point,
                ),
              ),
              selectable: true,
            ),
          ],
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => _openExplanationModal(context, theme, cardBg),
              icon: const Icon(Icons.open_in_full, size: 18),
              label: const Text('전체 보기'),
            ),
          ),
        ],
      ),
    );
  }

  void _openExplanationModal(BuildContext context, ThemeData theme, Color cardBg) {
    if (_explanation == null && _application == null) return;
    final buffer = StringBuffer();
    if (_explanation != null && _explanation!.isNotEmpty) buffer.writeln(_explanation);
    if (_application != null && _application!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('**오늘 이렇게 적용해 보세요:**');
      buffer.writeln();
      buffer.writeln(_application);
    }
    final fullMarkdown = buffer.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text('AI 쉬운 설명', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Markdown(
                data: fullMarkdown,
                selectable: true,
                padding: const EdgeInsets.all(20),
                styleSheet: MarkdownStyleSheet(
                  p: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                  h1: theme.textTheme.titleLarge,
                  h2: theme.textTheme.titleMedium,
                  h3: theme.textTheme.titleSmall,
                  listBullet: theme.textTheme.bodyLarge,
                  blockquote: theme.textTheme.bodyLarge?.copyWith(color: AppColors.point),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
