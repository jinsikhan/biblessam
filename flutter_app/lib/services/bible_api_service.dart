import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/config.dart';
import '../models/bible_book.dart';
import '../models/chapter_content.dart';
import '../models/daily_chapter.dart';
import '../models/emotion_theme.dart';

class BibleApiService {
  BibleApiService({String? baseUrl}) : baseUrl = baseUrl ?? kApiBaseUrl;
  final String baseUrl;

  Future<DailyChapter?> getDaily({String? date}) async {
    final uri = date != null
        ? Uri.parse('$baseUrl$kApiDaily?date=$date')
        : Uri.parse('$baseUrl$kApiDaily');
    try {
      final res = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('요청 시간 초과'),
      );
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (json['success'] != true) return null;
      return DailyChapter.fromJson(json);
    } catch (_) {
      rethrow;
    }
  }

  Future<ChapterContent?> getChapter(String book, int chapter) async {
    final uri = Uri.parse('$baseUrl$kApiBibleChapter?book=$book&chapter=$chapter');
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['success'] != true) return null;
    return ChapterContent.fromJson(json);
  }

  Future<List<BibleBook>> getBooks() async {
    final uri = Uri.parse('$baseUrl$kApiBibleBooks');
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['success'] != true) return [];
    final list = json['books'] as List<dynamic>? ?? [];
    return list.map((e) => BibleBook.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Search by reference query. Returns list of { book, chapter, reference }.
  Future<List<Map<String, dynamic>>> search(String q) async {
    if (q.trim().isEmpty) return [];
    final uri = Uri.parse('$baseUrl$kApiBibleSearch?q=${Uri.encodeComponent(q.trim())}');
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['success'] != true) return [];
    final results = json['results'] as List<dynamic>? ?? [];
    return results
        .map((e) => (e as Map<String, dynamic>).map((k, v) => MapEntry(k, v)))
        .toList();
  }

  /// Get emotion themes list (no refs). Or single theme with refs when themeId provided.
  Future<List<EmotionTheme>> getEmotionThemes({String? themeId}) async {
    final uri = themeId != null
        ? Uri.parse('$baseUrl$kApiRecommendationsEmotion?theme=$themeId')
        : Uri.parse('$baseUrl$kApiRecommendationsEmotion');
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['success'] != true) return [];
    if (themeId != null) {
      final theme = json['theme'] as Map<String, dynamic>?;
      final refs = json['refs'] as List<dynamic>?;
      if (theme == null) return [];
      final t = EmotionTheme(
        id: theme['id'] as String? ?? '',
        labelKo: theme['labelKo'] as String? ?? '',
        labelEn: theme['labelEn'] as String? ?? '',
        refs: refs?.map((e) => EmotionRef.fromJson(e as Map<String, dynamic>)).toList(),
      );
      return [t];
    }
    final list = json['themes'] as List<dynamic>? ?? [];
    return list.map((e) => EmotionTheme.fromJson(e as Map<String, dynamic>)).toList();
  }
}
