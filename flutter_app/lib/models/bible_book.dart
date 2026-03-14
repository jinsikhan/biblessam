class BibleBook {
  final String id;
  final String nameEn;
  final String nameKo;
  final int chapters;
  final String testament; // OT | NT

  const BibleBook({
    required this.id,
    required this.nameEn,
    required this.nameKo,
    required this.chapters,
    required this.testament,
  });

  factory BibleBook.fromJson(Map<String, dynamic> json) {
    return BibleBook(
      id: json['id'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      nameKo: json['nameKo'] as String? ?? '',
      chapters: (json['chapters'] as num?)?.toInt() ?? 0,
      testament: json['testament'] as String? ?? 'OT',
    );
  }

  /// API param: book name for bible-api (e.g. "1 samuel", "john")
  String get apiBookName => id.replaceAll('_', ' ').toLowerCase();
}
