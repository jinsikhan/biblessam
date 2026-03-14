import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/config.dart';
import '../models/favorite.dart';
import '../models/streak.dart';

class RecentChapter {
  final String book;
  final int chapter;
  final String? referenceLabel;
  final String readAt;

  RecentChapter({
    required this.book,
    required this.chapter,
    this.referenceLabel,
    required this.readAt,
  });

  Map<String, dynamic> toJson() => {
        'book': book,
        'chapter': chapter,
        'referenceLabel': referenceLabel,
        'readAt': readAt,
      };

  static RecentChapter fromJson(Map<String, dynamic> json) {
    return RecentChapter(
      book: json['book'] as String? ?? '',
      chapter: (json['chapter'] as num?)?.toInt() ?? 0,
      referenceLabel: json['referenceLabel'] as String?,
      readAt: json['readAt'] as String? ?? '',
    );
  }
}

class StorageService extends ChangeNotifier {
  static const _keyTheme = 'theme_mode';
  static const _keyFavorites = 'favorites';
  static const _keyRecent = 'recent_chapters';
  static const _keyStreak = 'streak';
  static const _keyStreakDates = 'streak_dates';
  static const _keyMinutesToday = 'minutes_today';
  static const _keyLastDate = 'streak_last_date';
  static const _keyAiExplanation = 'ai_explanation_';

  ThemeMode _themeMode = ThemeMode.light;
  List<Favorite> _favorites = [];
  List<RecentChapter> _recentChapters = [];
  StreakData _streak = const StreakData();
  final Map<String, String> _aiExplanationCache = {};

  ThemeMode get themeMode => _themeMode;
  List<Favorite> get favorites => List.unmodifiable(_favorites);
  List<RecentChapter> get recentChapters => List.unmodifiable(_recentChapters);
  StreakData get streak => _streak;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyTheme);
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex.clamp(0, 2)];
    }
    final favJson = prefs.getString(_keyFavorites);
    if (favJson != null) {
      try {
        final list = jsonDecode(favJson) as List<dynamic>;
        _favorites = list
            .map((e) => Favorite.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    final recentJson = prefs.getString(_keyRecent);
    if (recentJson != null) {
      try {
        final list = jsonDecode(recentJson) as List<dynamic>;
        _recentChapters = list
            .map((e) => RecentChapter.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    final streakDatesJson = prefs.getString(_keyStreakDates);
    final minutesToday = prefs.getInt(_keyMinutesToday) ?? 0;
    final lastDate = prefs.getString(_keyLastDate);
    final dates = streakDatesJson != null
        ? (jsonDecode(streakDatesJson) as List<dynamic>).map((e) => e.toString()).toList()
        : <String>[];
    _streak = StreakData(
      currentStreak: _computeCurrentStreak(dates, lastDate),
      totalMinutesToday: minutesToday,
      lastDate: lastDate,
      dates: dates,
    );
    // Load AI cache keys that start with prefix
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyAiExplanation));
    for (final k in keys) {
      final v = prefs.getString(k);
      if (v != null) _aiExplanationCache[k] = v;
    }
    notifyListeners();
  }

  int _computeCurrentStreak(List<String> dates, String? lastDate) {
    if (dates.isEmpty) return 0;
    final sorted = dates.toList()..sort();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (lastDate != today) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
      if (lastDate != yesterday) return 0;
    }
    int streak = 0;
    DateTime d = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final ds = d.toIso8601String().substring(0, 10);
      if (sorted.contains(ds)) {
        streak++;
        d = d.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTheme, mode.index);
    notifyListeners();
  }

  String _favKey(Favorite f) => '${f.book}|${f.chapter}';

  Future<void> addFavorite(Favorite f) async {
    if (_favorites.any((x) => _favKey(x) == _favKey(f))) return;
    _favorites.insert(0, f);
    await _persistFavorites();
    notifyListeners();
  }

  Future<void> removeFavorite(String id) async {
    _favorites.removeWhere((x) => x.id == id);
    await _persistFavorites();
    notifyListeners();
  }

  Future<void> removeFavoriteByBookChapter(String book, int chapter) async {
    _favorites.removeWhere((x) => x.book == book && x.chapter == chapter);
    await _persistFavorites();
    notifyListeners();
  }

  bool isFavorite(String book, int chapter) {
    return _favorites.any((x) => x.book == book && x.chapter == chapter);
  }

  Future<void> _persistFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFavorites,
      jsonEncode(_favorites.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addRecentChapter(String book, int chapter, {String? referenceLabel}) async {
    final item = RecentChapter(
      book: book,
      chapter: chapter,
      referenceLabel: referenceLabel,
      readAt: DateTime.now().toIso8601String(),
    );
    _recentChapters.removeWhere((x) => x.book == book && x.chapter == chapter);
    _recentChapters.insert(0, item);
    if (_recentChapters.length > kMaxRecentChapters) {
      _recentChapters = _recentChapters.take(kMaxRecentChapters).toList();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyRecent,
      jsonEncode(_recentChapters.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  void recordReadingMinutes(int minutes) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final dates = _streak.dates.toList();
    if (!dates.contains(today)) dates.add(today);
    dates.sort();
    final minutesToday = _streak.lastDate == today
        ? _streak.totalMinutesToday + minutes
        : minutes;
    _streak = StreakData(
      currentStreak: _computeCurrentStreak(dates, today),
      totalMinutesToday: minutesToday,
      lastDate: today,
      dates: dates,
    );
    _persistStreak(dates, minutesToday, today);
    notifyListeners();
  }

  Future<void> _persistStreak(List<String> dates, int minutesToday, String lastDate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStreakDates, jsonEncode(dates));
    await prefs.setInt(_keyMinutesToday, minutesToday);
    await prefs.setString(_keyLastDate, lastDate);
  }

  String? getAiExplanation(String book, int chapter, [String lang = 'ko']) {
    return _aiExplanationCache[_keyAiExplanation + '$book|$chapter|$lang'];
  }

  Future<void> setAiExplanation(String book, int chapter, String json, [String lang = 'ko']) async {
    final key = _keyAiExplanation + '$book|$chapter|$lang';
    _aiExplanationCache[key] = json;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json);
    notifyListeners();
  }
}
