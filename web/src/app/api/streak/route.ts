import { NextRequest } from "next/server";
import { getCorsHeaders } from "@/lib/security/cors";
import { checkRateLimit, getClientIp, DEFAULT_CONFIG } from "@/lib/security/rate-limit";
import { getUserIdFromRequest, getStreak, recordStreak } from "@/lib/store";

export async function GET(request: NextRequest) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);

  const ip = getClientIp(request);
  const { allowed } = checkRateLimit(ip, DEFAULT_CONFIG);
  if (!allowed) {
    return Response.json({ success: false, error: "Too many requests" }, { status: 429, headers });
  }

  const userId = getUserIdFromRequest(request);
  const data = getStreak(userId);
  const today = new Date().toISOString().slice(0, 10);
  return Response.json({
    success: true,
    streak: data
      ? {
          currentStreak: data.currentStreak,
          totalMinutesToday: data.totalMinutesToday,
          lastDate: data.lastDate,
          dates: data.dates,
        }
      : { currentStreak: 0, totalMinutesToday: 0, lastDate: null, dates: [] },
    today,
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

  let body: { date?: string; minutes?: number };
  try {
    body = await request.json();
  } catch {
    return Response.json({ success: false, error: "Invalid JSON" }, { status: 400, headers });
  }

  const dateStr = body.date && /^\d{4}-\d{2}-\d{2}$/.test(body.date) ? body.date : new Date().toISOString().slice(0, 10);
  const minutes = typeof body.minutes === "number" && body.minutes >= 0 ? Math.min(body.minutes, 1440) : 10;

  const userId = getUserIdFromRequest(request);
  const data = recordStreak(userId, dateStr, minutes);
  return Response.json({
    success: true,
    streak: {
      currentStreak: data.currentStreak,
      totalMinutesToday: data.totalMinutesToday,
      lastDate: data.lastDate,
    },
  }, { status: 200, headers });
}
