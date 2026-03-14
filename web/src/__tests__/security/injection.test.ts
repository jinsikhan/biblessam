/**
 * 인젝션 보안 테스트
 * 입력 살균이 위험한 특수문자를 제거하는지 검증
 * 참고: SQL Injection 방어는 parameterized queries가 담당, sanitize는 특수문자 제거가 목적
 */
import { sanitizeSearchQuery, validateBibleRef, sanitizeString } from "@/lib/security/sanitize";

describe("sanitizeSearchQuery — 특수문자 제거", () => {
  it("중괄호와 각괄호를 제거한다", () => {
    expect(sanitizeSearchQuery("test{key}[0]")).not.toContain("{");
    expect(sanitizeSearchQuery("test{key}[0]")).not.toContain("}");
    expect(sanitizeSearchQuery("test{key}[0]")).not.toContain("[");
    expect(sanitizeSearchQuery("test{key}[0]")).not.toContain("]");
  });

  it("등호를 제거한다", () => {
    expect(sanitizeSearchQuery("1 OR 1=1")).not.toContain("=");
  });

  it("별표(*)를 제거한다", () => {
    expect(sanitizeSearchQuery("SELECT * FROM")).not.toContain("*");
  });

  it("백슬래시를 제거한다", () => {
    expect(sanitizeSearchQuery("test\\ninjection")).not.toContain("\\");
  });

  it("꺾쇠괄호를 제거한다 (XSS 방어)", () => {
    const result = sanitizeSearchQuery("<script>alert(1)</script>");
    expect(result).not.toContain("<");
    expect(result).not.toContain(">");
  });

  it("한글+영문+숫자+기본 구두점만 허용한다", () => {
    const result = sanitizeSearchQuery("요한복음 3장 hello! world? test.");
    expect(result).toContain("요한복음");
    expect(result).toContain("3장");
    expect(result).toContain("hello");
  });

  it("200자로 제한한다", () => {
    const long = "a".repeat(300);
    expect(sanitizeSearchQuery(long).length).toBeLessThanOrEqual(200);
  });
});

describe("sanitizeString — 제어문자 제거", () => {
  it("NULL 바이트를 제거한다", () => {
    expect(sanitizeString("hello\x00world")).not.toContain("\x00");
  });

  it("제어문자(0x01-0x08)를 제거한다", () => {
    const result = sanitizeString("hello\x01\x02\x03world");
    expect(result).toBe("helloworld");
  });

  it("탭과 줄바꿈은 유지한다", () => {
    // \t (0x09), \n (0x0A), \r (0x0D) 는 제어문자지만 일반적으로 사용됨
    const result = sanitizeString("hello\tworld\n");
    expect(result).toContain("\t");
  });

  it("길이 제한을 적용한다", () => {
    const result = sanitizeString("a".repeat(1000), 100);
    expect(result.length).toBe(100);
  });
});

describe("validateBibleRef — 참조 파라미터 검증", () => {
  it("책명에서 특수문자를 제거한다", () => {
    const result = validateBibleRef("John<script>", "3");
    expect(result.book).not.toContain("<");
    expect(result.book).not.toContain(">");
  });

  it("책명에서 숫자와 특수문자를 제거하고 문자만 남긴다", () => {
    const result = validateBibleRef("John'; DROP--", "3");
    expect(result.book).not.toContain("'");
    expect(result.book).not.toContain(";");
  });

  it("유효하지 않은 장 번호를 거부한다", () => {
    expect(validateBibleRef("시편", "0").valid).toBe(false);
    expect(validateBibleRef("시편", "-1").valid).toBe(false);
    expect(validateBibleRef("시편", "999").valid).toBe(false);
    expect(validateBibleRef("시편", "abc").valid).toBe(false);
  });

  it("유효한 장 번호 범위를 허용한다 (1~150)", () => {
    expect(validateBibleRef("시편", "1").valid).toBe(true);
    expect(validateBibleRef("시편", "150").valid).toBe(true);
    expect(validateBibleRef("시편", "75").valid).toBe(true);
  });

  it("빈 책명을 거부한다", () => {
    expect(validateBibleRef("", "1").valid).toBe(false);
  });

  it("책명 길이를 50자로 제한한다", () => {
    const longName = "가".repeat(100);
    const result = validateBibleRef(longName, "1");
    expect(result.book.length).toBeLessThanOrEqual(50);
  });
});
