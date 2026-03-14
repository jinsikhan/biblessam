/**
 * API Rate Limiting
 * IP 기반 요청 제한으로 DDoS/남용 방지
 */

interface RateLimitEntry {
  count: number;
  resetAt: number;
}

const store = new Map<string, RateLimitEntry>();

// 만료된 엔트리 주기적 정리 (메모리 누수 방지)
setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of store) {
    if (now > entry.resetAt) {
      store.delete(key);
    }
  }
}, 60_000);

interface RateLimitConfig {
  /** 윈도우 내 최대 요청 수 */
  maxRequests: number;
  /** 윈도우 크기 (ms) */
  windowMs: number;
}

interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  resetAt: number;
}

/** 기본 설정: 60초에 30회 */
export const DEFAULT_CONFIG: RateLimitConfig = {
  maxRequests: 30,
  windowMs: 60_000,
};

/** AI 엔드포인트 설정: 60초에 5회 (무료 API 보호) */
export const AI_RATE_LIMIT: RateLimitConfig = {
  maxRequests: 5,
  windowMs: 60_000,
};

/** 인증 엔드포인트 설정: 60초에 10회 (브루트포스 방지) */
export const AUTH_RATE_LIMIT: RateLimitConfig = {
  maxRequests: 10,
  windowMs: 60_000,
};

/** 성경 API 프록시: 30초에 15회 (bible-api.com 한도) */
export const BIBLE_RATE_LIMIT: RateLimitConfig = {
  maxRequests: 15,
  windowMs: 30_000,
};

export function checkRateLimit(
  identifier: string,
  config: RateLimitConfig = DEFAULT_CONFIG
): RateLimitResult {
  const now = Date.now();
  const key = `${identifier}:${config.maxRequests}`;
  const entry = store.get(key);

  if (!entry || now > entry.resetAt) {
    store.set(key, { count: 1, resetAt: now + config.windowMs });
    return { allowed: true, remaining: config.maxRequests - 1, resetAt: now + config.windowMs };
  }

  entry.count++;

  if (entry.count > config.maxRequests) {
    return { allowed: false, remaining: 0, resetAt: entry.resetAt };
  }

  return { allowed: true, remaining: config.maxRequests - entry.count, resetAt: entry.resetAt };
}

/** 클라이언트 IP 추출 (프록시 대응) */
export function getClientIp(request: Request): string {
  const forwarded = request.headers.get("x-forwarded-for");
  if (forwarded) {
    return forwarded.split(",")[0].trim();
  }
  return request.headers.get("x-real-ip") || "unknown";
}
