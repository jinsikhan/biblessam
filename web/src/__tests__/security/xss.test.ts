/**
 * XSS 보안 테스트
 * 다양한 XSS 공격 벡터에 대한 방어 검증
 */
import { escapeHtml, sanitizeSearchQuery, sanitizeString } from "@/lib/security/sanitize";

describe("XSS 방어 테스트", () => {
  const XSS_PAYLOADS = [
    '<script>alert("xss")</script>',
    '<img src=x onerror=alert(1)>',
    '<svg onload=alert(1)>',
    'javascript:alert(1)',
    '<iframe src="javascript:alert(1)">',
    '"><script>alert(1)</script>',
    "'-alert(1)-'",
    '<body onload=alert(1)>',
    '<input onfocus=alert(1) autofocus>',
    '<marquee onstart=alert(1)>',
    '<div style="background:url(javascript:alert(1))">',
    '{{constructor.constructor("alert(1)")()}}',
  ];

  describe("escapeHtml은 모든 XSS 페이로드를 무력화한다", () => {
    XSS_PAYLOADS.forEach((payload, i) => {
      it(`페이로드 #${i + 1}: ${payload.slice(0, 40)}...`, () => {
        const escaped = escapeHtml(payload);
        expect(escaped).not.toContain("<script");
        expect(escaped).not.toContain("<img");
        expect(escaped).not.toContain("<svg");
        expect(escaped).not.toContain("<iframe");
        expect(escaped).not.toContain("<body");
        expect(escaped).not.toContain("<input");
      });
    });
  });

  describe("sanitizeSearchQuery는 위험한 문자를 제거한다", () => {
    it("HTML 태그를 제거한다", () => {
      expect(sanitizeSearchQuery('<script>alert(1)</script>')).not.toContain("<");
      expect(sanitizeSearchQuery('<script>alert(1)</script>')).not.toContain(">");
    });

    it("한글과 영문만 남긴다", () => {
      const result = sanitizeSearchQuery("요한복음<script> 3장");
      expect(result).toContain("요한복음");
      expect(result).toContain("3장");
      expect(result).not.toContain("<");
    });
  });

  describe("sanitizeString은 제어문자를 제거한다", () => {
    it("NULL 바이트를 제거한다", () => {
      expect(sanitizeString("hello\x00world")).not.toContain("\x00");
    });

    it("다른 제어문자를 제거한다", () => {
      const result = sanitizeString("hello\x01\x02\x03world");
      expect(result).toBe("helloworld");
    });
  });
});
