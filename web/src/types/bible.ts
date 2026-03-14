/**
 * Bible data types for BibleSsam (바이블쌤)
 * Used by API routes and lib for bible-books.json, emotion-themes.json, chapter content.
 */

/** 성경 책 (66권) */
export interface BibleBook {
  id: string;
  nameKo: string;
  nameEn: string;
  abbreviation?: string;
  testament: "old" | "new" | string;
  chapters: number;
}

/** 장 본문 (API 응답 등) */
export interface ChapterContent {
  book: string;
  chapter: number;
  translation: string;
  verses: Verse[];
}

/** 절 */
export interface Verse {
  number: number;
  text: string;
}

/** 감정/상황 테마 */
export interface EmotionTheme {
  theme: string;
  nameKo: string;
  verses: EmotionVerse[];
}

/** 감정 테마별 대표 구절 */
export interface EmotionVerse {
  book: string;
  chapter: number;
  verse: number;
  text: string;
}

/** 책 참조 (검색/API 파라미터) */
export interface BibleReference {
  bookId: string;
  chapter: number;
  verse?: number;
}
