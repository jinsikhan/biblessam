import { NextRequest } from "next/server";
import { validateBibleRef } from "@/lib/security/sanitize";
import { checkRateLimit, getClientIp, BIBLE_RATE_LIMIT } from "@/lib/security/rate-limit";
import { getCorsHeaders } from "@/lib/security/cors";
import { fetchChapter } from "@/lib/bible-api";
import { getBookByNameEn } from "@/lib/book-names";

export async function GET(request: NextRequest) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);

  const ip = getClientIp(request);
  const { allowed } = checkRateLimit(ip, BIBLE_RATE_LIMIT);
  if (!allowed) {
    return Response.json({ success: false, error: "Too many requests" }, { status: 429, headers });
  }

  const book = request.nextUrl.searchParams.get("book");
  const chapter = request.nextUrl.searchParams.get("chapter");
  const { valid, book: safeBook, chapter: safeChapter } = validateBibleRef(book ?? "", chapter ?? "");
  if (!valid) {
    return Response.json({ success: false, error: "Invalid book or chapter" }, { status: 400, headers });
  }

  const data = await fetchChapter(safeBook, safeChapter);
  if (!data) {
    return Response.json({ success: false, error: "Chapter not found" }, { status: 404, headers });
  }

  const bookInfo = getBookByNameEn(safeBook);
  const referenceKo = bookInfo?.nameKo ? `${bookInfo.nameKo} ${safeChapter}장` : data.reference;

  return Response.json(
    { success: true, ...data, verses: data.verses, referenceKo },
    { headers }
  );
}
