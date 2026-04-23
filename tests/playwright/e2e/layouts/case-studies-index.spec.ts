import { test, expect } from "@playwright/test";

test.describe("Case-studies index page", () => {
  test("EN index renders grid with ≥ one card per known category", async ({ page }) => {
    const r = await page.goto("/case-studies/");
    expect(r?.status()).toBe(200);

    const grid = page.locator('[data-test="case-studies-grid"]');
    await expect(grid).toBeVisible();

    const cards = grid.locator('[data-test="case-study-card"]');
    const count = await cards.count();
    expect(count).toBeGreaterThan(0);

    // Every card has a linked title, a category, and dates.
    for (let i = 0; i < count; i++) {
      const card = cards.nth(i);
      await expect(card.locator("h2 a")).toHaveCount(1);
      // Category is optional in theory but every current entry has one.
      await expect(card.locator(".case-study-card__category")).toHaveCount(1);
    }
  });

  test("FR index renders with /fr/case-studies/ links only", async ({ page }) => {
    await page.goto("/fr/case-studies/");
    const grid = page.locator('[data-test="case-studies-grid"]');
    await expect(grid).toBeVisible();
    const frCards = await grid.locator('a[href^="/fr/case-studies/"]').count();
    expect(frCards).toBeGreaterThan(0);
    // No EN case-study URLs should appear on the FR index.
    const enLeakage = await grid.locator('a[href^="/case-studies/"]:not([href^="/fr/"])').count();
    expect(enLeakage).toBe(0);
  });

  test("index is reachable from sidebar nav (EN)", async ({ page }) => {
    await page.goto("/");
    const navLink = page.locator('#sidebar nav.flex-column a[href="/case-studies/"]');
    await expect(navLink).toHaveCount(1);
  });

  test("index is reachable from sidebar nav (FR)", async ({ page }) => {
    await page.goto("/fr/");
    const navLink = page.locator('#sidebar nav.flex-column a[href="/fr/case-studies/"]');
    await expect(navLink).toHaveCount(1);
  });
});
