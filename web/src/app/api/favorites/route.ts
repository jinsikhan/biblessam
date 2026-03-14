import { NextRequest } from "next/server";
import { getCorsHeaders } from "@/lib/security/cors";
import { checkRateLimit, getClientIp, DEFAULT_CONFIG } from "@/lib/security/rate-limit";
import { validateBibleRef } from "@/lib/security/sanitize";
import { getUserIdFromRequest, getFavorites, addFavorite } from "@/lib/store";

export async function GET(request: NextRequest) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);

  const ip = getClientIp(request);
  const { allowed } = checkRateLimit(ip, DEFAULT_CONFIG);
  if (!allowed) {
    return Response.json({ success: false, error: "Too many requests" }, { status: 429, headers });
  }

  const userId = getUserIdFromRequest(request);
  const list = getFavorites(userId);
  return Response.json({
    success: true,
    favorites: list.map((f) => ({ id: f.id, book: f.book, chapter: f.chapter, verseText: f.verseText, createdAt: f.createdAt })),
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

  let body: { book?: string; chapter?: number; verseText?: string };
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
  const verseText = typeof body.verseText === "string" ? body.verseText.slice(0, 500) : undefined;
  const item = addFavorite(userId, safeBook, safeChapter, verseText);
  return Response.json({
    success: true,
    favorite: { id: item.id, book: item.book, chapter: item.chapter, verseText: item.verseText, createdAt: item.createdAt },
  }, { status: 201, headers });
}
