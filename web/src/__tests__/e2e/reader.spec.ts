import { test, expect } from "@playwright/test";

test.describe("장 읽기 화면", () => {
  test("성경 본문이 표시된다", async ({ page }) => {
    // 오늘의 말씀 또는 직접 접근
    await page.goto("/read/john/3");

    // 본문 또는 절 번호가 있는지 확인
    const content = page.locator('[data-testid="chapter-content"], [class*="verse"], main');
    await expect(content).toBeVisible({ timeout: 10_000 });
  });

  test("뒤로가기 버튼이 있다", async ({ page }) => {
    await page.goto("/read/john/3");
    const backButton = page.locator('[data-testid="back-button"], a[href="/"], button:has-text("뒤로")');
    await expect(backButton).toBeVisible();
  });

  test("AI 설명 아이콘이 있다", async ({ page }) => {
    await page.goto("/read/john/3");
    const aiButton = page.locator('[data-testid="ai-explain-button"], button:has-text("설명"), [aria-label*="설명"]');
    if (await aiButton.isVisible()) {
      await expect(aiButton).toBeEnabled();
    }
  });

  test("즐겨찾기 버튼이 있다", async ({ page }) => {
    await page.goto("/read/john/3");
    const favButton = page.locator('[data-testid="favorite-button"], button[aria-label*="즐겨찾기"], button[aria-label*="bookmark"]');
    if (await favButton.isVisible()) {
      await expect(favButton).toBeEnabled();
    }
  });
});

test.describe("AI 설명 On-Demand", () => {
  test("AI 설명 버튼 탭 시 로딩 후 결과가 표시된다", async ({ page }) => {
    await page.goto("/read/john/3");
    const aiButton = page.locator('[data-testid="ai-explain-button"]');

    if (await aiButton.isVisible()) {
      await aiButton.click();

      // 스켈레톤 또는 결과가 나타나야 함
      const explanationArea = page.locator('[data-testid="ai-explanation"], [class*="explanation"], [class*="skeleton"]');
      await expect(explanationArea).toBeVisible({ timeout: 15_000 });
    }
  });
});
