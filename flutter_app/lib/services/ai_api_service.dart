import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/config.dart';

class AiExplanationResult {
  final String explanation;
  final List<String> summary;
  final String application;
  /// JSON 파싱 실패 후 서버가 마크다운 원문으로 반환한 경우 true — 모달로만 표시
  final bool isMarkdownFallback;

  AiExplanationResult({
    required this.explanation,
    this.summary = const [],
    required this.application,
    this.isMarkdownFallback = false,
  });

  factory AiExplanationResult.fromJson(Map<String, dynamic> json) {
    return AiExplanationResult(
      explanation: json['explanation'] as String? ?? '',
      summary: (json['summary'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList() ??
          const [],
      application: json['application'] as String? ?? '',
      isMarkdownFallback: json['_markdownFallback'] == true,
    );
  }
}

class AiApiService {
  AiApiService({String? baseUrl}) : baseUrl = baseUrl ?? kApiBaseUrl;
  final String baseUrl;
  static String _normalizeBaseUrl(String url) {
    final u = url.trim();
    if (u.startsWith('http:') && !u.startsWith('http://')) return 'http://${u.substring(5)}';
    if (u.startsWith('https:') && !u.startsWith('https://')) return 'https://${u.substring(6)}';
    return u;
  }

  /// 스트리밍으로 설명 요청. [onDelta]로 청크 수신, 완료 시 결과 반환. 실패 시 null 및 [onServerError].
  Future<AiExplanationResult?> getExplanationStream(
    String book,
    int chapter, {
    String lang = 'ko',
    void Function(String chunk)? onDelta,
    void Function(String message)? onServerError,
  }) async {
    final base = _normalizeBaseUrl(baseUrl);
    final uri = Uri.parse(
      '$base$kApiAiExplanationStream?book=${Uri.encodeComponent(book)}&chapter=$chapter&lang=$lang',
    );
    final client = http.Client();
    try {
      final req = http.Request('GET', uri);
      req.headers['Accept'] = 'text/event-stream';
      req.headers['Cache-Control'] = 'no-cache';
      final response = await client.send(req).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('요청 시간이 초과되었어요'),
      );
      if (response.statusCode != 200) {
        onServerError?.call('설명을 불러올 수 없어요 (${response.statusCode})');
        return null;
      }
      AiExplanationResult? result;
      String? errorMsg;
      final buffer = StringBuffer();
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer.write(chunk);
        final text = buffer.toString();
        final parts = text.split('\n\n');
        buffer.clear();
        buffer.write(parts.last);
        for (int i = 0; i < parts.length - 1; i++) {
          final line = parts[i].trim();
          if (!line.startsWith('data: ')) continue;
          final jsonStr = line.substring(6).trim();
          if (jsonStr.isEmpty) continue;
          try {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>?;
            if (json == null) continue;
            if (json['error'] != null) {
              errorMsg = json['error'] as String?;
              continue;
            }
            if (json['delta'] != null) {
              onDelta?.call(json['delta'] as String);
              continue;
            }
            if (json['done'] == true && json['explanation'] != null) {
              result = AiExplanationResult(
                explanation: json['explanation'] as String? ?? '',
                application: json['application'] as String? ?? '',
              );
            }
          } catch (_) {}
        }
      }
      final remaining = buffer.toString();
      if (remaining.isNotEmpty) {
        for (final line in remaining.split('\n')) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('data: ')) continue;
          try {
            final json = jsonDecode(trimmed.substring(6).trim()) as Map<String, dynamic>?;
            if (json?['error'] != null) errorMsg = json!['error'] as String?;
            if (json?['done'] == true && json?['explanation'] != null) {
              result = AiExplanationResult(
                explanation: json!['explanation'] as String? ?? '',
                application: json['application'] as String? ?? '',
              );
            }
          } catch (_) {}
        }
      }
      if (errorMsg != null) {
        onServerError?.call(errorMsg);
        return null;
      }
      return result;
    } catch (e) {
      onServerError?.call(e is Exception ? e.toString().replaceFirst('Exception: ', '') : '네트워크 오류');
      return null;
    } finally {
      client.close();
    }
  }

  /// Returns result or null; [serverError] is set when status is not 200 so UI can show it.
  Future<AiExplanationResult?> getExplanation(
    String book,
    int chapter, {
    String lang = 'ko',
    void Function(String message)? onServerError,
  }) async {
    final base = _normalizeBaseUrl(baseUrl);
    final uri = Uri.parse(
      '$base$kApiAiExplanation?book=${Uri.encodeComponent(book)}&chapter=$chapter&lang=$lang',
    );
    try {
      final res = await http.get(uri).timeout(
        const Duration(seconds: 35),
        onTimeout: () => throw Exception('요청 시간이 초과되었어요'),
      );
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && json['success'] == true) {
        if (json['_fallback'] == true) {
          final msg = json['explanation'] as String? ?? 'AI 설명을 불러오지 못했어요.';
          onServerError?.call(msg);
          return null;
        }
        return AiExplanationResult.fromJson(json);
      }
      final msg = json['error'] as String? ?? '설명을 불러올 수 없어요 (${res.statusCode})';
      onServerError?.call(msg);
      return null;
    } catch (e) {
      onServerError?.call(e is Exception ? e.toString().replaceFirst('Exception: ', '') : '네트워크 오류');
      return null;
    }
  }

  /// Returns prayer text for the given date.
  Future<String?> getPrayer({String? date, String lang = 'ko'}) async {
    final base = _normalizeBaseUrl(baseUrl);
    final q = date != null ? '?date=$date&lang=$lang' : '?lang=$lang';
    final uri = Uri.parse('$base$kApiAiPrayer$q');
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['success'] != true) return null;
    return json['prayer'] as String?;
  }
}
