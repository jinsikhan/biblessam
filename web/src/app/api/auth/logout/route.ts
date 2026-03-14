import { NextRequest } from "next/server";
import { getCorsHeaders } from "@/lib/security/cors";
import { checkRateLimit, getClientIp, AUTH_RATE_LIMIT } from "@/lib/security/rate-limit";
import { verifyRefreshToken } from "@/lib/auth/jwt";
import { addToBlacklist } from "@/lib/auth/refresh-blacklist";

export async function POST(request: NextRequest) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);

  const ip = getClientIp(request);
  const { allowed } = checkRateLimit(ip, AUTH_RATE_LIMIT);
  if (!allowed) {
    return Response.json({ success: false, error: "Too many requests" }, { status: 429, headers });
  }

  let body: { refreshToken?: string } = {};
  try {
    body = await request.json();
  } catch {
    // body 없어도 200 — 클라이언트는 로컬에서 토큰 삭제하면 됨
  }

  const refreshToken = typeof body.refreshToken === "string" ? body.refreshToken.trim() : "";
  if (refreshToken) {
    const payload = verifyRefreshToken(refreshToken);
    if (payload) {
      addToBlacklist(payload.jti);
    }
  }

  return Response.json(
    { success: true, message: "Logged out. Discard tokens on client." },
    { headers }
  );
}
