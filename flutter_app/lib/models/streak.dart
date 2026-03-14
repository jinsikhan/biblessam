class StreakData {
  final int currentStreak;
  final int totalMinutesToday;
  final String? lastDate;
  final List<String> dates;

  const StreakData({
    this.currentStreak = 0,
    this.totalMinutesToday = 0,
    this.lastDate,
    this.dates = const [],
  });

  factory StreakData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StreakData();
    final datesList = json['dates'] as List<dynamic>?;
    return StreakData(
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      totalMinutesToday: (json['totalMinutesToday'] as num?)?.toInt() ?? 0,
      lastDate: json['lastDate'] as String?,
      dates: datesList?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'totalMinutesToday': totalMinutesToday,
        'lastDate': lastDate,
        'dates': dates,
      };
}
