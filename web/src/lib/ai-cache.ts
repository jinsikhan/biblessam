/**
 * AI 응답 캐시 — Redis 없으면 메모리 캐시 사용
 * 장별 설명: ai:explanation:{book}:{chapter}:{lang}
 * 날짜별 기도: ai:prayer:{date}:{lang}
 * 설명 캐시 TTL: 무제한(성경 불변), 기도 캐시 TTL: 24시간
 */

export interface CacheEntry<T> {
  value: T;
  expiresAt: number | null; // null = 만료 없음
}

const memoryCache = new Map<string, CacheEntry<unknown>>();
const PRAYER_TTL_MS = 24 * 60 * 60 * 1000;

function getNow(): number {
  return Date.now();
}

function get<T>(key: string): T | null {
  const entry = memoryCache.get(key) as CacheEntry<T> | undefined;
  if (!entry) return null;
  if (entry.expiresAt !== null && getNow() > entry.expiresAt) {
    memoryCache.delete(key);
    return null;
  }
  return entry.value;
}

function set<T>(key: string, value: T, ttlMs: number | null): void {
  memoryCache.set(key, {
    value,
    expiresAt: ttlMs === null ? null : getNow() + ttlMs,
  });
}

/** 장별 설명 캐시 키 */
export function explanationCacheKey(book: string, chapter: number, lang: string): string {
  const b = String(book).toLowerCase().replace(/\s+/g, "+");
  return `ai:explanation:${b}:${chapter}:${lang}`;
}

/** 날짜별 기도 캐시 키 */
export function prayerCacheKey(date: string, lang: string): string {
  return `ai:prayer:${date}:${lang}`;
}

export const aiCache = {
  getExplanation<T>(book: string, chapter: number, lang: string): T | null {
    return get<T>(explanationCacheKey(book, chapter, lang));
  },
  setExplanation<T>(book: string, chapter: number, lang: string, value: T): void {
    set(explanationCacheKey(book, chapter, lang), value, null);
  },
  getPrayer<T>(date: string, lang: string): T | null {
    return get<T>(prayerCacheKey(date, lang));
  },
  setPrayer<T>(date: string, lang: string, value: T): void {
    set(prayerCacheKey(date, lang), value, PRAYER_TTL_MS);
  },
};
