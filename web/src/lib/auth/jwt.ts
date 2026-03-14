/**
 * JWT 발급 및 검증
 * Access Token(짧은 유효기간), Refresh Token(긴 유효기간)
 */

import jwt from "jsonwebtoken";
import { getServerEnv } from "@/lib/security/env";

const ACCESS_EXPIRES_IN = "1h";
const REFRESH_EXPIRES_IN = "7d";

export interface JwtPayload {
  sub: string;   // userId
  type: "access" | "refresh";
  iat?: number;
  exp?: number;
  jti?: string;
}

function getSecret(): string {
  let secret = "";
  try {
    secret = getServerEnv("JWT_SECRET");
  } catch {
    // getServerEnv throws on client; server may have unset JWT_SECRET
  }
  if (!secret || secret.length < 16) {
    if (process.env.NODE_ENV === "development") {
      secret = "dev-jwt-secret-min-32-chars-for-biblesam";
    }
    if (!secret || secret.length < 16) {
      throw new Error("JWT_SECRET is not set or too short (min 16 chars)");
    }
  }
  return secret;
}

/** Access Token 발급 */
export function signAccessToken(userId: string): string {
  return jwt.sign(
    { sub: userId, type: "access" } as Omit<JwtPayload, "iat" | "exp">,
    getSecret(),
    { expiresIn: ACCESS_EXPIRES_IN }
  );
}

/** Refresh Token 발급 (jti로 로그아웃 블랙리스트 대응) */
export function signRefreshToken(userId: string): { token: string; jti: string } {
  const jti = `rt_${Date.now()}_${Math.random().toString(36).slice(2, 11)}`;
  const token = jwt.sign(
    { sub: userId, type: "refresh", jti } as Omit<JwtPayload, "iat" | "exp">,
    getSecret(),
    { expiresIn: REFRESH_EXPIRES_IN }
  );
  return { token, jti };
}

/** 토큰 검증 — 실패 시 null */
export function verifyAccessToken(token: string): JwtPayload | null {
  try {
    const payload = jwt.verify(token, getSecret()) as JwtPayload;
    if (payload.type !== "access" || !payload.sub) return null;
    return payload;
  } catch {
    return null;
  }
}

/** Refresh 토큰 검증 — 실패 시 null */
export function verifyRefreshToken(token: string): (JwtPayload & { jti: string }) | null {
  try {
    const payload = jwt.verify(token, getSecret()) as JwtPayload & { jti?: string };
    if (payload.type !== "refresh" || !payload.sub || !payload.jti) return null;
    return payload as JwtPayload & { jti: string };
  } catch {
    return null;
  }
}

/** Authorization Bearer 또는 쿠키에서 Access 토큰 추출 */
export function getAccessTokenFromRequest(request: Request): string | null {
  const auth = request.headers.get("authorization");
  if (auth?.startsWith("Bearer ")) return auth.slice(7).trim();
  // Cookie: accessToken=...
  const cookie = request.headers.get("cookie");
  if (cookie) {
    const match = cookie.match(/accessToken=([^;]+)/);
    if (match?.[1]) return decodeURIComponent(match[1].trim());
  }
  return null;
}
