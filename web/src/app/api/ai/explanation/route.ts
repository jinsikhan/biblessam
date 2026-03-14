import { NextRequest } from "next/server";
import { validateBibleRef } from "@/lib/security/sanitize";
import { checkRateLimit, getClientIp, AI_RATE_LIMIT } from "@/lib/security/rate-limit";
import { getCorsHeaders } from "@/lib/security/cors";
import { getServerEnv } from "@/lib/security/env";
import { fetchChapter } from "@/lib/bible-api";
import { generateExplanation } from "@/lib/ai-api";
import { aiCache } from "@/lib/ai-cache";

export async function GET(request: NextRequest) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);

  const ip = getClientIp(request);
  const { allowed } = checkRateLimit(ip, AI_RATE_LIMIT);
  if (!allowed) {
    return Response.json({ success: false, error: "Too many requests" }, { status: 429, headers });
  }

  const book = request.nextUrl.searchParams.get("book");
  const chapter = request.nextUrl.searchParams.get("chapter");
  const lang = (request.nextUrl.searchParams.get("lang") || "ko").slice(0, 2) === "en" ? "en" : "ko";

  const { valid, book: safeBook, chapter: safeChapter } = validateBibleRef(book ?? "", chapter ?? "");
  if (!valid) {
    return Response.json({ success: false, error: "Invalid book or chapter" }, { status: 400, headers });
  }

  const cached = aiCache.getExplanation<{ explanation: string; application: string }>(safeBook, safeChapter, lang);
  if (cached) {
    return Response.json({ success: true, ...cached }, { headers });
  }

  const chapterData = await fetchChapter(safeBook, safeChapter);
  if (!chapterData?.text) {
    return Response.json({ success: false, error: "Chapter not found" }, { status: 404, headers });
  }

  try {
    const getEnv = (key: "GEMINI_API_KEY" | "OPENROUTER_API_KEY" | "GROQ_API_KEY") => getServerEnv(key);
    const result = await generateExplanation(chapterData.text, lang, getEnv);
    aiCache.setExplanation(safeBook, safeChapter, lang, result);
    return Response.json({ success: true, ...result }, { headers });
  } catch (err) {
    const message = err instanceof Error ? err.message : "AI request failed";
    if (process.env.NODE_ENV === "development") {
      console.error("[api/ai/explanation]", message, err);
    }
    const isNoKey = /no ai api key|api key configured/i.test(message);
    const fallbackKo =
      "AI 설명을 일시적으로 불러오지 못했어요. " +
      (isNoKey
        ? "웹 서버의 환경 변수에 GEMINI_API_KEY 또는 OPENROUTER_API_KEY를 설정해 주세요."
        : "잠시 후 다시 시도해 주세요.");
    return Response.json(
      {
        success: true,
        _fallback: true,
        explanation: fallbackKo,
        application: "다음에 💡 버튼을 다시 눌러 보세요.",
        ...(process.env.NODE_ENV === "development" && { _error: message }),
      },
      { headers }
    );
  }
}
