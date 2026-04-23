import { test, expect } from "@playwright/test";

// Addresses [REVIEW-1]: pins the sidebar nav language-filter invariant so a
// regression (e.g. forgotten {%- if tab_lang != page_lang -%} filter) would
// fail CI. Also pins [REVIEW-2]: home link is language-aware.

test.describe("Sidebar nav", () => {
  test("EN home nav shows only EN tabs (+ home)", async ({ page }) => {
    await page.goto("/");
    const nav = page.locator("#sidebar nav.flex-column > ul.nav");
    const items = nav.locator("> li.nav-item");
    // 1 home + 4 EN tabs = 5
    await expect(items).toHaveCount(5);
    // None of the FR tab URLs must appear in the nav.
    const frTabLinks = nav.locator('a[href^="/fr/"]');
    await expect(frTabLinks).toHaveCount(0);
  });

  test("FR home nav shows only FR tabs (+ home)", async ({ page }) => {
    await page.goto("/fr/");
    const nav = page.locator("#sidebar nav.flex-column > ul.nav");
    const items = nav.locator("> li.nav-item");
    await expect(items).toHaveCount(5);
    // None of the EN-only tab URLs must appear (tabs without /fr/ prefix).
    const enOnly = nav.locator('a[href="/about/"], a[href="/archives/"], a[href="/categories/"], a[href="/tags/"]');
    await expect(enOnly).toHaveCount(0);
  });

  test("avatar and site-title link to the current-language home (EN)", async ({ page }) => {
    await page.goto("/");
    const avatarHref = await page.locator("#sidebar #avatar").getAttribute("href");
    const titleHref = await page.locator("#sidebar a.site-title").getAttribute("href");
    expect(avatarHref).toBe("/");
    expect(titleHref).toBe("/");
  });

  test("avatar and site-title link to the current-language home (FR)", async ({ page }) => {
    await page.goto("/fr/");
    const avatarHref = await page.locator("#sidebar #avatar").getAttribute("href");
    const titleHref = await page.locator("#sidebar a.site-title").getAttribute("href");
    expect(avatarHref).toBe("/fr/");
    expect(titleHref).toBe("/fr/");
  });
});
