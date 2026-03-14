import { handleCors, getCorsHeaders } from "@/lib/security/cors";

describe("handleCors", () => {
  it("OPTIONS 요청에 204 응답을 반환한다", () => {
    const request = new Request("http://localhost:3000/api/test", {
      method: "OPTIONS",
      headers: { origin: "http://localhost:3000" },
    });
    const response = handleCors(request);
    expect(response).not.toBeNull();
    expect(response!.status).toBe(204);
  });

  it("GET 요청에는 null을 반환한다", () => {
    const request = new Request("http://localhost:3000/api/test", {
      method: "GET",
      headers: { origin: "http://localhost:3000" },
    });
    expect(handleCors(request)).toBeNull();
  });

  it("POST 요청에는 null을 반환한다", () => {
    const request = new Request("http://localhost:3000/api/test", {
      method: "POST",
      headers: { origin: "http://localhost:3000" },
    });
    expect(handleCors(request)).toBeNull();
  });
});

describe("getCorsHeaders", () => {
  const asRecord = (h: HeadersInit): Record<string, string> => h as Record<string, string>;

  it("허용된 origin을 반환한다", () => {
    const headers = asRecord(getCorsHeaders("http://localhost:3000"));
    expect(headers["Access-Control-Allow-Origin"]).toBe("http://localhost:3000");
  });

  it("허용되지 않은 origin에 기본값을 반환한다", () => {
    const headers = asRecord(getCorsHeaders("http://evil.com"));
    expect(headers["Access-Control-Allow-Origin"]).not.toBe("http://evil.com");
  });

  it("필요한 메서드를 허용한다", () => {
    const headers = asRecord(getCorsHeaders("http://localhost:3000"));
    expect(headers["Access-Control-Allow-Methods"]).toContain("GET");
    expect(headers["Access-Control-Allow-Methods"]).toContain("POST");
    expect(headers["Access-Control-Allow-Methods"]).toContain("OPTIONS");
  });

  it("credentials를 허용한다", () => {
    const headers = asRecord(getCorsHeaders("http://localhost:3000"));
    expect(headers["Access-Control-Allow-Credentials"]).toBe("true");
  });
});
