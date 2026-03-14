import { NextRequest } from "next/server";
import { validateBibleRef } from "@/lib/security/sanitize";
import { checkRateLimit, getClientIp, AI_RATE_LIMIT } from "@/lib/security/rate-limit";
import { getCorsHeaders } from "@/lib/security/cors";
import { getServerEnv } from "@/lib/security/env";
import { fetchChapter } from "@/lib/bible-api";
import { generateExplanationStream } from "@/lib/ai-api";
import { aiCache } from "@/lib/ai-cache";

const SSE_HEADERS = {
  "Content-Type": "text/event-stream",
  "Cache-Control": "no-cache, no-transform",
  Connection: "keep-alive",
} as const;

function sseLine(data: object): string {
  return `data: ${JSON.stringify(data)}\n\n`;
}

export async function GET(request: NextRequest) {
  const origin = request.headers.get("origin");
  const baseHeaders = { ...getCorsHeaders(origin), ...SSE_HEADERS };

  const ip = getClientIp(request);
  const { allowed } = checkRateLimit(ip, AI_RATE_LIMIT);
  if (!allowed) {
    return Response.json({ success: false, error: "Too many requests" }, { status: 429, headers: getCorsHeaders(origin) });
  }

  const book = request.nextUrl.searchParams.get("book");
  const chapter = request.nextUrl.searchParams.get("chapter");
  const lang = (request.nextUrl.searchParams.get("lang") || "ko").slice(0, 2) === "en" ? "en" : "ko";

  const { valid, book: safeBook, chapter: safeChapter } = validateBibleRef(book ?? "", chapter ?? "");
  if (!valid) {
    return Response.json({ success: false, error: "Invalid book or chapter" }, { status: 400, headers: getCorsHeaders(origin) });
  }

  const cached = aiCache.getExplanation<{ explanation: string; application: string }>(safeBook, safeChapter, lang);
  if (cached) {
    const stream = new ReadableStream({
      start(controller) {
        controller.enqueue(new TextEncoder().encode(sseLine({ done: true, ...cached })));
        controller.close();
      },
    });
    return new Response(stream, { headers: baseHeaders });
  }

  let chapterData: Awaited<ReturnType<typeof fetchChapter>>;
  try {
    chapterData = await fetchChapter(safeBook, safeChapter);
  } catch {
    return Response.json({ success: false, error: "Chapter fetch failed" }, { status: 502, headers: getCorsHeaders(origin) });
  }
  if (!chapterData?.text) {
    return Response.json({ success: false, error: "Chapter not found" }, { status: 404, headers: getCorsHeaders(origin) });
  }

  const getEnv = (key: "GEMINI_API_KEY" | "OPENROUTER_API_KEY" | "GROQ_API_KEY") => getServerEnv(key);
  const encoder = new TextEncoder();

  const stream = new ReadableStream({
    async start(controller) {
      try {
        const result = await generateExplanationStream(
          chapterData!.text,
          lang,
          getEnv,
          (chunk) => {
            controller.enqueue(encoder.encode(sseLine({ delta: chunk })));
          }
        );
        aiCache.setExplanation(safeBook, safeChapter, lang, result);
        controller.enqueue(encoder.encode(sseLine({ done: true, explanation: result.explanation, application: result.application })));
      } catch (err) {
        const message = err instanceof Error ? err.message : "AI request failed";
        if (process.env.NODE_ENV === "development") {
          console.error("[api/ai/explanation/stream]", message, err);
        }
        controller.enqueue(encoder.encode(sseLine({ error: message })));
      } finally {
        controller.close();
      }
    },
  });

  return new Response(stream, { headers: baseHeaders });
}
