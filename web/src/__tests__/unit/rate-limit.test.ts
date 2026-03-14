import { checkRateLimit, getClientIp, AI_RATE_LIMIT, AUTH_RATE_LIMIT } from "@/lib/security/rate-limit";

describe("checkRateLimit", () => {
  it("첫 번째 요청은 허용된다", () => {
    const result = checkRateLimit("test-first-request");
    expect(result.allowed).toBe(true);
    expect(result.remaining).toBeGreaterThan(0);
  });

  it("제한 초과 시 차단한다", () => {
    const id = "test-rate-limit-exceed-" + Date.now();
    const config = { maxRequests: 3, windowMs: 60_000 };

    checkRateLimit(id, config); // 1
    checkRateLimit(id, config); // 2
    checkRateLimit(id, config); // 3
    const result = checkRateLimit(id, config); // 4 → 차단

    expect(result.allowed).toBe(false);
    expect(result.remaining).toBe(0);
  });

  it("remaining 카운트가 정확하다", () => {
    const id = "test-remaining-" + Date.now();
    const config = { maxRequests: 5, windowMs: 60_000 };

    const r1 = checkRateLimit(id, config);
    expect(r1.remaining).toBe(4);

    const r2 = checkRateLimit(id, config);
    expect(r2.remaining).toBe(3);
  });

  it("AI_RATE_LIMIT 설정이 올바르다", () => {
    expect(AI_RATE_LIMIT.maxRequests).toBe(5);
    expect(AI_RATE_LIMIT.windowMs).toBe(60_000);
  });

  it("AUTH_RATE_LIMIT 설정이 올바르다", () => {
    expect(AUTH_RATE_LIMIT.maxRequests).toBe(10);
    expect(AUTH_RATE_LIMIT.windowMs).toBe(60_000);
  });
});

describe("getClientIp", () => {
  it("x-forwarded-for 헤더에서 IP를 추출한다", () => {
    const request = new Request("http://localhost", {
      headers: { "x-forwarded-for": "1.2.3.4, 5.6.7.8" },
    });
    expect(getClientIp(request)).toBe("1.2.3.4");
  });

  it("x-real-ip 헤더에서 IP를 추출한다", () => {
    const request = new Request("http://localhost", {
      headers: { "x-real-ip": "10.0.0.1" },
    });
    expect(getClientIp(request)).toBe("10.0.0.1");
  });

  it("헤더가 없으면 unknown을 반환한다", () => {
    const request = new Request("http://localhost");
    expect(getClientIp(request)).toBe("unknown");
  });
});
