/**
 * 보안 헤더 테스트
 * OWASP 권장 헤더가 올바르게 설정되었는지 검증
 */
import { SECURITY_HEADERS, applySecurityHeaders } from "@/lib/security/headers";

describe("OWASP 보안 헤더 검증", () => {
  it("필수 보안 헤더가 모두 존재한다", () => {
    const requiredHeaders = [
      "X-XSS-Protection",
      "X-Content-Type-Options",
      "X-Frame-Options",
      "Referrer-Policy",
      "Strict-Transport-Security",
      "Permissions-Policy",
      "Content-Security-Policy",
    ];

    requiredHeaders.forEach((header) => {
      expect(SECURITY_HEADERS).toHaveProperty(header);
    });
  });

  it("X-Frame-Options이 DENY로 설정되어 Clickjacking을 방지한다", () => {
    expect(SECURITY_HEADERS["X-Frame-Options"]).toBe("DENY");
  });

  it("CSP frame-ancestors가 none으로 설정되어 이중 보호한다", () => {
    expect(SECURITY_HEADERS["Content-Security-Policy"]).toContain("frame-ancestors 'none'");
  });

  it("HSTS max-age가 1년 이상이다", () => {
    const match = SECURITY_HEADERS["Strict-Transport-Security"].match(/max-age=(\d+)/);
    expect(match).not.toBeNull();
    expect(parseInt(match![1])).toBeGreaterThanOrEqual(31536000);
  });

  it("CSP default-src가 self로 설정되어 있다", () => {
    expect(SECURITY_HEADERS["Content-Security-Policy"]).toContain("default-src 'self'");
  });

  it("CSP base-uri가 self로 설정되어 base tag injection을 방지한다", () => {
    expect(SECURITY_HEADERS["Content-Security-Policy"]).toContain("base-uri 'self'");
  });

  it("CSP form-action이 self로 설정되어 폼 리다이렉트를 방지한다", () => {
    expect(SECURITY_HEADERS["Content-Security-Policy"]).toContain("form-action 'self'");
  });
});

describe("applySecurityHeaders 통합 테스트", () => {
  it("모든 헤더가 Response에 적용된다", () => {
    const response = new Response("OK");
    applySecurityHeaders(response);

    Object.keys(SECURITY_HEADERS).forEach((key) => {
      expect(response.headers.get(key)).toBe(SECURITY_HEADERS[key]);
    });
  });
});
