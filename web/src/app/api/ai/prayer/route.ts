import { NextRequest } from "next/server";
import { checkRateLimit, getClientIp, AI_RATE_LIMIT } from "@/lib/security/rate-limit";
import { getCorsHeaders } from "@/lib/security/cors";
import { getServerEnv } from "@/lib/security/env";
import { getDailyChapter } from "@/lib/daily-chapter";
import { fetchChapter } from "@/lib/bible-api";
import { generatePrayer } from "@/lib/ai-api";
import { aiCache } from "@/lib/ai-cache";

export async function GET(request: NextRequest) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);

  const ip = getClientIp(request);
  const { allowed } = checkRateLimit(ip, AI_RATE_LIMIT);
  if (!allowed) {
    return Response.json({ success: false, error: "Too many requests" }, { status: 429, headers });
  }

  const dateParam = request.nextUrl.searchParams.get("date");
  const dateStr = dateParam && /^\d{4}-\d{2}-\d{2}$/.test(dateParam) ? dateParam : new Date().toISOString().slice(0, 10);
  const lang = (request.nextUrl.searchParams.get("lang") || "ko").slice(0, 2) === "en" ? "en" : "ko";

  const cached = aiCache.getPrayer<{ prayer: string }>(dateStr, lang);
  if (cached) {
    return Response.json({ success: true, ...cached }, { headers });
  }

  const daily = getDailyChapter(dateStr);
  const chapterData = await fetchChapter(daily.book, daily.chapter);
  if (!chapterData?.text) {
    return Response.json({ success: false, error: "Daily chapter not available" }, { status: 502, headers });
  }

  try {
    const getEnv = (key: "GEMINI_API_KEY" | "OPENROUTER_API_KEY" | "GROQ_API_KEY") => getServerEnv(key);
    const result = await generatePrayer(chapterData.text, lang, getEnv);
    aiCache.setPrayer(dateStr, lang, result);
    return Response.json({ success: true, ...result }, { headers });
  } catch (err) {
    const message = err instanceof Error ? err.message : "AI request failed";
    if (process.env.NODE_ENV === "development") {
      console.error("[api/ai/prayer]", message, err);
    }
    const fallbackPrayer =
      lang === "ko"
        ? "오늘의 한 줄 기도를 불러오지 못했어요. 잠시 후 다시 시도해 주세요."
        : "Could not load today's prayer. Please try again later.";
    return Response.json(
      { success: true, prayer: fallbackPrayer, _error: process.env.NODE_ENV === "development" ? message : undefined },
      { headers }
    );
  }
}
