import { test, expect } from "@playwright/test";

// Template-level tests for the case-study detail layout. Iterates over the
// links on the index page so adding a new case study does NOT require
// updating this file. Asserts invariants every detail page must satisfy.

test.describe("Case-study detail pages (template)", () => {
  test("every case-study detail page has required structural elements", async ({ page }) => {
    await page.goto("/case-studies/");

    // Collect every detail-page URL the index links to.
    const urls = await page.$$eval(
      '[data-test="case-study-card"] a[href^="/case-studies/"]',
      (anchors) => (anchors as HTMLAnchorElement[]).map((a) => a.getAttribute("href") || ""),
    );
    expect(urls.length).toBeGreaterThan(0);

    for (const url of urls) {
      await page.goto(url);
      await expect(
        page.locator('[data-test="case-study"]'),
        `case-study block on ${url}`,
      ).toBeVisible();
      // Title (h1 or h2) must exist.
      const hasHeading = await page.locator("h1, h2").count();
      expect(hasHeading, `heading on ${url}`).toBeGreaterThan(0);
      // Category badge and date badge (both present on every port we ship).
      await expect(page.locator('[data-test="case-study-category"]'), `category on ${url}`).toHaveCount(1);
      await expect(page.locator('[data-test="case-study-dates"]'), `dates on ${url}`).toHaveCount(1);
      // Language switcher must still render (case-studies have a `ref`).
      await expect(page.locator('[data-test="lang-switcher"]')).toBeVisible();
    }
  });

  test("FR case-study detail pages have lang=fr and /fr/ canonical", async ({ page }) => {
    await page.goto("/fr/case-studies/");
    const urls = await page.$$eval(
      '[data-test="case-study-card"] a[href^="/fr/case-studies/"]',
      (anchors) => (anchors as HTMLAnchorElement[]).map((a) => a.getAttribute("href") || ""),
    );
    expect(urls.length).toBeGreaterThan(0);

    for (const url of urls) {
      await page.goto(url);
      expect(await page.locator("html").getAttribute("lang"), `html lang on ${url}`).toBe("fr");
      const canonical = await page.locator('head link[rel="canonical"]').getAttribute("href");
      expect(canonical, `canonical on ${url}`).toContain("/fr/");
    }
  });
});
