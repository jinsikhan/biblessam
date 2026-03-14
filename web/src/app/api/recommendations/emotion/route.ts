import { NextRequest } from "next/server";
import { sanitizeString } from "@/lib/security/sanitize";
import { getCorsHeaders } from "@/lib/security/cors";
import { getEmotionThemes } from "@/lib/static-data";
import { getBookById } from "@/lib/book-names";

type ThemeRef = { book: string; chapter: number; verse?: number; highlight: string };
type Theme = { id: string; labelKo: string; labelEn: string; refs: ThemeRef[] };

function getThemes(): Theme[] {
  return getEmotionThemes() as Theme[];
}

function bookIdToApiName(id: string): string {
  return id.replace(/_/g, " ").toLowerCase();
}

function toReferenceKo(bookId: string, chapter: number, verse?: number): string {
  const book = getBookById(bookId);
  if (!book) return `${bookId} ${chapter}${verse ? `:${verse}` : ""}`;
  return `${book.nameKo} ${chapter}장${verse ? `:${verse}` : ""}`;
}

export async function GET(request: NextRequest) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);

  const themes = getThemes();
  const themeId = sanitizeString(request.nextUrl.searchParams.get("theme") ?? "", 50);
  if (themeId) {
    const theme = themes.find((t) => t.id === themeId);
    if (!theme) {
      return Response.json({ success: false, error: "Theme not found" }, { status: 404, headers });
    }
    const refs = theme.refs.map((r) => ({
      book: bookIdToApiName(r.book),
      chapter: r.chapter,
      verse: r.verse,
      highlight: r.highlight,
      reference: `${bookIdToApiName(r.book)} ${r.chapter}${r.verse ? `:${r.verse}` : ""}`,
      referenceKo: toReferenceKo(r.book, r.chapter, r.verse),
    }));
    return Response.json({ success: true, theme: { id: theme.id, labelKo: theme.labelKo, labelEn: theme.labelEn }, refs }, { headers });
  }

  // 목록 조회 시 refs 포함 (홈 구약/신약 추천용)
  const list = themes.map((t) => ({
    id: t.id,
    labelKo: t.labelKo,
    labelEn: t.labelEn,
    refs: t.refs.map((r) => ({
      book: bookIdToApiName(r.book),
      chapter: r.chapter,
      verse: r.verse,
      highlight: r.highlight,
      reference: `${bookIdToApiName(r.book)} ${r.chapter}${r.verse ? `:${r.verse}` : ""}`,
      referenceKo: toReferenceKo(r.book, r.chapter, r.verse),
    })),
  }));
  return Response.json({ success: true, themes: list }, { headers });
}
