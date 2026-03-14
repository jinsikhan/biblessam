import { SECURITY_HEADERS, applySecurityHeaders } from "@/lib/security/headers";

describe("SECURITY_HEADERS", () => {
  it("XSS 보호 헤더가 설정되어 있다", () => {
    expect(SECURITY_HEADERS["X-XSS-Protection"]).toBe("1; mode=block");
  });

  it("MIME 스니핑 방지 헤더가 설정되어 있다", () => {
    expect(SECURITY_HEADERS["X-Content-Type-Options"]).toBe("nosniff");
  });

  it("클릭재킹 방지 헤더가 설정되어 있다", () => {
    expect(SECURITY_HEADERS["X-Frame-Options"]).toBe("DENY");
  });

  it("HSTS 헤더가 설정되어 있다", () => {
    expect(SECURITY_HEADERS["Strict-Transport-Security"]).toContain("max-age=");
  });

  it("CSP 헤더가 설정되어 있다", () => {
    const csp = SECURITY_HEADERS["Content-Security-Policy"];
    expect(csp).toContain("default-src 'self'");
    expect(csp).toContain("frame-ancestors 'none'");
  });

  it("CSP에서 AI API 도메인을 허용한다", () => {
    const csp = SECURITY_HEADERS["Content-Security-Policy"];
    expect(csp).toContain("generativelanguage.googleapis.com");
    expect(csp).toContain("openrouter.ai");
    expect(csp).toContain("api.groq.com");
  });

  it("Permissions-Policy에서 불필요한 API를 차단한다", () => {
    expect(SECURITY_HEADERS["Permissions-Policy"]).toContain("camera=()");
    expect(SECURITY_HEADERS["Permissions-Policy"]).toContain("microphone=()");
  });
});

describe("applySecurityHeaders", () => {
  it("Response에 보안 헤더를 추가한다", () => {
    const response = new Response("OK");
    applySecurityHeaders(response);

    expect(response.headers.get("X-XSS-Protection")).toBe("1; mode=block");
    expect(response.headers.get("X-Content-Type-Options")).toBe("nosniff");
    expect(response.headers.get("X-Frame-Options")).toBe("DENY");
  });
});
