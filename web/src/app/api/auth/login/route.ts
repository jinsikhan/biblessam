import { NextRequest } from "next/server";
import { getCorsHeaders } from "@/lib/security/cors";
import { checkRateLimit, getClientIp, AUTH_RATE_LIMIT } from "@/lib/security/rate-limit";
import { signAccessToken, signRefreshToken } from "@/lib/auth/jwt";
import { findOrCreateUser } from "@/lib/auth/users";
import { verifySocialToken } from "@/lib/auth/social-verify";

export async function POST(request: NextRequest) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);

  const ip = getClientIp(request);
  const { allowed } = checkRateLimit(ip, AUTH_RATE_LIMIT);
  if (!allowed) {
    return Response.json({ success: false, error: "Too many requests" }, { status: 429, headers });
  }

  let body: { provider?: string; token?: string };
  try {
    body = await request.json();
  } catch {
    return Response.json({ success: false, error: "Invalid JSON" }, { status: 400, headers });
  }

  const provider = body.provider as "google" | "kakao" | "apple" | undefined;
  const token = typeof body.token === "string" ? body.token.trim() : "";

  if (!provider || !["google", "kakao", "apple"].includes(provider) || !token) {
    return Response.json(
      { success: false, error: "provider (google|kakao|apple) and token are required" },
      { status: 400, headers }
    );
  }

  const profile = verifySocialToken(provider, token);
  if (!profile) {
    return Response.json({ success: false, error: "Invalid or expired token" }, { status: 401, headers });
  }

  const user = findOrCreateUser({
    provider,
    providerId: profile.providerId,
    email: profile.email,
    displayName: profile.displayName,
    profileImage: profile.profileImage,
  });

  let accessToken: string;
  let refreshToken: string;
  try {
    accessToken = signAccessToken(user.id);
    const ref = signRefreshToken(user.id);
    refreshToken = ref.token;
  } catch (e) {
    return Response.json(
      { success: false, error: "Server configuration error" },
      { status: 500, headers }
    );
  }

  return Response.json(
    {
      success: true,
      accessToken,
      refreshToken,
      expiresIn: 3600,
      user: {
        id: user.id,
        provider: user.provider,
        email: user.email,
        displayName: user.displayName,
        profileImage: user.profileImage,
      },
    },
    { headers }
  );
}
