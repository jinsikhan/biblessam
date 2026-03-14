import { escapeHtml, sanitizeSearchQuery, validateBibleRef, sanitizeString } from "@/lib/security/sanitize";

describe("escapeHtml", () => {
  it("HTML 특수문자를 이스케이프한다", () => {
    expect(escapeHtml("<script>alert('xss')</script>")).toBe(
      "&lt;script&gt;alert(&#x27;xss&#x27;)&lt;&#x2F;script&gt;"
    );
  });

  it("일반 문자열은 변경하지 않는다", () => {
    expect(escapeHtml("Hello World")).toBe("Hello World");
  });

  it("빈 문자열을 처리한다", () => {
    expect(escapeHtml("")).toBe("");
  });

  it("모든 특수문자를 이스케이프한다", () => {
    expect(escapeHtml('&<>"\'/'))
      .toBe("&amp;&lt;&gt;&quot;&#x27;&#x2F;");
  });
});

describe("sanitizeSearchQuery", () => {
  it("한글 검색어를 허용한다", () => {
    expect(sanitizeSearchQuery("요한복음 3장")).toBe("요한복음 3장");
  });

  it("200자 초과 시 잘라낸다", () => {
    const long = "가".repeat(250);
    expect(sanitizeSearchQuery(long).length).toBe(200);
  });

  it("특수문자를 제거한다", () => {
    expect(sanitizeSearchQuery("test<script>")).not.toContain("<");
    expect(sanitizeSearchQuery("test<script>")).not.toContain(">");
  });

  it("앞뒤 공백을 제거한다", () => {
    expect(sanitizeSearchQuery("  hello  ")).toBe("hello");
  });
});

describe("validateBibleRef", () => {
  it("유효한 참조를 검증한다", () => {
    const result = validateBibleRef("John", "3");
    expect(result.valid).toBe(true);
    expect(result.book).toBe("John");
    expect(result.chapter).toBe(3);
  });

  it("한글 책명을 허용한다", () => {
    const result = validateBibleRef("창세기", "1");
    expect(result.valid).toBe(true);
    expect(result.book).toBe("창세기");
  });

  it("유효하지 않은 장 번호를 거부한다", () => {
    expect(validateBibleRef("John", "0").valid).toBe(false);
    expect(validateBibleRef("John", "151").valid).toBe(false);
    expect(validateBibleRef("John", "abc").valid).toBe(false);
  });

  it("빈 책명을 거부한다", () => {
    expect(validateBibleRef("", "1").valid).toBe(false);
  });

  it("책명의 특수문자를 제거한다", () => {
    const result = validateBibleRef("John<script>", "3");
    expect(result.book).not.toContain("<");
  });
});

describe("sanitizeString", () => {
  it("제어문자를 제거한다", () => {
    expect(sanitizeString("hello\x00world")).toBe("helloworld");
  });

  it("최대 길이를 적용한다", () => {
    const long = "a".repeat(1000);
    expect(sanitizeString(long, 100).length).toBe(100);
  });

  it("기본 최대 길이는 500자이다", () => {
    const long = "a".repeat(600);
    expect(sanitizeString(long).length).toBe(500);
  });
});
