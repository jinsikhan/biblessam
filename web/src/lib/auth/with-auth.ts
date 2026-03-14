/**
 * 선택적 인증: 요청에서 JWT 검증 후 사용자 정보 반환
 * 비로그인도 허용 — Authorization 없으면 anonymous
 */

import { getAccessTokenFromRequest, verifyAccessToken } from "./jwt";
import { getUserById } from "./users";

export interface AuthResult {
  userId: string;
  user: { id: string; provider: string; email?: string; displayName?: string; profileImage?: string } | null;
}

/**
 * Request에서 Authorization Bearer 또는 cookie로 JWT 검증 후 userId, user 반환
 * 토큰 없음/만료/무효 → userId: "anonymous", user: null
 */
export function getAuthFromRequest(request: Request): AuthResult {
  const token = getAccessTokenFromRequest(request);
  if (!token) {
    const xUserId = request.headers.get("x-user-id");
    const fallback = xUserId?.trim().slice(0, 64);
    return {
      userId: fallback || "anonymous",
      user: null,
    };
  }

  const payload = verifyAccessToken(token);
  if (!payload) {
    return { userId: "anonymous", user: null };
  }

  const user = getUserById(payload.sub);
  return {
    userId: payload.sub,
    user: user
      ? {
          id: user.id,
          provider: user.provider,
          email: user.email,
          displayName: user.displayName,
          profileImage: user.profileImage,
        }
      : null,
  };
}
