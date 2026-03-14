class DailyChapter {
  final String book;
  final int chapter;
  final String reference;
  /// 한글 표기 (예: 사도행전 25장). API에서 오지 않으면 reference 사용
  final String? referenceKo;

  const DailyChapter({
    required this.book,
    required this.chapter,
    required this.reference,
    this.referenceKo,
  });

  String get displayReference => referenceKo ?? reference;

  factory DailyChapter.fromJson(Map<String, dynamic> json) {
    return DailyChapter(
      book: json['book'] as String? ?? '',
      chapter: (json['chapter'] as num?)?.toInt() ?? 0,
      reference: json['reference'] as String? ?? '',
      referenceKo: json['referenceKo'] as String?,
    );
  }
}
