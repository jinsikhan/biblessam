/**
 * 환경 변수 검증
 * 서버 시작 시 필수 변수 누락/노출 방지
 */

import path from "node:path";
import fs from "node:fs";

/** 절대 클라이언트에 노출되면 안 되는 변수 */
const SERVER_ONLY_VARS = [
  "GEMINI_API_KEY",
  "OPENROUTER_API_KEY",
  "GROQ_API_KEY",
  "DATABASE_URL",
  "REDIS_URL",
  "JWT_SECRET",
  "GOOGLE_CLIENT_SECRET",
  "KAKAO_CLIENT_SECRET",
] as const;

let cachedEnv: Record<string, string> | null = null;
let loadedEnvPath: string | null = null;
/** .env 파일에서 KEY=VALUE 파싱 (process.env 미반영 시 대비) */
function readEnvFile(): Record<string, string> {
  if (cachedEnv && process.env.NODE_ENV !== "development") return cachedEnv;
  if (process.env.NODE_ENV === "development") {
    cachedEnv = null;
    loadedEnvPath = null;
  }
  const cwd = process.cwd();
  const candidates = [
    path.resolve(cwd, ".env.local"),
    path.resolve(cwd, ".env"),
    path.resolve(cwd, "..", ".env"),
    path.resolve(cwd, "..", "..", ".env"),
  ];
  const out: Record<string, string> = {};
  for (const envPath of candidates) {
    if (!fs.existsSync(envPath)) continue;
    try {
      loadedEnvPath = envPath;
      const raw = fs.readFileSync(envPath, "utf-8");
      for (const line of raw.split(/\r?\n/)) {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith("#")) continue;
        const eq = trimmed.indexOf("=");
        if (eq <= 0) continue;
        let key = trimmed.slice(0, eq).trim();
        if (key.startsWith("export ")) key = key.slice(7).trim();
        let val = trimmed.slice(eq + 1).trim();
        if (val.startsWith('"') && val.endsWith('"')) val = val.slice(1, -1).replace(/\\"/g, '"');
        if (val.startsWith("'") && val.endsWith("'")) val = val.slice(1, -1).replace(/\\'/g, "'");
        key = key.replace(/^\uFEFF/, "").trim();
        if (key && (val !== "" || out[key] === undefined)) out[key] = val;
      }
      if (process.env.NODE_ENV === "development") {
        const hasAi = !!(out.GEMINI_API_KEY || out.OPENROUTER_API_KEY || out.GROQ_API_KEY);
        console.log("[env] Read", envPath, "| keys:", Object.keys(out).length, "| AI:", hasAi);
      }
      break;
    } catch (e) {
      if (process.env.NODE_ENV === "development") console.warn("[env] Failed", envPath, e);
    }
  }
  if (process.env.NODE_ENV === "development" && !out.GEMINI_API_KEY && !out.OPENROUTER_API_KEY) {
    console.warn("[env] No AI keys in .env. cwd:", cwd, "tried:", candidates);
  }
  if (!out.GEMINI_API_KEY && process.env.GEMINI_API_KEY) out.GEMINI_API_KEY = process.env.GEMINI_API_KEY;
  if (!out.OPENROUTER_API_KEY && process.env.OPENROUTER_API_KEY) out.OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
  if (!out.GROQ_API_KEY && process.env.GROQ_API_KEY) out.GROQ_API_KEY = process.env.GROQ_API_KEY;
  cachedEnv = out;
  return out;
}

/** 개발 시에만: AI 키 로드 상태 확인 (키 값은 노출 안 함) */
export function getEnvDebug(): {
  cwd: string;
  envPath: string | null;
  fromProcessEnv: { GEMINI: boolean; OPENROUTER: boolean; GROQ: boolean };
  fromFile: { GEMINI: boolean; OPENROUTER: boolean; GROQ: boolean };
  getServerEnvReturns: { GEMINI: boolean; OPENROUTER: boolean; GROQ: boolean };
} {
  const file = readEnvFile();
  return {
    cwd: process.cwd(),
    envPath: loadedEnvPath,
    fromProcessEnv: {
      GEMINI: !!process.env.GEMINI_API_KEY,
      OPENROUTER: !!process.env.OPENROUTER_API_KEY,
      GROQ: !!process.env.GROQ_API_KEY,
    },
    fromFile: {
      GEMINI: !!file.GEMINI_API_KEY,
      OPENROUTER: !!file.OPENROUTER_API_KEY,
      GROQ: !!file.GROQ_API_KEY,
    },
    getServerEnvReturns: {
      GEMINI: !!getServerEnv("GEMINI_API_KEY"),
      OPENROUTER: !!getServerEnv("OPENROUTER_API_KEY"),
      GROQ: !!getServerEnv("GROQ_API_KEY"),
    },
  };
}

/** 서버 시작 시 환경 변수 검증 */
export function validateEnv(): { valid: boolean; warnings: string[]; errors: string[] } {
  const warnings: string[] = [];
  const errors: string[] = [];

  // AI API 키 — 최소 1개는 필요
  const hasAiKey =
    !!process.env.GEMINI_API_KEY ||
    !!process.env.OPENROUTER_API_KEY ||
    !!process.env.GROQ_API_KEY;

  if (!hasAiKey) {
    warnings.push("AI API 키가 하나도 설정되지 않았습니다. AI 설명 기능이 동작하지 않습니다.");
  }

  // NEXT_PUBLIC_ 접두어로 시작하는 민감 변수 감지
  for (const key of SERVER_ONLY_VARS) {
    if (process.env[`NEXT_PUBLIC_${key}`]) {
      errors.push(`보안 위반: ${key}가 NEXT_PUBLIC_ 접두어로 노출되어 있습니다. 즉시 제거하세요.`);
    }
  }

  // JWT_SECRET 강도 검사
  const jwtSecret = process.env.JWT_SECRET;
  if (jwtSecret && jwtSecret.length < 32) {
    warnings.push("JWT_SECRET이 32자 미만입니다. 더 긴 시크릿을 사용하세요.");
  }

  return { valid: errors.length === 0, warnings, errors };
}

/** 서버 전용 환경 변수 안전하게 가져오기 */
export function getServerEnv(key: (typeof SERVER_ONLY_VARS)[number]): string {
  if (typeof window !== "undefined") {
    throw new Error(`보안 위반: 서버 전용 변수 ${key}를 클라이언트에서 접근 시도.`);
  }
  let val = process.env[key] ?? "";
  if (!val && (key === "GEMINI_API_KEY" || key === "OPENROUTER_API_KEY" || key === "GROQ_API_KEY")) {
    val = readEnvFile()[key] ?? "";
  }
  return val;
}
