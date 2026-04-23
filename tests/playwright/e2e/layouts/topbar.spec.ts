import { test, expect } from "@playwright/test";

// Topbar tests — breadcrumb shape, title, and language switcher placement.
// Covers both EN and FR via URL-derived assertions (no per-content hardcoding).

test.describe("Topbar — language switcher", () => {
  test("switcher lives in the topbar (not in the sidebar)", async ({ page }) => {
    await page.goto("/");
    const topbar = page.locator("#topbar");
    await expect(
      topbar.locator('[data-test="lang-switcher"]'),
      "switcher should be in topbar",
    ).toHaveCount(1);
    await expect(
      page.locator('#sidebar [data-test="lang-switcher"]'),
      "switcher should NOT be in sidebar",
    ).toHaveCount(0);
  });

  test("switcher is visible without scrolling (above the fold)", async ({ page, viewport }) => {
    await page.goto("/");
    const switcher = page.locator('[data-test="lang-switcher"]');
    await expect(switcher).toBeVisible();
    const box = await switcher.boundingBox();
    expect(box).not.toBeNull();
    // Top of viewport is 0; switcher's top must be above the bottom edge.
    expect(box!.y).toBeLessThan(viewport!.height);
  });

  test("switcher renders compact (2-letter codes + separator)", async ({ page }) => {
    await page.goto("/");
    const switcher = page.locator('[data-test="lang-switcher"]');
    const text = (await switcher.textContent())?.replace(/\s+/g, "") || "";
    // Expected pattern: EN · FR (with middot), uppercase codes.
    expect(text).toMatch(/^[A-Z]{2}·[A-Z]{2}$/);
  });
});

test.describe("Topbar — breadcrumb", () => {
  test("case-study detail page shows 3-level breadcrumb (Home > Case studies > title)", async ({ page }) => {
    await page.goto("/case-studies/mob/");
    const crumbs = page.locator("#breadcrumb > span");
    await expect(crumbs).toHaveCount(3);
    await expect(crumbs.nth(0).locator("a")).toHaveAttribute("href", "/");
    await expect(crumbs.nth(1).locator("a")).toHaveAttribute("href", "/case-studies/");
  });

  test("FR case-study detail page uses /fr/ Home and localised middle crumb", async ({ page }) => {
    await page.goto("/fr/case-studies/mob/");
    const crumbs = page.locator("#breadcrumb > span");
    await expect(crumbs).toHaveCount(3);
    await expect(crumbs.nth(0).locator("a")).toHaveAttribute("href", "/fr/");
    await expect(crumbs.nth(1).locator("a")).toHaveAttribute("href", "/fr/case-studies/");
    await expect(crumbs.nth(1)).toContainText(/études de cas/i);
  });

  test("tab page shows 2-level breadcrumb", async ({ page }) => {
    await page.goto("/case-studies/");
    const crumbs = page.locator("#breadcrumb > span");
    await expect(crumbs).toHaveCount(2);
  });

  test("homepage shows single-level breadcrumb", async ({ page }) => {
    await page.goto("/");
    const crumbs = page.locator("#breadcrumb > span");
    await expect(crumbs).toHaveCount(1);
  });
});

test.describe("Topbar — title", () => {
  test("case-study detail preserves title casing (not 'Case_study')", async ({ page }) => {
    await page.goto("/case-studies/mob/");
    const title = await page.locator("#topbar-title").textContent();
    expect(title?.trim()).toContain("moB");
    expect(title?.trim()).not.toMatch(/Case_study/);
  });

  test("<title> tag is non-empty on tab pages (regression for empty-title bug)", async ({ page }) => {
    await page.goto("/case-studies/");
    const title = await page.title();
    // Must not start with ' | ' (empty prefix bug).
    expect(title).not.toMatch(/^\s*\|/);
    expect(title).toContain("Case studies");
  });
});
