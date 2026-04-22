import { test, expect } from "@playwright/test";

test.describe("Homepage (Phase 0 smoke)", () => {
  test("returns 200 and has a title", async ({ page }) => {
    const response = await page.goto("/");
    expect(response?.status()).toBe(200);
    await expect(page).toHaveTitle(/Ghislain Delabie/i);
  });

  test("has <html lang> attribute", async ({ page }) => {
    await page.goto("/");
    const lang = await page.locator("html").getAttribute("lang");
    expect(lang).toBeTruthy();
  });

  test("has a canonical link", async ({ page }) => {
    await page.goto("/");
    const canonical = page.locator('link[rel="canonical"]');
    await expect(canonical).toHaveCount(1);
  });
});
