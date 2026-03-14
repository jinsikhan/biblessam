import { NextRequest } from "next/server";
import { getCorsHeaders } from "@/lib/security/cors";
import { checkRateLimit, getClientIp, DEFAULT_CONFIG } from "@/lib/security/rate-limit";
import { validateBibleRef } from "@/lib/security/sanitize";
import { getUserIdFromRequest, getHistory, addHistory } from "@/lib/store";

export async function GET(request: NextRequest) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);

  const ip = getClientIp(request);
  const { allowed } = checkRateLimit(ip, DEFAULT_CONFIG);
  if (!allowed) {
    return Response.json({ success: false, error: "Too many requests" }, { status: 429, headers });
  }

  const userId = getUserIdFromRequest(request);
  const list = getHistory(userId);
  return Response.json({
    success: true,
    history: list.map((h) => ({ book: h.book, chapter: h.chapter, readAt: h.readAt })),
  }, { headers });
}

export async function POST(request: NextRequest) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);

  const ip = getClientIp(request);
  const { allowed } = checkRateLimit(ip, DEFAULT_CONFIG);
  if (!allowed) {
    return Response.json({ success: false, error: "Too many requests" }, { status: 429, headers });
  }

  let body: { book?: string; chapter?: number };
  try {
    body = await request.json();
  } catch {
    return Response.json({ success: false, error: "Invalid JSON" }, { status: 400, headers });
  }

  const { valid, book: safeBook, chapter: safeChapter } = validateBibleRef(
    String(body.book ?? ""),
    String(body.chapter ?? "")
  );
  if (!valid) {
    return Response.json({ success: false, error: "Invalid book or chapter" }, { status: 400, headers });
  }

  const userId = getUserIdFromRequest(request);
  addHistory(userId, safeBook, safeChapter);
  return Response.json({ success: true }, { status: 201, headers });
}
