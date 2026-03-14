class EmotionRef {
  final String book;
  final int chapter;
  final int? verse;
  final String highlight;
  final String? reference;
  final String? referenceKo;

  const EmotionRef({
    required this.book,
    required this.chapter,
    this.verse,
    required this.highlight,
    this.reference,
    this.referenceKo,
  });

  String get displayReference => referenceKo ?? reference ?? '$book $chapter';

  factory EmotionRef.fromJson(Map<String, dynamic> json) {
    return EmotionRef(
      book: json['book'] as String? ?? '',
      chapter: (json['chapter'] as num?)?.toInt() ?? 0,
      verse: (json['verse'] as num?)?.toInt(),
      highlight: json['highlight'] as String? ?? '',
      reference: json['reference'] as String?,
      referenceKo: json['referenceKo'] as String?,
    );
  }
}

class EmotionTheme {
  final String id;
  final String labelKo;
  final String labelEn;
  final List<EmotionRef>? refs;

  const EmotionTheme({
    required this.id,
    required this.labelKo,
    required this.labelEn,
    this.refs,
  });

  factory EmotionTheme.fromJson(Map<String, dynamic> json) {
    final refsList = json['refs'] as List<dynamic>?;
    return EmotionTheme(
      id: json['id'] as String? ?? '',
      labelKo: json['labelKo'] as String? ?? '',
      labelEn: json['labelEn'] as String? ?? '',
      refs: refsList
          ?.map((e) => EmotionRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
