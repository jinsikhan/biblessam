import { NextRequest } from "next/server";
import { getCorsHeaders } from "@/lib/security/cors";
import { checkRateLimit, getClientIp, AUTH_RATE_LIMIT } from "@/lib/security/rate-limit";
import { signAccessToken, verifyRefreshToken } from "@/lib/auth/jwt";
import { isBlacklisted } from "@/lib/auth/refresh-blacklist";

export async function POST(request: NextRequest) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);

  const ip = getClientIp(request);
  const { allowed } = checkRateLimit(ip, AUTH_RATE_LIMIT);
  if (!allowed) {
    return Response.json({ success: false, error: "Too many requests" }, { status: 429, headers });
  }

  let body: { refreshToken?: string };
  try {
    body = await request.json();
  } catch {
    return Response.json({ success: false, error: "Invalid JSON" }, { status: 400, headers });
  }

  const refreshToken = typeof body.refreshToken === "string" ? body.refreshToken.trim() : "";
  if (!refreshToken) {
    return Response.json({ success: false, error: "refreshToken is required" }, { status: 400, headers });
  }

  const payload = verifyRefreshToken(refreshToken);
  if (!payload) {
    return Response.json({ success: false, error: "Invalid or expired refresh token" }, { status: 401, headers });
  }

  if (isBlacklisted(payload.jti)) {
    return Response.json({ success: false, error: "Token has been revoked" }, { status: 401, headers });
  }

  let accessToken: string;
  try {
    accessToken = signAccessToken(payload.sub);
  } catch {
    return Response.json(
      { success: false, error: "Server configuration error" },
      { status: 500, headers }
    );
  }

  return Response.json(
    {
      success: true,
      accessToken,
      expiresIn: 3600,
    },
    { headers }
  );
}
