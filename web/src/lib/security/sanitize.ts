/**
 * 입력값 살균 (Sanitization)
 * XSS, Injection 방지를 위한 유틸리티
 */

/** HTML 특수문자 이스케이프 */
export function escapeHtml(str: string): string {
  const map: Record<string, string> = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#x27;",
    "/": "&#x2F;",
  };
  return str.replace(/[&<>"'/]/g, (char) => map[char]);
}

/** 검색 쿼리 살균 — 허용: 한글, 영문, 숫자, 공백, 기본 구두점 */
export function sanitizeSearchQuery(query: string): string {
  return query
    .trim()
    .slice(0, 200) // 최대 200자
    .replace(/[^\w\sㄱ-ㅎ가-힣ㅏ-ㅣ0-9.,;:!?'"()-]/g, "");
}

/** 성경 참조 파라미터 검증 — book: 영문(숫자 포함)·한글·공백/언더스코어, chapter: 숫자만 */
export function validateBibleRef(book: string, chapter: string): { valid: boolean; book: string; chapter: number } {
  const cleanBook = book.trim().replace(/[^a-zA-Z0-9ㄱ-ㅎ가-힣ㅏ-ㅣ\s_]/g, "").slice(0, 50);
  const chapterNum = parseInt(chapter, 10);

  if (!cleanBook || isNaN(chapterNum) || chapterNum < 1 || chapterNum > 150) {
    return { valid: false, book: "", chapter: 0 };
  }

  return { valid: true, book: cleanBook, chapter: chapterNum };
}

/** 일반 문자열 살균 — 제어문자 제거 */
export function sanitizeString(str: string, maxLength = 500): string {
  return str
    .trim()
    .slice(0, maxLength)
    .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, "");
}
