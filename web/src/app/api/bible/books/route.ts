import { NextRequest } from "next/server";
import { getCorsHeaders } from "@/lib/security/cors";
import { getBibleBooks } from "@/lib/static-data";

export async function GET(request: NextRequest) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);
  const books = getBibleBooks();
  return Response.json({ success: true, books }, { headers });
}
