import { NextRequest } from "next/server";
import { getCorsHeaders } from "@/lib/security/cors";
import { checkRateLimit, getClientIp, DEFAULT_CONFIG } from "@/lib/security/rate-limit";
import { getUserIdFromRequest, deleteFavorite } from "@/lib/store";

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);

  const ip = getClientIp(request);
  const { allowed } = checkRateLimit(ip, DEFAULT_CONFIG);
  if (!allowed) {
    return Response.json({ success: false, error: "Too many requests" }, { status: 429, headers });
  }

  const { id } = await params;
  const userId = getUserIdFromRequest(request);
  const deleted = deleteFavorite(userId, id);
  if (!deleted) {
    return Response.json({ success: false, error: "Not found" }, { status: 404, headers });
  }
  return Response.json({ success: true }, { headers });
}
