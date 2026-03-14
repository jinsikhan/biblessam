class Favorite {
  final String id;
  final String book;
  final int chapter;
  final String? verseText;
  final String? referenceLabel;
  final String createdAt;

  const Favorite({
    required this.id,
    required this.book,
    required this.chapter,
    this.verseText,
    this.referenceLabel,
    required this.createdAt,
  });

  String get reference => referenceLabel ?? '$book $chapter';

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] as String? ?? '',
      book: json['book'] as String? ?? '',
      chapter: (json['chapter'] as num?)?.toInt() ?? 0,
      verseText: json['verseText'] as String?,
      referenceLabel: json['referenceLabel'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'book': book,
        'chapter': chapter,
        'verseText': verseText,
        'referenceLabel': referenceLabel,
        'createdAt': createdAt,
      };
}
