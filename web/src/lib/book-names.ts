/**
 * 한글↔영문 성경 책명 매핑
 * bible-books.json 기반 조회 (D03)
 */

import type { BibleBook } from "@/types";
import bibleBooksJson from "@/data/bible-books.json";

const books = bibleBooksJson as BibleBook[];

/** 책 id로 조회 */
export function getBookById(id: string): BibleBook | undefined {
  return books.find((b) => b.id === id);
}

/** 한글 책명으로 조회 (완전 일치 또는 포함) */
export function getBookByNameKo(nameKo: string): BibleBook | undefined {
  const trimmed = nameKo.trim();
  return (
    books.find((b) => b.nameKo === trimmed) ??
    books.find((b) => b.nameKo.includes(trimmed) || trimmed.includes(b.nameKo))
  );
}

/** 영문 책명/약어로 조회 */
export function getBookByNameEn(nameEn: string): BibleBook | undefined {
  const lower = nameEn.trim().toLowerCase();
  return books.find(
    (b) =>
      b.nameEn?.toLowerCase() === lower ||
      b.abbreviation?.toLowerCase() === lower ||
      b.id?.toLowerCase() === lower
  );
}

/** 전체 책 목록 */
export function getAllBooks(): BibleBook[] {
  return [...books];
}

/** 구약/신약 필터 */
export function getBooksByTestament(testament: "old" | "new"): BibleBook[] {
  return books.filter((b) => b.testament === testament);
}
