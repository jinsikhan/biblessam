import { NextRequest } from "next/server";
import { getCorsHeaders } from "@/lib/security/cors";
import { getDailyChapter } from "@/lib/daily-chapter";
import { getBookByNameEn } from "@/lib/book-names";

export async function GET(request: NextRequest) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);

  const dateParam = request.nextUrl.searchParams.get("date");
  const dateStr = dateParam && /^\d{4}-\d{2}-\d{2}$/.test(dateParam) ? dateParam : undefined;
  const daily = getDailyChapter(dateStr);

  const bookInfo = getBookByNameEn(daily.book);
  const referenceKo = bookInfo ? `${bookInfo.nameKo} ${daily.chapter}장` : `${daily.book} ${daily.chapter}`;

  return Response.json(
    {
      success: true,
      book: daily.book,
      chapter: daily.chapter,
      reference: `${daily.book} ${daily.chapter}`,
      referenceKo,
    },
    { headers }
  );
}
