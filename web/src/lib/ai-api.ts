/**
 * AI API 연동 — Gemini(1순위) → OpenRouter(2순위) → Groq(3순위) 폴백
 * 쉬운 설명 + 삶 적용, 오늘의 한 줄 기도 생성
 * 교리/해석 금지, 부드러운 제안만
 */

import { extractJsonSync } from "@axync/extract-json";
import { jsonrepair } from "jsonrepair";

const GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";
const GEMINI_STREAM_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:streamGenerateContent";
const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";
const GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";
const REQUEST_TIMEOUT_MS = 30_000;

export interface ExplanationResult {
  explanation: string;
  /** 핵심 요약 정리 (3~5개) */
  summary?: string[];
  application: string;
  /** JSON 파싱 실패 후 마크다운 원문으로 반환된 경우 true — 클라이언트에서 모달로만 표시 */
  _markdownFallback?: boolean;
}

export interface PrayerResult {
  prayer: string;
}

const EXPLANATION_PROMPT_KO = `당신은 성경을 쉽게 설명해주는 도우미입니다.

아래는 **한 장 전체** 성경 본문입니다. 이 **장 전체**를 읽고 다음 형식으로 설명해 주세요.

**문체**: 설명문 전체는 반드시 **합니다체**(문어체)로 써 주세요. 예: "~이다", "~한다", "~하였다". 해요체(~해요, ~였어요)나 구어체는 쓰지 마세요.

**쉬운 설명(explanation)** 형식:
1) 본문의 흐름에 따라 구간을 나누고, 각 구간마다 제목을 달아 주세요. 제목 형식: "제목 (장:절–절)" 예: "등잔대와 등불 (8:1–4)"
2) 각 구간 아래에 bullet으로 핵심을 정리해 주세요. 등장하는 대상·역할·의미·목적 등을 구체적으로, 초등학생도 이해할 수 있게 써 주세요. 교리나 신학적 해석은 넣지 말고 본문 사실만.
3) 마지막에 "한 줄로 요약" 항목을 두고, 장의 핵심을 2~3개 bullet으로 짧게 정리해 주세요.

예시 구조:
[구간 제목 (장:절–절)]
• 내용 요점 1
• 내용 요점 2
• 의미나 목적
[다음 구간 제목 (장:절–절)]
...
한 줄로 요약
• 요약 1
• 요약 2

**삶 적용(application)**: "오늘 이렇게 적용해 보세요:"로 시작하는 실천 가능한 한 문장을 써 주세요. 이 한 문장만 해요체로 써도 됩니다.

성경 본문 (한 장 전체):
`;

const EXPLANATION_PROMPT_EN = `You are a helper that explains the Bible in simple terms.

Below is the **full text of one chapter**. Read the **entire chapter** and explain it in this format:

**Simple explanation (explanation)** format:
1) Divide the chapter into sections by flow of the text. Give each section a heading in the form "Title (chapter:verse–verse)" e.g. "The Lampstand and Lamps (8:1–4)".
2) Under each section, list key points as bullets: what appears, roles, meaning, purpose—concretely and in simple language. Explain only what the text says; no doctrine or theological interpretation.
3) At the end add a "One-line summary" section with 2–3 short bullets capturing the main points of the chapter.

Example structure:
[Section title (ch:v–v)]
• Key point 1
• Key point 2
• Meaning or purpose
[Next section title (ch:v–v)]
...
One-line summary
• Summary 1
• Summary 2

**Life application (application)**: One practical sentence starting with "Apply this today:".

Bible passage (full chapter):
`;

const APPLICATION_SUFFIX_KO = `

JSON 형식으로만 응답해 주세요. 다른 설명 없이 JSON만 출력하세요. explanation과 application 값 안에서 줄바꿈은 반드시 \\n으로만 표기하고 실제 줄바꿈을 넣지 마세요.
{
  "explanation": "쉬운 설명 텍스트",
  "summary": ["요약 1", "요약 2", "요약 3"],
  "application": "오늘 이렇게 적용해 보세요: ..."
}`;

const APPLICATION_SUFFIX_EN = `

Respond only in JSON format. No other text, only JSON. Inside explanation and application strings use \\n for line breaks, not actual newlines.
{
  "explanation": "Simple explanation text",
  "summary": ["Summary 1", "Summary 2", "Summary 3"],
  "application": "Apply this today: ..."
}`;

function ensureStringArray(value: unknown): string[] | undefined {
  if (!value) return undefined;
  if (Array.isArray(value)) {
    const items = value
      .map((v) => (typeof v === "string" ? v.trim() : String(v ?? "").trim()))
      .filter(Boolean);
    return items.length ? items : undefined;
  }
  if (typeof value === "string") {
    // "• ..." 또는 줄바꿈 요약을 배열로 정리
    const lines = value
      .split(/\\n|\n/)
      .map((s) => s.replace(/^[\s•\-\*]+/, "").trim())
      .filter(Boolean);
    return lines.length ? lines : undefined;
  }
  return undefined;
}

const PRAYER_PROMPT_KO = `아래 성경 본문의 핵심 메시지를 바탕으로 짧고 따뜻한 기도문 1~2문장을 써 주세요.
- "하나님"으로 시작하세요.
- 특정 교단이나 교리에 치우치지 않는 중립적인 기도문이어야 합니다.
- 따뜻하고 위로가 되는 톤으로 써 주세요.

성경 본문:
`;

const PRAYER_PROMPT_EN = `Based on the key message of the Bible passage below, write a short, warm prayer in 1-2 sentences.
- Start with "God" or "Lord".
- The prayer should be neutral, not favoring any denomination or doctrine.
- Write in a warm, comforting tone.

Bible passage:
`;

const PRAYER_SUFFIX_KO = `

JSON 형식으로만 응답해 주세요:
{
  "prayer": "기도문 텍스트"
}`;

const PRAYER_SUFFIX_EN = `

Respond only in JSON format:
{
  "prayer": "prayer text"
}`;

/** JSON 문자열 값 안의 실제 줄바꿈을 \\n으로 치환 (Gemini 등이 유효하지 않은 JSON을 줄 때 대비) */
function normalizeNewlinesInJsonStrings(raw: string): string {
  let result = "";
  let inString = false;
  let escaped = false;
  for (let i = 0; i < raw.length; i++) {
    const c = raw[i];
    if (escaped) {
      result += c;
      escaped = false;
      continue;
    }
    if (c === "\\") {
      result += c;
      escaped = true;
      continue;
    }
    if (c === '"') {
      inString = !inString;
      result += c;
      continue;
    }
    if (inString && (c === "\n" || c === "\r")) {
      result += c === "\n" ? "\\n" : "\\r";
      continue;
    }
    result += c;
  }
  return result;
}

function parseJsonFromText(text: string): Record<string, unknown> | null {
  const trimmed = text.trim();
  let input = trimmed;
  const codeBlockMatch = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (codeBlockMatch) input = codeBlockMatch[1].trim();

  let extracted = extractJsonSync(input, 5);
  for (const item of extracted) {
    if (item && typeof item === "object" && !Array.isArray(item)) {
      const obj = item as Record<string, unknown>;
      if ("explanation" in obj || "application" in obj || "prayer" in obj) return obj;
    }
  }
  if (extracted.length > 0 && typeof extracted[0] === "object" && !Array.isArray(extracted[0])) {
    return extracted[0] as Record<string, unknown>;
  }

  const firstBrace = input.indexOf("{");
  if (firstBrace < 0) return null;

  const lastBrace = input.lastIndexOf("}");
  const slice =
    lastBrace > firstBrace
      ? input.slice(firstBrace, lastBrace + 1)
      : input.slice(firstBrace);

  const candidates = [slice, normalizeNewlinesInJsonStrings(slice)];
  for (const candidate of candidates) {
    try {
      const repaired = jsonrepair(candidate);
      const parsed = JSON.parse(repaired) as Record<string, unknown>;
      if (parsed && typeof parsed === "object" && ("explanation" in parsed || "application" in parsed || "prayer" in parsed)) {
        return parsed;
      }
      if (parsed && typeof parsed === "object") return parsed;
    } catch {
      // try next
    }
  }
  return null;
}

function ensureString(value: unknown, fallback: string): string {
  if (typeof value === "string" && value.trim()) return value.trim();
  if (value != null) return String(value);
  return fallback;
}

async function callGemini(
  apiKey: string,
  prompt: string,
  jsonMode: boolean,
  maxOutputTokens = 1024
): Promise<string> {
  const body: Record<string, unknown> = {
    contents: [{ role: "user", parts: [{ text: prompt }] }],
    generationConfig: {
      temperature: 0.3,
      maxOutputTokens,
      ...(jsonMode && { responseMimeType: "application/json" }),
    },
  };
  const res = await fetch(`${GEMINI_URL}?key=${encodeURIComponent(apiKey)}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Gemini ${res.status}: ${err}`);
  }
  const data = (await res.json()) as { candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }> };
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) throw new Error("Gemini: empty response");
  return text;
}

/** Gemini 스트리밍: SSE 청크를 순차적으로 yield */
async function* streamGemini(
  apiKey: string,
  prompt: string,
  jsonMode: boolean,
  maxOutputTokens = 4096
): AsyncGenerator<string, void, unknown> {
  const body: Record<string, unknown> = {
    contents: [{ role: "user", parts: [{ text: prompt }] }],
    generationConfig: {
      temperature: 0.3,
      maxOutputTokens,
      ...(jsonMode && { responseMimeType: "application/json" }),
    },
  };
  const url = `${GEMINI_STREAM_URL}?key=${encodeURIComponent(apiKey)}&alt=sse`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-goog-api-key": apiKey,
    },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Gemini ${res.status}: ${err.slice(0, 200)}`);
  }
  const reader = res.body?.getReader();
  if (!reader) throw new Error("Gemini: no response body");
  const decoder = new TextDecoder();
  let buffer = "";
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split(/\r?\n/);
      buffer = lines.pop() ?? "";
      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed) continue;
        let raw = trimmed.startsWith("data: ") ? trimmed.slice(6).trim() : trimmed;
        if (raw === "[DONE]" || raw === "") continue;
        try {
          const data = JSON.parse(raw) as {
            candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
          };
          const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
          if (text) yield text;
        } catch {
          // skip malformed chunk
        }
      }
    }
    if (buffer.trim()) {
      let raw = buffer.trim().startsWith("data: ") ? buffer.trim().slice(6).trim() : buffer.trim();
      if (raw) {
        try {
          const data = JSON.parse(raw) as { candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }> };
          const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
          if (text) yield text;
        } catch {
          // skip
        }
      }
    }
  } finally {
    reader.releaseLock();
  }
}

/**
 * 스트리밍으로 설명 생성 (Gemini만 지원, 실패 시 에러 throw)
 * 전체 텍스트를 모은 뒤 parseJsonFromText로 파싱해 ExplanationResult 반환
 */
export async function generateExplanationStream(
  chapterText: string,
  lang: "ko" | "en",
  getEnv: (key: "GEMINI_API_KEY" | "OPENROUTER_API_KEY" | "GROQ_API_KEY") => string,
  onDelta: (chunk: string) => void
): Promise<ExplanationResult> {
  const prompt =
    (lang === "ko" ? EXPLANATION_PROMPT_KO : EXPLANATION_PROMPT_EN) +
    chapterText +
    (lang === "ko" ? APPLICATION_SUFFIX_KO : APPLICATION_SUFFIX_EN);
  const apiKey = getEnv("GEMINI_API_KEY");
  if (!apiKey) throw new Error("No AI API key configured");

  let fullText = "";
  for await (const chunk of streamGemini(apiKey, prompt, true, 4096)) {
    fullText += chunk;
    onDelta(chunk);
  }
  const obj = parseJsonFromText(fullText);
  const fallbackKo =
    lang === "ko" ? "응답 형식을 인식하지 못했어요. 잠시 후 다시 시도해 주세요." : "Could not parse response. Please try again.";
  const fallbackApp = lang === "ko" ? "다음에 💡 버튼을 다시 눌러 보세요." : "Try the 💡 button again.";
  if (!obj) {
    if (process.env.NODE_ENV === "development") {
      console.warn("[ai-api] Explanation stream response was not valid JSON. First 600 chars:", fullText.slice(0, 600));
    }
    throw new Error("AI response was not valid JSON with explanation and application");
  }
  const explanation = ensureString(obj.explanation ?? obj.Explanation, "");
  const summary = ensureStringArray((obj as any).summary ?? (obj as any).Summary);
  const application = ensureString(obj.application ?? obj.Application, "");
  return {
    explanation: explanation || fallbackKo,
    ...(summary ? { summary } : {}),
    application: application || fallbackApp,
  };
}

async function callOpenRouter(apiKey: string, prompt: string, maxTokens = 1024): Promise<string> {
  const res = await fetch(OPENROUTER_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: "openrouter/free",
      messages: [{ role: "user", content: prompt }],
      max_tokens: maxTokens,
      temperature: 0.3,
    }),
    signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`OpenRouter ${res.status}: ${err}`);
  }
  const data = (await res.json()) as { choices?: Array<{ message?: { content?: string } }> };
  const text = data.choices?.[0]?.message?.content;
  if (!text) throw new Error("OpenRouter: empty response");
  return text;
}

async function callGroq(apiKey: string, prompt: string, maxTokens = 1024): Promise<string> {
  const res = await fetch(GROQ_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: "llama-3.3-70b-versatile",
      messages: [{ role: "user", content: prompt }],
      max_tokens: maxTokens,
      temperature: 0.3,
    }),
    signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Groq ${res.status}: ${err}`);
  }
  const data = (await res.json()) as { choices?: Array<{ message?: { content?: string } }> };
  const text = data.choices?.[0]?.message?.content;
  if (!text) throw new Error("Groq: empty response");
  return text;
}

export type AiProvider = "gemini" | "openrouter" | "groq";

async function generateWithFallback(
  getPrompt: () => string,
  jsonMode: boolean,
  getEnv: (key: "GEMINI_API_KEY" | "OPENROUTER_API_KEY" | "GROQ_API_KEY") => string,
  maxTokens = 1024
): Promise<string> {
  const prompt = getPrompt();
  const errors: string[] = [];

  const geminiKey = getEnv("GEMINI_API_KEY");
  if (geminiKey) {
    try {
      return await callGemini(geminiKey, prompt, jsonMode, maxTokens);
    } catch (e) {
      errors.push(`Gemini: ${e instanceof Error ? e.message : String(e)}`);
    }
  }

  const openRouterKey = getEnv("OPENROUTER_API_KEY");
  if (openRouterKey) {
    try {
      return await callOpenRouter(openRouterKey, prompt, maxTokens);
    } catch (e) {
      errors.push(`OpenRouter: ${e instanceof Error ? e.message : String(e)}`);
    }
  }

  const groqKey = getEnv("GROQ_API_KEY");
  if (groqKey) {
    try {
      return await callGroq(groqKey, prompt, maxTokens);
    } catch (e) {
      errors.push(`Groq: ${e instanceof Error ? e.message : String(e)}`);
    }
  }

  throw new Error(errors.length ? errors.join("; ") : "No AI API key configured");
}

/**
 * 쉬운 설명 + 삶 적용 한 줄 생성 (On-Demand 호출용)
 * @param chapterText - 장 전체 본문
 * @param lang - "ko" | "en"
 */
export async function generateExplanation(
  chapterText: string,
  lang: "ko" | "en",
  getEnv: (key: "GEMINI_API_KEY" | "OPENROUTER_API_KEY" | "GROQ_API_KEY") => string
): Promise<ExplanationResult> {
  const prompt =
    (lang === "ko" ? EXPLANATION_PROMPT_KO : EXPLANATION_PROMPT_EN) +
    chapterText +
    (lang === "ko" ? APPLICATION_SUFFIX_KO : APPLICATION_SUFFIX_EN);
  const text = await generateWithFallback(() => prompt, true, getEnv, 4096);
  const obj = parseJsonFromText(text);
  const fallbackKo = lang === "ko" ? "응답 형식을 인식하지 못했어요. 잠시 후 다시 시도해 주세요." : "Could not parse response. Please try again.";
  const fallbackApp = lang === "ko" ? "다음에 💡 버튼을 다시 눌러 보세요." : "Try the 💡 button again.";
  if (!obj) {
    const mdFallback = tryUseRawAsMarkdownExplanation(text, lang);
    if (mdFallback) {
      if (process.env.NODE_ENV === "development") {
        console.warn("[ai-api] Used raw response as markdown explanation (JSON parse failed)");
      }
      return { ...mdFallback, _markdownFallback: true as const };
    }
    if (process.env.NODE_ENV === "development") {
      console.warn("[ai-api] Explanation response was not valid JSON. First 600 chars:", text.slice(0, 600));
    }
    return { explanation: fallbackKo, application: fallbackApp };
  }
  const explanation = ensureString(obj.explanation ?? obj.Explanation, "");
  const summary = ensureStringArray((obj as any).summary ?? (obj as any).Summary);
  const application = ensureString(obj.application ?? obj.Application, "");
  return {
    explanation: explanation || fallbackKo,
    ...(summary ? { summary } : {}),
    application: application || fallbackApp,
  };
}

/**
 * JSON이 아닌 응답(마크다운/본문)을 설명으로 사용할 수 있으면 반환
 */
function tryUseRawAsMarkdownExplanation(
  raw: string,
  lang: "ko" | "en"
): ExplanationResult | null {
  const t = raw.trim();
  if (t.length < 80) return null;
  const errPatterns = [/^sorry/i, /^i cannot/i, /^error/i, /^죄송/i, /^할 수 없/i];
  if (errPatterns.some((p) => p.test(t))) return null;
  const applicationMarkerKo = "오늘 이렇게 적용해 보세요:";
  const applicationMarkerEn = "Apply this today:";
  const idxKo = t.indexOf(applicationMarkerKo);
  const idxEn = t.indexOf(applicationMarkerEn);
  const idx = lang === "ko" ? (idxKo >= 0 ? idxKo : idxEn) : (idxEn >= 0 ? idxEn : idxKo);
  let explanation = t;
  let application = lang === "ko" ? "다음에 💡 버튼을 다시 눌러 보세요." : "Try the 💡 button again.";
  if (idx >= 0) {
    explanation = t.slice(0, idx).trim();
    const line = t.slice(idx).split(/\n/)[0] ?? "";
    const afterColon = line.replace(/^[^:]*:\s*/, "").trim();
    if (afterColon.length > 0 && afterColon.length < 400) application = afterColon;
  }
  if (explanation.length < 80) return null;
  const maxLen = 12000;
  if (explanation.length > maxLen) explanation = explanation.slice(0, maxLen) + "\n\n…";
  return { explanation, application };
}

/**
 * 오늘의 한 줄 기도 생성 (날짜별 캐시 권장)
 * @param chapterText - 오늘의 말씀 장 본문
 * @param lang - "ko" | "en"
 */
export async function generatePrayer(
  chapterText: string,
  lang: "ko" | "en",
  getEnv: (key: "GEMINI_API_KEY" | "OPENROUTER_API_KEY" | "GROQ_API_KEY") => string
): Promise<PrayerResult> {
  const prompt =
    (lang === "ko" ? PRAYER_PROMPT_KO : PRAYER_PROMPT_EN) + chapterText + (lang === "ko" ? PRAYER_SUFFIX_KO : PRAYER_SUFFIX_EN);
  const text = await generateWithFallback(() => prompt, true, getEnv);
  const obj = parseJsonFromText(text);
  const prayer = obj ? ensureString(obj.prayer ?? obj.Prayer, "") : "";
  if (!prayer) {
    throw new Error("AI response was not valid JSON with prayer");
  }
  return { prayer };
}
