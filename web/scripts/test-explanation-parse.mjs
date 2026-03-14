/**
 * 샘플 호출: AI 설명 API를 호출하고 원문 + 파싱 결과 확인
 * 실행: cd web && node --env-file=.env.local scripts/test-explanation-parse.mjs
 */
import { config } from "dotenv";
import { resolve } from "path";
import { fileURLToPath } from "url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
config({ path: resolve(__dirname, "../.env.local") });

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;

if (!GEMINI_API_KEY && !OPENROUTER_API_KEY) {
  console.error("GEMINI_API_KEY or OPENROUTER_API_KEY required in .env.local");
  process.exit(1);
}

const GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";
const OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions";

const prompt = `당신은 성경을 쉽게 설명해주는 도우미입니다.
아래 성경 본문을 읽고 다음 두 가지를 해주세요:
1. **쉬운 설명** (2~3문단)
2. **삶 적용** (한 문장): "오늘 이렇게 적용해 보세요:"로 시작

성경 본문:
In the beginning was the Word, and the Word was with God, and the Word was God. (John 1:1)

JSON 형식으로만 응답해 주세요:
{
  "explanation": "쉬운 설명 텍스트",
  "application": "오늘 이렇게 적용해 보세요: ..."
}`;

async function callGemini() {
  const res = await fetch(
    `${GEMINI_URL}?key=${encodeURIComponent(GEMINI_API_KEY)}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.3,
          maxOutputTokens: 1024,
          responseMimeType: "application/json",
        },
      }),
    }
  );
  if (!res.ok) throw new Error(`Gemini ${res.status}: ${await res.text()}`);
  const data = await res.json();
  return data.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
}

async function callOpenRouter() {
  const res = await fetch(OPENROUTER_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${OPENROUTER_API_KEY}`,
    },
    body: JSON.stringify({
      model: "openrouter/free",
      messages: [{ role: "user", content: prompt }],
      max_tokens: 1024,
      temperature: 0.3,
    }),
  });
  if (!res.ok) throw new Error(`OpenRouter ${res.status}: ${await res.text()}`);
  const data = await res.json();
  return data.choices?.[0]?.message?.content ?? "";
}

async function main() {
  console.log("Calling AI (Gemini first, then OpenRouter if needed)...\n");
  let raw = "";
  try {
    if (GEMINI_API_KEY) {
      raw = await callGemini();
      console.log("[Provider] Gemini");
    }
    if (!raw && OPENROUTER_API_KEY) {
      raw = await callOpenRouter();
      console.log("[Provider] OpenRouter");
    }
  } catch (e) {
    console.error("AI call failed:", e.message);
    process.exit(1);
  }

  console.log("\n--- Raw response (first 800 chars) ---\n");
  console.log(raw.slice(0, 800));
  console.log("\n--- End raw ---\n");

  const { extractJsonSync } = await import("@axync/extract-json");

  function normalizeNewlinesInJsonStrings(raw) {
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

  let extracted = extractJsonSync(raw, 5);
  if (extracted.length === 0) {
    const normalized = normalizeNewlinesInJsonStrings(raw);
    extracted = extractJsonSync(normalized, 5);
    console.log("After normalizeNewlinesInJsonStrings, extractJsonSync count:", extracted.length);
    if (extracted.length === 0) {
      try {
        const firstBrace = normalized.indexOf("{");
        const lastBrace = normalized.lastIndexOf("}");
        console.log("Brace range:", firstBrace, lastBrace, "normalized length:", normalized.length);
        if (firstBrace >= 0 && lastBrace > firstBrace) {
          const slice = normalized.slice(firstBrace, lastBrace + 1);
          const parsed = JSON.parse(slice);
          console.log("JSON.parse(normalized slice) succeeded, keys:", Object.keys(parsed));
          extracted = [parsed];
        }
      } catch (e) {
        console.log("JSON.parse(normalized) failed:", e.message);
        console.log("Slice preview (200 chars):", normalized.slice(normalized.indexOf("{"), normalized.indexOf("{") + 200));
      }
    }
  } else {
    console.log("extractJsonSync count:", extracted.length);
  }

  const obj = extracted.find(
    (item) =>
      item &&
      typeof item === "object" &&
      !Array.isArray(item) &&
      ("explanation" in item || "application" in item)
  ) ?? (extracted[0] && typeof extracted[0] === "object" && !Array.isArray(extracted[0]) ? extracted[0] : null);

  if (obj) {
    console.log("\n--- Parsed object ---");
    console.log("explanation:", typeof obj.explanation, obj.explanation ? String(obj.explanation).slice(0, 100) + "..." : "");
    console.log("application:", typeof obj.application, obj.application ? String(obj.application).slice(0, 80) + "..." : "");
  } else {
    console.log("\nParsed: no suitable object found");
    if (extracted.length) console.log("First extracted keys:", Object.keys(extracted[0] || {}));
  }
}

main().catch(console.error);
