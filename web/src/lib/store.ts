/**
 * 사용자 데이터 인메모리 저장소 (MVP)
 * 로그인 연동 시 PostgreSQL 등으로 교체
 * 사용자 식별: x-user-id 헤더 또는 Authorization Bearer (JWT sub)
 */

import { getAccessTokenFromRequest, verifyAccessToken } from "@/lib/auth/jwt";

export interface FavoriteItem {
  id: string;
  userId: string;
  book: string;
  chapter: number;
  verseText?: string;
  createdAt: string; // ISO
}

export interface HistoryItem {
  book: string;
  chapter: number;
  readAt: string; // ISO
}

export interface StreakData {
  userId: string;
  lastDate: string; // YYYY-MM-DD
  currentStreak: number;
  totalMinutesToday: number;
  dates: string[]; // YYYY-MM-DD list of read days
}

const favoritesByUser = new Map<string, FavoriteItem[]>();
const historyByUser = new Map<string, HistoryItem[]>();
const streakByUser = new Map<string, StreakData>();
const MAX_HISTORY = 20;

function ensureUser<T>(map: Map<string, T[]>, userId: string): T[] {
  let arr = map.get(userId);
  if (!arr) {
    arr = [];
    map.set(userId, arr);
  }
  return arr;
}

function getOrCreateStreak(userId: string): StreakData {
  let s = streakByUser.get(userId);
  if (!s) {
    s = { userId, lastDate: "", currentStreak: 0, totalMinutesToday: 0, dates: [] };
    streakByUser.set(userId, s);
  }
  return s;
}

export function addFavorite(userId: string, book: string, chapter: number, verseText?: string): FavoriteItem {
  const list = ensureUser(favoritesByUser, userId);
  const id = `fav_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
  const item: FavoriteItem = { id, userId, book, chapter, verseText, createdAt: new Date().toISOString() };
  list.unshift(item);
  return item;
}

export function getFavorites(userId: string): FavoriteItem[] {
  return ensureUser(favoritesByUser, userId).slice();
}

export function deleteFavorite(userId: string, id: string): boolean {
  const list = favoritesByUser.get(userId);
  if (!list) return false;
  const idx = list.findIndex((f) => f.id === id);
  if (idx === -1) return false;
  list.splice(idx, 1);
  return true;
}

export function addHistory(userId: string, book: string, chapter: number): void {
  const list = ensureUser(historyByUser, userId);
  const entry: HistoryItem = { book, chapter, readAt: new Date().toISOString() };
  const existing = list.findIndex((h) => h.book === book && h.chapter === chapter);
  if (existing >= 0) list.splice(existing, 1);
  list.unshift(entry);
  if (list.length > MAX_HISTORY) list.length = MAX_HISTORY;
}

export function getHistory(userId: string): HistoryItem[] {
  return ensureUser(historyByUser, userId).slice();
}

export function recordStreak(userId: string, dateStr: string, minutes: number): StreakData {
  const s = getOrCreateStreak(userId);
  const dates = new Set(s.dates);
  dates.add(dateStr);
  s.dates = Array.from(dates).sort();
  s.totalMinutesToday = dateStr === s.lastDate ? s.totalMinutesToday + minutes : minutes;
  s.lastDate = dateStr;
  let streak = 0;
  const today = new Date().toISOString().slice(0, 10);
  for (let i = s.dates.length - 1; i >= 0; i--) {
    const d = s.dates[i];
    const prev = s.dates[i + 1];
    if (prev) {
      const prevDate = new Date(prev);
      const currDate = new Date(d);
      const diffDays = Math.round((currDate.getTime() - prevDate.getTime()) / 86400000);
      if (diffDays !== 1) break;
    }
    streak++;
    if (d === today) break;
  }
  s.currentStreak = streak;
  return { ...s };
}

export function getStreak(userId: string): StreakData | null {
  return streakByUser.get(userId) || null;
}

/** 동기화: 즐겨찾기 목록 교체 (병합 후 호출) */
export function setFavorites(userId: string, items: Omit<FavoriteItem, "userId">[]): void {
  const list = items.map((f) => ({ ...f, userId }));
  favoritesByUser.set(userId, list);
}

/** 동기화: 최근 읽은 장 교체 (병합 후 호출, 최대 MAX_HISTORY) */
export function setHistory(userId: string, items: HistoryItem[]): void {
  historyByUser.set(userId, items.slice(0, MAX_HISTORY));
}

/** 동기화: 스트릭 데이터 병합 후 저장 (dates 합집합, lastDate/totalMinutesToday는 인자 우선) */
export function setStreakData(
  userId: string,
  data: { dates: string[]; lastDate: string; totalMinutesToday: number }
): StreakData {
  const s = getOrCreateStreak(userId);
  const dates = Array.from(new Set([...s.dates, ...data.dates])).sort();
  s.dates = dates;
  s.lastDate = data.lastDate || s.lastDate;
  s.totalMinutesToday = data.totalMinutesToday;
  let streak = 0;
  const today = new Date().toISOString().slice(0, 10);
  for (let i = dates.length - 1; i >= 0; i--) {
    const d = dates[i];
    const prev = dates[i + 1];
    if (prev) {
      const prevDate = new Date(prev);
      const currDate = new Date(d);
      const diffDays = Math.round((currDate.getTime() - prevDate.getTime()) / 86400000);
      if (diffDays !== 1) break;
    }
    streak++;
    if (d === today) break;
  }
  s.currentStreak = streak;
  return { ...s };
}

/** JWT 검증 기반 userId 추출 (선택적 인증: 비로그인 시 anonymous) */
export function getUserIdFromRequest(request: Request): string {
  const token = getAccessTokenFromRequest(request);
  if (token) {
    const payload = verifyAccessToken(token);
    if (payload?.sub) return String(payload.sub);
  }
  const xUserId = request.headers.get("x-user-id");
  if (xUserId?.trim()) return xUserId.trim().slice(0, 64);
  return "anonymous";
}
