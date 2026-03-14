/**
 * 보안 응답 헤더
 * OWASP 권장 헤더 + CSP 설정
 */

export const SECURITY_HEADERS: Record<string, string> = {
  /** XSS 필터 활성화 */
  "X-XSS-Protection": "1; mode=block",

  /** MIME 타입 스니핑 방지 */
  "X-Content-Type-Options": "nosniff",

  /** Clickjacking 방지 */
  "X-Frame-Options": "DENY",

  /** Referrer 정보 최소화 */
  "Referrer-Policy": "strict-origin-when-cross-origin",

  /** HTTPS 강제 (프로덕션) */
  "Strict-Transport-Security": "max-age=31536000; includeSubDomains",

  /** 권한 정책 — 불필요한 브라우저 API 차단 */
  "Permissions-Policy": "camera=(), microphone=(), geolocation=()",

  /** CSP — XSS 방어의 핵심 */
  "Content-Security-Policy": [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' 'unsafe-eval'", // Next.js 빌드 호환
    "style-src 'self' 'unsafe-inline'", // Tailwind 인라인 스타일
    "img-src 'self' data: blob:",
    "font-src 'self'",
    "connect-src 'self' https://generativelanguage.googleapis.com https://openrouter.ai https://api.groq.com",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "form-action 'self'",
  ].join("; "),
};

/** Next.js 응답에 보안 헤더 추가 */
export function applySecurityHeaders(response: Response): Response {
  for (const [key, value] of Object.entries(SECURITY_HEADERS)) {
    response.headers.set(key, value);
  }
  return response;
}
