/**
 * 소셜 로그인 토큰 검증
 * 실제 연동 시 Google/Kakao/Apple API로 토큰 검증 후 사용자 정보 추출
 * MVP: mock — 토큰이 있으면 검증 성공으로 간주하고 placeholder 사용자 정보 반환
 */

import type { AuthProvider } from "./users";

export interface SocialProfile {
  provider: AuthProvider;
  providerId: string;
  email?: string;
  displayName?: string;
  profileImage?: string;
}

/**
 * 소셜 토큰 검증 (mock)
 * - 가능하면 실제 검증 로직 추가 (Google token verify, Kakao/Apple API)
 * - 현재: 토큰이 비어있지 않으면 성공, providerId는 token 해시 기반 생성
 */
export function verifySocialToken(
  provider: AuthProvider,
  token: string
): SocialProfile | null {
  const t = typeof token === "string" ? token.trim() : "";
  if (!t) return null;

  // Mock: 토큰 앞 16자 + 해시 비슷한 값으로 providerId 생성 (동일 토큰이면 동일 사용자)
  let hash = 0;
  for (let i = 0; i < t.length; i++) {
    hash = (hash << 5) - hash + t.charCodeAt(i);
    hash |= 0;
  }
  const providerId = `mock_${provider}_${Math.abs(hash).toString(36)}`;

  return {
    provider,
    providerId,
    email: undefined,
    displayName: undefined,
    profileImage: undefined,
  };
}
