class BibleVerse {
  final int verse;
  final String text;

  const BibleVerse({required this.verse, required this.text});

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      verse: (json['verse'] as num?)?.toInt() ?? 0,
      text: json['text'] as String? ?? '',
    );
  }
}

class ChapterContent {
  final String reference;
  final String? referenceKo;
  final String book;
  final int chapter;
  final List<BibleVerse> verses;
  final String text;

  const ChapterContent({
    required this.reference,
    this.referenceKo,
    required this.book,
    required this.chapter,
    required this.verses,
    required this.text,
  });

  /// 한글 제목 (예: 요한복음 3장). 없으면 reference 사용.
  String get displayReference => referenceKo ?? reference;

  factory ChapterContent.fromJson(Map<String, dynamic> json) {
    final versesList = json['verses'] as List<dynamic>?;
    final verses = versesList
            ?.map((e) => BibleVerse.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return ChapterContent(
      reference: json['reference'] as String? ?? '',
      referenceKo: json['referenceKo'] as String?,
      book: json['book'] as String? ?? '',
      chapter: (json['chapter'] as num?)?.toInt() ?? 0,
      verses: verses,
      text: json['text'] as String? ?? '',
    );
  }
}
