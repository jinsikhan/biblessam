import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { handleCors, getCorsHeaders } from "@/lib/security/cors";

export function middleware(request: NextRequest) {
  const corsResponse = handleCors(request);
  if (corsResponse) return corsResponse;

  const response = NextResponse.next();
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);
  Object.entries(headers).forEach(([key, value]) => {
    response.headers.set(key, value);
  });
  return response;
}

export const config = {
  matcher: "/api/:path*",
};
