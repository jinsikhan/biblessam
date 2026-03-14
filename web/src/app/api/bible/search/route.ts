import { NextRequest } from "next/server";
import { sanitizeSearchQuery } from "@/lib/security/sanitize";
import { checkRateLimit, getClientIp, BIBLE_RATE_LIMIT } from "@/lib/security/rate-limit";
import { getCorsHeaders } from "@/lib/security/cors";
import { parseReference } from "@/lib/bible-api";
import { getBookByNameEn } from "@/lib/book-names";

export async function GET(request: NextRequest) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);

  const ip = getClientIp(request);
  const { allowed } = checkRateLimit(ip, BIBLE_RATE_LIMIT);
  if (!allowed) {
    return Response.json({ success: false, error: "Too many requests" }, { status: 429, headers });
  }

  const q = request.nextUrl.searchParams.get("q");
  const sanitized = sanitizeSearchQuery(q ?? "");
  if (!sanitized) {
    return Response.json({ success: true, results: [] }, { headers });
  }

  const ref = parseReference(sanitized);
  if (!ref) {
    return Response.json({ success: true, results: [] }, { headers });
  }

  const bookInfo = getBookByNameEn(ref.book);
  const reference = `${ref.book} ${ref.chapter}`;
  const referenceKo = bookInfo?.nameKo ? `${bookInfo.nameKo} ${ref.chapter}장` : reference;

  return Response.json(
    {
      success: true,
      results: [{ book: ref.book, chapter: ref.chapter, reference, referenceKo }],
    },
    { headers }
  );
}
