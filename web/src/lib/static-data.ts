/**
 * 정적 데이터 로드 (fs 사용 — JSON을 TS에서 import하지 않아 tsc 오류 방지)
 */

import { readFileSync } from "fs";
import { join } from "path";

const DATA_DIR = join(process.cwd(), "src/data");

let bibleBooksCache: Array<{ id: string; nameEn: string; nameKo: string; chapters: number; testament: string }> | null = null;
let emotionThemesCache: Array<{
  id: string;
  labelKo: string;
  labelEn: string;
  refs: Array<{ book: string; chapter: number; verse?: number; highlight: string }>;
}> | null = null;

export function getBibleBooks(): Array<{ id: string; nameEn: string; nameKo: string; chapters: number; testament: string }> {
  if (bibleBooksCache) return bibleBooksCache;
  const raw = readFileSync(join(DATA_DIR, "bible-books.json"), "utf-8");
  bibleBooksCache = JSON.parse(raw) as typeof bibleBooksCache;
  return bibleBooksCache!;
}

export function getEmotionThemes(): Array<{
  id: string;
  labelKo: string;
  labelEn: string;
  refs: Array<{ book: string; chapter: number; verse?: number; highlight: string }>;
}> {
  if (emotionThemesCache) return emotionThemesCache;
  const raw = readFileSync(join(DATA_DIR, "emotion-themes.json"), "utf-8");
  emotionThemesCache = JSON.parse(raw) as typeof emotionThemesCache;
  return emotionThemesCache!;
}
