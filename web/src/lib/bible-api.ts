/**
 * bible-api.com 연동
 * Rate limit: 15 req / 30초 (IP 기준) — 요청 간 throttle 적용
 */

const BIBLE_API_BASE = "https://bible-api.com";
const RATE_LIMIT_REQUESTS = 15;
const RATE_LIMIT_WINDOW_MS = 30_000;

const requestTimestamps: number[] = [];

function waitForRateLimit(): Promise<void> {
  const now = Date.now();
  const windowStart = now - RATE_LIMIT_WINDOW_MS;
  const recent = requestTimestamps.filter((t) => t > windowStart);
  if (recent.length >= RATE_LIMIT_REQUESTS) {
    const oldestInWindow = Math.min(...recent);
    const waitMs = oldestInWindow + RATE_LIMIT_WINDOW_MS - now + 100;
    return new Promise((resolve) => setTimeout(resolve, Math.max(waitMs, 0)));
  }
  return Promise.resolve();
}

function recordRequest(): void {
  const now = Date.now();
  requestTimestamps.push(now);
  const windowStart = now - RATE_LIMIT_WINDOW_MS;
  while (requestTimestamps.length > 0 && requestTimestamps[0] < windowStart) {
    requestTimestamps.shift();
  }
}

export interface BibleVerse {
  verse: number;
  text: string;
}

export interface BibleChapterResponse {
  reference: string;
  book: string;
  chapter: number;
  verses: BibleVerse[];
  text: string;
}

interface BibleApiVerse {
  book_id: string;
  book_name: string;
  chapter: number;
  verse: number;
  text: string;
}

interface BibleApiResponse {
  reference: string;
  verses: BibleApiVerse[];
  text: string;
  translation_id?: string;
  translation_name?: string;
}

/** API 경로용 책명: 소문자, 공백/언더스코어는 + (예: 1 john, 1_john → 1+john) */
function toApiBookName(book: string): string {
  return book
    .trim()
    .toLowerCase()
    .replace(/_/g, " ")
    .replace(/\s+/g, " ")
    .trim()
    .replace(/\s+/g, "+")
    .replace(/[^a-z0-9+]/g, "");
}

/**
 * 장 본문 조회
 * @param book - 영문 책명 (예: john, 1 john)
 * @param chapter - 장 번호 (1~150)
 */
export async function fetchChapter(
  book: string,
  chapter: number
): Promise<BibleChapterResponse | null> {
  if (chapter < 1 || chapter > 150) return null;
  const path = `${toApiBookName(book)}+${chapter}`;
  const url = `${BIBLE_API_BASE}/${encodeURIComponent(path)}`;

  await waitForRateLimit();
  recordRequest();

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15_000);

  try {
    const res = await fetch(url, { signal: controller.signal });
    clearTimeout(timeout);
    if (!res.ok) return null;
    const data: BibleApiResponse = await res.json();
    if (!data.verses || !Array.isArray(data.verses)) return null;
    return {
      reference: data.reference || `${book} ${chapter}`,
      book: data.verses[0]?.book_name || book,
      chapter: data.verses[0]?.chapter ?? chapter,
      verses: data.verses.map((v) => ({ verse: v.verse, text: v.text.trim() })),
      text: (data.text || "").trim(),
    };
  } catch {
    clearTimeout(timeout);
    return null;
  }
}

/**
 * 검색 쿼리에서 책+장 파싱 (참조 검색)
 * 지원 형식: "John 3", "john 3", "요한복음 3", "요한복음 3장", "시편 23"
 * 한글 책명은 book-name-map과 매칭 필요
 */
export function parseReference(query: string): { book: string; chapter: number } | null {
  const q = query.trim();
  // 영문: "1 John 3" or "John 3"
  const enMatch = q.match(/^\s*(\d?\s*[a-zA-Z]+)\s+(\d+)\s*$/);
  if (enMatch) {
    const book = enMatch[1].trim().toLowerCase().replace(/\s+/g, " ");
    const chapter = parseInt(enMatch[2], 10);
    if (chapter >= 1 && chapter <= 150) return { book, chapter };
  }
  // 한글: "요한복음 3" or "요한복음 3장" or "시편 23"
  const koMatch = q.match(/^(.+?)\s*(\d+)\s*장?\s*$/);
  if (koMatch) {
    const koBook = koMatch[1].trim();
    const chapter = parseInt(koMatch[2], 10);
    if (chapter >= 1 && chapter <= 150) {
      const enBook = koreanBookToEnglish(koBook);
      if (enBook) return { book: enBook, chapter };
    }
  }
  return null;
}

/** 한글 책명 → 영문 (bible-api.com용) */
function koreanBookToEnglish(ko: string): string | null {
  const map: Record<string, string> = {
    창세기: "genesis",
    출애굽기: "exodus",
    레위기: "leviticus",
    민수기: "numbers",
    신명기: "deuteronomy",
    여호수아: "joshua",
    사사기: "judges",
    룻기: "ruth",
    사무엘상: "1 samuel",
    사무엘하: "2 samuel",
    열왕기상: "1 kings",
    열왕기하: "2 kings",
    역대상: "1 chronicles",
    역대하: "2 chronicles",
    에스라: "ezra",
    느헤미야: "nehemiah",
    에스더: "esther",
    욥기: "job",
    시편: "psalms",
    잠언: "proverbs",
    전도서: "ecclesiastes",
    아가: "song of solomon",
    이사야: "isaiah",
    예레미야: "jeremiah",
    예레미야애가: "lamentations",
    에스겔: "ezekiel",
    다니엘: "daniel",
    호세아: "hosea",
    요엘: "joel",
    아모스: "amos",
    오바댜: "obadiah",
    요나: "jonah",
    미가: "micah",
    나훔: "nahum",
    하박국: "habakkuk",
    스바냐: "zephaniah",
    학개: "haggai",
    스가랴: "zechariah",
    말라기: "malachi",
    마태복음: "matthew",
    마가복음: "mark",
    누가복음: "luke",
    요한복음: "john",
    사도행전: "acts",
    로마서: "romans",
    고린도전서: "1 corinthians",
    고린도후서: "2 corinthians",
    갈라디아서: "galatians",
    에베소서: "ephesians",
    빌립보서: "philippians",
    골로새서: "colossians",
    데살로니가전서: "1 thessalonians",
    데살로니가후서: "2 thessalonians",
    디모데전서: "1 timothy",
    디모데후서: "2 timothy",
    디도서: "titus",
    빌레몬서: "philemon",
    히브리서: "hebrews",
    야고보서: "james",
    베드로전서: "1 peter",
    베드로후서: "2 peter",
    요한일서: "1 john",
    요한이서: "2 john",
    요한삼서: "3 john",
    유다서: "jude",
    요한계시록: "revelation",
  };
  const normalized = ko.replace(/\s/g, "");
  for (const [k, v] of Object.entries(map)) {
    if (k === normalized || k.replace(/\s/g, "") === normalized) return v;
  }
  return null;
}
