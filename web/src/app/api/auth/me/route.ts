import { NextRequest } from "next/server";
import { getCorsHeaders } from "@/lib/security/cors";
import { checkRateLimit, getClientIp, AUTH_RATE_LIMIT } from "@/lib/security/rate-limit";
import { getAuthFromRequest } from "@/lib/auth/with-auth";

export async function GET(request: NextRequest) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);

  const ip = getClientIp(request);
  const { allowed } = checkRateLimit(ip, AUTH_RATE_LIMIT);
  if (!allowed) {
    return Response.json({ success: false, error: "Too many requests" }, { status: 429, headers });
  }

  const { userId, user } = getAuthFromRequest(request);

  if (!user) {
    return Response.json(
      { success: true, user: null, message: "Not logged in" },
      { headers }
    );
  }

  return Response.json(
    {
      success: true,
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
