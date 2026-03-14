import { NextRequest } from "next/server";
import { getCorsHeaders } from "@/lib/security/cors";
import { checkRateLimit, getClientIp, DEFAULT_CONFIG } from "@/lib/security/rate-limit";
import { validateBibleRef } from "@/lib/security/sanitize";
import { getAuthFromRequest } from "@/lib/auth/with-auth";
import {
  getFavorites,
  getHistory,
  getStreak,
  setFavorites,
  setHistory,
  setStreakData,
  type FavoriteItem,
  type HistoryItem,
} from "@/lib/store";

const MAX_HISTORY = 20;

export async function POST(request: NextRequest) {
  const origin = request.headers.get("origin");
  const headers = getCorsHeaders(origin);

  const ip = getClientIp(request);
  const { allowed } = checkRateLimit(ip, DEFAULT_CONFIG);
  if (!allowed) {
    return Response.json({ success: false, error: "Too many requests" }, { status: 429, headers });
  }

  const { userId, user } = getAuthFromRequest(request);
  if (!user) {
    return Response.json(
      { success: false, error: "Authentication required" },
      { status: 401, headers }
    );
  }

  let body: {
    favorites?: Array<{ id?: string; book: string; chapter: number; verseText?: string; createdAt?: string }>;
    history?: Array<{ book: string; chapter: number; readAt: string }>;
    streak?: { dates?: string[]; lastDate?: string; totalMinutesToday?: number };
  };
  try {
    body = await request.json();
  } catch {
    return Response.json({ success: false, error: "Invalid JSON" }, { status: 400, headers });
  }

  const serverFavorites = getFavorites(userId);
  const serverHistory = getHistory(userId);
  const serverStreak = getStreak(userId);

  // 즐겨찾기: 서버 + 클라이언트 합치기, (book, chapter) 기준 중복 제거
  const favMap = new Map<string, FavoriteItem>();
  for (const f of serverFavorites) {
    favMap.set(`${f.book}:${f.chapter}`, { ...f, userId });
  }
  const clientFavorites = Array.isArray(body.favorites) ? body.favorites : [];
  for (const f of clientFavorites) {
    const { valid, book: safeBook, chapter: safeChapter } = validateBibleRef(
      String(f.book ?? ""),
      String(f.chapter ?? "")
    );
    if (!valid) continue;
    const key = `${safeBook}:${safeChapter}`;
    if (!favMap.has(key)) {
      const id = f.id ?? `fav_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
      favMap.set(key, {
        id,
        userId,
        book: safeBook,
        chapter: safeChapter,
        verseText: typeof f.verseText === "string" ? f.verseText.slice(0, 500) : undefined,
        createdAt: typeof f.createdAt === "string" ? f.createdAt : new Date().toISOString(),
      });
    }
  }
  const mergedFavorites = Array.from(favMap.values()).sort(
    (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
  );
  setFavorites(
    userId,
    mergedFavorites.map(({ id, book, chapter, verseText, createdAt }) => ({
      id,
      book,
      chapter,
      verseText,
      createdAt,
    }))
  );

  // 최근 읽은 장: 서버 + 클라이언트 합쳐서 readAt 기준 정렬, 상위 20개
  const historyMap = new Map<string, HistoryItem>();
  for (const h of serverHistory) {
    historyMap.set(`${h.book}:${h.chapter}`, h);
  }
  const clientHistory = Array.isArray(body.history) ? body.history : [];
  for (const h of clientHistory) {
    const { valid, book: safeBook, chapter: safeChapter } = validateBibleRef(
      String(h.book ?? ""),
      String(h.chapter ?? "")
    );
    if (!valid) continue;
    const key = `${safeBook}:${safeChapter}`;
    const existing = historyMap.get(key);
    const readAt = typeof h.readAt === "string" ? h.readAt : new Date().toISOString();
    if (!existing || new Date(readAt) > new Date(existing.readAt)) {
      historyMap.set(key, { book: safeBook, chapter: safeChapter, readAt });
    }
  }
  const mergedHistory = Array.from(historyMap.values())
    .sort((a, b) => new Date(b.readAt).getTime() - new Date(a.readAt).getTime())
    .slice(0, MAX_HISTORY);
  setHistory(userId, mergedHistory);

  // 스트릭: dates 합집합, lastDate/totalMinutesToday는 더 큰 쪽 우선
  const serverDates = serverStreak?.dates ?? [];
  const clientDates = Array.isArray(body.streak?.dates) ? body.streak.dates : [];
  const allDates = Array.from(new Set([...serverDates, ...clientDates])).filter((d) =>
    /^\d{4}-\d{2}-\d{2}$/.test(d)
  );
  const lastDateServer = serverStreak?.lastDate ?? "";
  const lastDateClient = typeof body.streak?.lastDate === "string" ? body.streak.lastDate : "";
  const lastDate =
    !lastDateServer && !lastDateClient
      ? ""
      : !lastDateServer
        ? lastDateClient
        : !lastDateClient
          ? lastDateServer
          : lastDateServer >= lastDateClient
            ? lastDateServer
            : lastDateClient;
  const today = new Date().toISOString().slice(0, 10);
  const minutesServer = serverStreak?.totalMinutesToday ?? 0;
  const minutesClient =
    typeof body.streak?.totalMinutesToday === "number" && body.streak.totalMinutesToday >= 0
      ? Math.min(body.streak.totalMinutesToday, 1440)
      : 0;
  const totalMinutesToday = lastDate === today ? Math.max(minutesServer, minutesClient) : 0;

  setStreakData(userId, {
    dates: allDates,
    lastDate: lastDate || today,
    totalMinutesToday,
  });

  return Response.json(
    {
      success: true,
      message: "Sync complete",
      counts: {
        favorites: mergedFavorites.length,
        history: mergedHistory.length,
        streakDays: allDates.length,
      },
    },
    { headers }
  );
}
