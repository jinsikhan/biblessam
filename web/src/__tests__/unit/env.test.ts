import { validateEnv } from "@/lib/security/env";

describe("validateEnv", () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv };
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  it("AI 키가 없으면 경고를 반환한다", () => {
    delete process.env.GEMINI_API_KEY;
    delete process.env.OPENROUTER_API_KEY;
    delete process.env.GROQ_API_KEY;

    const result = validateEnv();
    expect(result.warnings.length).toBeGreaterThan(0);
    expect(result.warnings[0]).toContain("AI API 키");
  });

  it("AI 키가 있으면 경고가 없다", () => {
    process.env.GEMINI_API_KEY = "test-key";

    const result = validateEnv();
    const aiWarnings = result.warnings.filter((w) => w.includes("AI API 키"));
    expect(aiWarnings.length).toBe(0);
  });

  it("NEXT_PUBLIC_ 접두어로 민감 변수가 노출되면 에러를 반환한다", () => {
    process.env.NEXT_PUBLIC_GEMINI_API_KEY = "exposed-key";

    const result = validateEnv();
    expect(result.valid).toBe(false);
    expect(result.errors.length).toBeGreaterThan(0);
    expect(result.errors[0]).toContain("보안 위반");
  });

  it("JWT_SECRET이 32자 미만이면 경고를 반환한다", () => {
    process.env.JWT_SECRET = "short";

    const result = validateEnv();
    const jwtWarnings = result.warnings.filter((w) => w.includes("JWT_SECRET"));
    expect(jwtWarnings.length).toBeGreaterThan(0);
  });

  it("모든 조건이 충족되면 valid가 true이다", () => {
    process.env.GEMINI_API_KEY = "test-key";
    process.env.JWT_SECRET = "a".repeat(64);
    // NEXT_PUBLIC_ 접두어 민감 변수 없음

    const result = validateEnv();
    expect(result.valid).toBe(true);
    expect(result.errors.length).toBe(0);
  });
});
