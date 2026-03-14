/// 서버 /api/daily 실패 시 사용하는 오늘의 말씀 계산 (서버와 동일 알고리즘)
import '../models/daily_chapter.dart';

const _chapterCounts = [
  50, 40, 27, 36, 34, 24, 21, 4, 31, 24, 22, 25, 29, 36, 10, 13, 10, 42, 150, 31, 12, 8, 66, 52, 5, 48, 12, 14, 3, 9, 1, 4, 7, 3, 3, 3, 2, 14, 4, 28, 16, 24, 21, 28, 16, 16, 13, 6, 6, 4, 4, 5, 3, 6, 4, 3, 1, 13, 5, 5, 3, 5, 1, 1, 1, 22,
];

const _bookNamesEn = [
  'genesis', 'exodus', 'leviticus', 'numbers', 'deuteronomy', 'joshua', 'judges', 'ruth', '1 samuel', '2 samuel', '1 kings', '2 kings', '1 chronicles', '2 chronicles', 'ezra', 'nehemiah', 'esther', 'job', 'psalms', 'proverbs', 'ecclesiastes', 'song of solomon', 'isaiah', 'jeremiah', 'lamentations', 'ezekiel', 'daniel', 'hosea', 'joel', 'amos', 'obadiah', 'jonah', 'micah', 'nahum', 'habakkuk', 'zephaniah', 'haggai', 'zechariah', 'malachi',
  'matthew', 'mark', 'luke', 'john', 'acts', 'romans', '1 corinthians', '2 corinthians', 'galatians', 'ephesians', 'philippians', 'colossians', '1 thessalonians', '2 thessalonians', '1 timothy', '2 timothy', 'titus', 'philemon', 'hebrews', 'james', '1 peter', '2 peter', '1 john', '2 john', '3 john', 'jude', 'revelation',
];

const _bookNamesKo = [
  '창세기', '출애굽기', '레위기', '민수기', '신명기', '여호수아', '사사기', '룻기', '사무엘상', '사무엘하', '열왕기상', '열왕기하', '역대상', '역대하', '에스라', '느헤미야', '에스더', '욥기', '시편', '잠언', '전도서', '아가', '이사야', '예레미야', '예레미야애가', '에스겔', '다니엘', '호세아', '요엘', '아모스', '오바댜', '요나', '미가', '나훔', '하박국', '스바냐', '학개', '스가랴', '말라기',
  '마태복음', '마가복음', '누가복음', '요한복음', '사도행전', '로마서', '고린도전서', '고린도후서', '갈라디아서', '에베소서', '빌립보서', '골로새서', '데살로니가전서', '데살로니가후서', '디모데전서', '디모데후서', '디도서', '빌레몬서', '히브리서', '야고보서', '베드로전서', '베드로후서', '요한일서', '요한이서', '요한삼서', '유다서', '요한계시록',
];

const _totalChapters = 1189;

int _dateToSeedIndex(String dateStr) {
  final s = dateStr.replaceAll('-', '');
  int h = 0;
  for (int i = 0; i < s.length; i++) {
    h = ((h * 31 + s.codeUnitAt(i)) & 0xFFFFFFFF);
  }
  return h % _totalChapters;
}

/// 오늘 날짜(또는 주어진 날짜)로 서버와 동일한 오늘의 말씀 1장 반환. API 실패 시 사용.
DailyChapter getDailyChapterFallback({String? date}) {
  final dateStr = date ?? DateTime.now().toIso8601String().substring(0, 10);
  final index = _dateToSeedIndex(dateStr);
  int acc = 0;
  for (int bookIndex = 0; bookIndex < _chapterCounts.length; bookIndex++) {
    final count = _chapterCounts[bookIndex];
    if (index < acc + count) {
      final chapter = index - acc + 1;
      final book = _bookNamesEn[bookIndex];
      final refKo = '${_bookNamesKo[bookIndex]} $chapter장';
      return DailyChapter(
        book: book,
        chapter: chapter,
        reference: '$book $chapter',
        referenceKo: refKo,
      );
    }
    acc += count;
  }
  final last = _chapterCounts.length - 1;
  return DailyChapter(
    book: _bookNamesEn[last],
    chapter: _chapterCounts[last],
    reference: '${_bookNamesEn[last]} ${_chapterCounts[last]}',
    referenceKo: '${_bookNamesKo[last]} ${_chapterCounts[last]}장',
  );
}
