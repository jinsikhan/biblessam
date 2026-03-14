/**
 * CORS 설정
 * 허용된 도메인만 API 접근 가능
 */

const ALLOWED_ORIGINS = [
  "http://localhost:3000",
  "http://localhost:3001",
  "https://jinsikhan.github.io",
  process.env.NEXT_PUBLIC_APP_URL,
].filter(Boolean) as string[];

/** 개발 시 Flutter Web 등 localhost 임의 포트 허용 */
function isOriginAllowed(origin: string | null): boolean {
  if (!origin) return false;
  if (ALLOWED_ORIGINS.includes(origin)) return true;
  try {
    const u = new URL(origin);
    if (u.hostname === "localhost" || u.hostname === "127.0.0.1") return true;
  } catch {
    /* ignore */
  }
  return false;
}

/** CORS 프리플라이트 응답 생성 */
export function handleCors(request: Request): Response | null {
  const origin = request.headers.get("origin");

  // 프리플라이트 (OPTIONS) 처리
  if (request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: getCorsHeaders(origin),
    });
  }

  return null; // 프리플라이트 아님 → 계속 진행
}

/** CORS 헤더 생성 */
export function getCorsHeaders(origin: string | null): HeadersInit {
  const isAllowed = isOriginAllowed(origin);

  return {
    "Access-Control-Allow-Origin": isAllowed && origin ? origin : (ALLOWED_ORIGINS[0] ?? "http://localhost:3000"),
    "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Access-Control-Max-Age": "86400",
    "Access-Control-Allow-Credentials": "true",
  };
}
