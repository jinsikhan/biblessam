/**
 * Refresh Token 블랙리스트 (로그아웃 시 무효화)
 * 인메모리 — 서버 재시작 시 초기화됨 (MVP)
 */

const blacklist = new Set<string>();

export function addToBlacklist(jti: string): void {
  blacklist.add(jti);
}

export function isBlacklisted(jti: string): boolean {
  return blacklist.has(jti);
}
