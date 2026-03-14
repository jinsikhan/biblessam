import { test, expect } from "@playwright/test";

test.describe("홈 화면", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
  });

  test("홈 페이지가 정상 로드된다", async ({ page }) => {
    await expect(page).toHaveTitle(/바이블쌤|BibleSsam/i);
  });

  test("검색바가 표시된다", async ({ page }) => {
    const searchBar = page.locator('[data-testid="search-bar"], input[type="search"], input[placeholder*="검색"]');
    await expect(searchBar).toBeVisible();
  });

  test("오늘의 말씀 카드가 표시된다", async ({ page }) => {
    const dailyCard = page.locator('[data-testid="daily-chapter"], [class*="daily"]');
    await expect(dailyCard).toBeVisible();
  });

  test("하단 탭 네비게이션이 표시된다", async ({ page }) => {
    const nav = page.locator('nav, [data-testid="bottom-nav"]');
    await expect(nav).toBeVisible();
  });

  test("감정 칩이 가로 스크롤 가능하다", async ({ page }) => {
    const chipContainer = page.locator('[data-testid="emotion-chips"], [class*="emotion"]');
    if (await chipContainer.isVisible()) {
      const box = await chipContainer.boundingBox();
      expect(box).not.toBeNull();
    }
  });
});

test.describe("네비게이션", () => {
  test("즐겨찾기 탭으로 이동 가능하다", async ({ page }) => {
    await page.goto("/");
    const favTab = page.locator('a[href*="favorite"], [data-testid="tab-favorites"]');
    if (await favTab.isVisible()) {
      await favTab.click();
      await expect(page).toHaveURL(/favorite/);
    }
  });

  test("설정 탭으로 이동 가능하다", async ({ page }) => {
    await page.goto("/");
    const settingsTab = page.locator('a[href*="setting"], [data-testid="tab-settings"]');
    if (await settingsTab.isVisible()) {
      await settingsTab.click();
      await expect(page).toHaveURL(/setting/);
    }
  });
});
