import { test, expect } from "@playwright/test";

// Pins the sidebar nav language-filter invariants:
// - [REVIEW-1] (first round): EN and FR navs must not bleed into each other.
// - [REVIEW-2] (first round): home link is language-aware.
// - [REVIEW-21] / [REVIEW-1 @ 07:01]: home nav label follows page.lang.
// - [REVIEW-15]: counts are data-driven (number of tabs per language), not
//   hard-coded — adding a tab does not break this unrelated test.
// - [REVIEW-16]: leakage checks scope to the nav element, not full HTML.

const NAV = "#sidebar nav.flex-column > ul.nav";

test.describe("Sidebar nav", () => {
  test("EN home nav contains only EN tab URLs (+ home)", async ({ page }) => {
    await page.goto("/");
    const nav = page.locator(NAV);
    // Data-driven: count EN anchors (those that don't start with /fr/). Must be ≥ 2
    // (at minimum, home + one tab). Exact number adapts as tabs grow.
    const enTabAnchors = await nav.locator('a[href]:not([href^="/fr/"])').count();
    expect(enTabAnchors).toBeGreaterThanOrEqual(2);
    // No FR tab URL must appear.
    const frTabLinks = nav.locator('a[href^="/fr/"]');
    await expect(frTabLinks).toHaveCount(0);
  });

  test("FR home nav contains only FR tab URLs (+ home)", async ({ page }) => {
    await page.goto("/fr/");
    const nav = page.locator(NAV);
    const frTabAnchors = await nav.locator('a[href^="/fr/"]').count();
    expect(frTabAnchors).toBeGreaterThanOrEqual(2);
    // EN-only tab URLs must not appear in the nav specifically.
    const enOnlyInFrNav = nav.locator(
      'a[href="/about/"], a[href="/archives/"], a[href="/categories/"], a[href="/tags/"]',
    );
    await expect(enOnlyInFrNav).toHaveCount(0);
  });

  test("avatar and site-title link to the current-language home (EN)", async ({ page }) => {
    await page.goto("/");
    expect(await page.locator("#sidebar #avatar").getAttribute("href")).toBe("/");
    expect(await page.locator("#sidebar a.site-title").getAttribute("href")).toBe("/");
  });

  test("avatar and site-title link to the current-language home (FR)", async ({ page }) => {
    await page.goto("/fr/");
    expect(await page.locator("#sidebar #avatar").getAttribute("href")).toBe("/fr/");
    expect(await page.locator("#sidebar a.site-title").getAttribute("href")).toBe("/fr/");
  });

  // [REVIEW-21] / [REVIEW-1 @ 07:01]: home label in the current-page language.
  test("home nav label is 'HOME' on /", async ({ page }) => {
    await page.goto("/");
    const firstNavItem = page.locator(`${NAV} > li.nav-item`).first();
    await expect(firstNavItem).toContainText(/HOME/i);
  });

  test("home nav label is 'ACCUEIL' on /fr/", async ({ page }) => {
    await page.goto("/fr/");
    const firstNavItem = page.locator(`${NAV} > li.nav-item`).first();
    await expect(firstNavItem).toContainText(/ACCUEIL/i);
  });
});
