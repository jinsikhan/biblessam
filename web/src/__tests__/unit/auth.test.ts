/**
 * 인증 유틸리티 단위 테스트
 * JWT 발급/검증, 요청에서 토큰 추출
 */

describe("Auth", () => {
  const originalEnv = process.env;

  beforeAll(() => {
    process.env.JWT_SECRET = "test-jwt-secret-at-least-32-characters-long";
  });

  afterAll(() => {
    process.env = originalEnv;
  });

  describe("JWT", () => {
    it("accessToken 발급 후 검증 시 sub 반환", async () => {
      const { signAccessToken, verifyAccessToken } = await import("@/lib/auth/jwt");
      const token = signAccessToken("user_123");
      expect(token).toBeTruthy();
      const payload = verifyAccessToken(token);
      expect(payload).not.toBeNull();
      expect(payload!.sub).toBe("user_123");
      expect(payload!.type).toBe("access");
    });

    it("refreshToken 발급 후 검증 시 sub, jti 반환", async () => {
      const { signRefreshToken, verifyRefreshToken } = await import("@/lib/auth/jwt");
      const { token, jti } = signRefreshToken("user_456");
      expect(token).toBeTruthy();
      expect(jti).toBeTruthy();
      const payload = verifyRefreshToken(token);
      expect(payload).not.toBeNull();
      expect(payload!.sub).toBe("user_456");
      expect(payload!.jti).toBe(jti);
      expect(payload!.type).toBe("refresh");
    });

    it("잘못된 토큰 검증 시 null", async () => {
      const { verifyAccessToken, verifyRefreshToken } = await import("@/lib/auth/jwt");
      expect(verifyAccessToken("invalid")).toBeNull();
      expect(verifyRefreshToken("invalid")).toBeNull();
    });
  });

  describe("getAccessTokenFromRequest", () => {
    it("Authorization Bearer에서 토큰 추출", async () => {
      const { getAccessTokenFromRequest } = await import("@/lib/auth/jwt");
      const req = new Request("http://x", {
        headers: { Authorization: "Bearer my.token.here" },
      });
      expect(getAccessTokenFromRequest(req)).toBe("my.token.here");
    });

    it("토큰 없으면 null", async () => {
      const { getAccessTokenFromRequest } = await import("@/lib/auth/jwt");
      const req = new Request("http://x");
      expect(getAccessTokenFromRequest(req)).toBeNull();
    });
  });

  describe("getAuthFromRequest", () => {
    it("Bearer 없으면 anonymous", async () => {
      const { getAuthFromRequest } = await import("@/lib/auth/with-auth");
      const req = new Request("http://x");
      const auth = getAuthFromRequest(req);
      expect(auth.userId).toBe("anonymous");
      expect(auth.user).toBeNull();
    });
  });
});
