/**
 * 오늘의 말씀 — 날짜(YYYY-MM-DD)를 시드로 성경 1,189장 중 하나를 결정적으로 선택
 * 같은 날 모든 사용자에게 동일한 장 반환
 */

/** 성경 책별 장 수 (구약 39 + 신약 27, 순서 고정) */
const CHAPTER_COUNTS = [
  50, 40, 27, 36, 34, 24, 21, 4, 31, 24, 22, 25, 29, 36, 10, 13, 10, 42, 150, 31, 12, 8, 66, 52, 5, 48, 12, 14, 3, 9, 1, 4, 7, 3, 3, 3, 2, 14, 4, 28, 16, 24, 21, 28, 16, 16, 13, 6, 6, 4, 4, 5, 3, 6, 4, 3, 1, 13, 5, 5, 3, 5, 1, 1, 1, 22,
];

/** bible-api.com용 영문 책명 (순서: 창세기~요한계시록) */
const BOOK_NAMES_EN: string[] = [
  "genesis", "exodus", "leviticus", "numbers", "deuteronomy", "joshua", "judges", "ruth", "1 samuel", "2 samuel", "1 kings", "2 kings", "1 chronicles", "2 chronicles", "ezra", "nehemiah", "esther", "job", "psalms", "proverbs", "ecclesiastes", "song of solomon", "isaiah", "jeremiah", "lamentations", "ezekiel", "daniel", "hosea", "joel", "amos", "obadiah", "jonah", "micah", "nahum", "habakkuk", "zephaniah", "haggai", "zechariah", "malachi",
  "matthew", "mark", "luke", "john", "acts", "romans", "1 corinthians", "2 corinthians", "galatians", "ephesians", "philippians", "colossians", "1 thessalonians", "2 thessalonians", "1 timothy", "2 timothy", "titus", "philemon", "hebrews", "james", "1 peter", "2 peter", "1 john", "2 john", "3 john", "jude", "revelation",
];

const TOTAL_CHAPTERS = CHAPTER_COUNTS.reduce((a, b) => a + b, 0); // 1189

export interface DailyChapterResult {
  book: string;
  chapter: number;
  bookIndex: number;
  chapterIndex: number;
}

/**
 * 날짜 문자열(YYYY-MM-DD)을 시드로 0..1188 범위의 결정적 인덱스 반환
 */
function dateToSeedIndex(dateStr: string): number {
  const s = dateStr.replace(/-/g, "");
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (h * 31 + s.charCodeAt(i)) >>> 0;
  }
  return h % TOTAL_CHAPTERS;
}

/**
 * 오늘의 말씀 장 선택 (같은 날짜면 항상 동일)
 * @param dateStr - YYYY-MM-DD (기본: 오늘 날짜)
 */
export function getDailyChapter(dateStr?: string): DailyChapterResult {
  const date = dateStr || new Date().toISOString().slice(0, 10);
  const index = dateToSeedIndex(date);

  let acc = 0;
  for (let bookIndex = 0; bookIndex < CHAPTER_COUNTS.length; bookIndex++) {
    const count = CHAPTER_COUNTS[bookIndex];
    if (index < acc + count) {
      const chapter = index - acc + 1;
      return {
        book: BOOK_NAMES_EN[bookIndex],
        chapter,
        bookIndex,
        chapterIndex: index,
      };
    }
    acc += count;
  }
  const lastBook = CHAPTER_COUNTS.length - 1;
  return {
    book: BOOK_NAMES_EN[lastBook],
    chapter: CHAPTER_COUNTS[lastBook],
    bookIndex: lastBook,
    chapterIndex: TOTAL_CHAPTERS - 1,
  };
}
