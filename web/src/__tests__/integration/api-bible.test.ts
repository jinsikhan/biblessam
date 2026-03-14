/**
 * 성경 API 통합 테스트
 * API Routes가 올바르게 동작하는지 검증
 */

describe("Bible API Routes", () => {
  const BASE_URL = process.env.TEST_BASE_URL || "http://localhost:3000";

  // API가 실행 중이 아닐 수 있으므로 조건부 실행
  const itIfApi = process.env.TEST_API_RUNNING ? it : it.skip;

  itIfApi("GET /api/daily — 오늘의 말씀을 반환한다", async () => {
    const res = await fetch(`${BASE_URL}/api/daily`);
    expect(res.status).toBe(200);

    const data = await res.json();
    expect(data).toHaveProperty("book");
    expect(data).toHaveProperty("chapter");
  });

  itIfApi("GET /api/bible/books — 성경 책 목록을 반환한다", async () => {
    const res = await fetch(`${BASE_URL}/api/bible/books`);
    expect(res.status).toBe(200);

    const data = await res.json();
    expect(Array.isArray(data.books || data)).toBe(true);
  });

  itIfApi("GET /api/bible/chapter?book=john&chapter=3 — 장 내용을 반환한다", async () => {
    const res = await fetch(`${BASE_URL}/api/bible/chapter?book=john&chapter=3`);
    expect(res.status).toBe(200);

    const data = await res.json();
    expect(data).toHaveProperty("verses");
  });

  itIfApi("GET /api/bible/chapter — 파라미터 없이 400을 반환한다", async () => {
    const res = await fetch(`${BASE_URL}/api/bible/chapter`);
    expect(res.status).toBe(400);
  });

  itIfApi("잘못된 XSS 쿼리에도 안전하게 응답한다", async () => {
    const res = await fetch(`${BASE_URL}/api/bible/search?q=<script>alert(1)</script>`);
    const text = await res.text();
    expect(text).not.toContain("<script>");
  });
});
