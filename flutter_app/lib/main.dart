import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app/app.dart';

/// 웹 배포 시 config.json에서 API 주소 로드 (배포 시점에 주입됨)
Future<String?> _loadWebConfig() async {
  try {
    final uri = Uri.base.resolve('config.json');
    final res = await http.get(uri).timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>?;
    return json?['apiBaseUrl'] as String?;
  } catch (_) {
    return null;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? apiBaseUrl;
  if (kIsWeb) {
    apiBaseUrl = await _loadWebConfig();
  }
  runApp(App(apiBaseUrl: apiBaseUrl));
}
