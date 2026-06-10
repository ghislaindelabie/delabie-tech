import { test, expect } from "@playwright/test";
import { findUntranslatedPermalink } from "../helpers/content";

test.describe("Language switcher (Phase 1)", () => {
  test("switcher is visible on the homepage", async ({ page }) => {
    await page.goto("/");
    const switcher = page.locator('[data-test="lang-switcher"]');
    await expect(switcher).toBeVisible();
  });

  test("EN homepage links to FR variant", async ({ page }) => {
    await page.goto("/");
    const frLink = page.locator('[data-test="lang-switcher"] a[hreflang="fr"]').first();
    await expect(frLink).toHaveAttribute("href", /\/fr\/?$/);
  });

  test("clicking FR link loads FR home with lang=fr", async ({ page }) => {
    await page.goto("/");
    const frLink = page.locator('[data-test="lang-switcher"] a[hreflang="fr"]').first();
    await frLink.click();
    await expect(page).toHaveURL(/\/fr\/?$/);
    const htmlLang = await page.locator("html").getAttribute("lang");
    expect(htmlLang).toBe("fr");
  });

  test("FR page exposes EN counterpart in switcher", async ({ page }) => {
    await page.goto("/fr/");
    const enLink = page.locator('[data-test="lang-switcher"] a[hreflang="en"]').first();
    await expect(enLink).toHaveAttribute("href", /^\/(?!fr)/);
  });

  // Addresses [REVIEW-4]: genuinely exercise the unavailable branch.
  // Derive the fixture from content at test time (scan for a
  // `translated: false` doc) instead of hardcoding `/phase1-notes/` —
  // adding/removing such a page must not require editing this test. Skip
  // gracefully if no untranslated doc exists (no unavailable branch to
  // exercise).
  test("translated:false page renders unavailable state for the missing lang", async ({ page }) => {
    const fixture = findUntranslatedPermalink();
    test.skip(!fixture, "no `translated: false` content doc to exercise the unavailable branch");

    // The unavailable entry is for the OTHER language relative to the page.
    const missingLang = fixture!.lang === "fr" ? "en" : "fr";

    await page.goto(fixture!.url);
    const switcher = page.locator('[data-test="lang-switcher"]');
    await expect(switcher).toBeVisible();

    const unavailable = switcher.locator(".lang-switcher__unavailable");
    await expect(unavailable).toHaveCount(1);
    await expect(unavailable).toHaveAttribute("aria-disabled", "true");
    await expect(unavailable).toHaveAttribute("lang", missingLang);

    // And no <a> in the switcher may be missing an href.
    const brokenLinks = switcher.locator("a:not([href])");
    await expect(brokenLinks).toHaveCount(0);
  });

  // Addresses [REVIEW-9]: Chirpy's auto-generated archive-family pages
  // (categories/tags/per-tag/per-category indexes) get no switcher.
  // The new `/archive/` collection page is a real bilingual tab and DOES
  // get a switcher — see the bilingual nav tests above.
  test("Chirpy auto-archive pages do not render the switcher", async ({ page }) => {
    for (const path of ["/categories/", "/tags/"]) {
      await page.goto(path);
      await expect(page.locator('[data-test="lang-switcher"]')).toHaveCount(0);
    }
  });

  test("no broken <a> anywhere in the switcher across core pages", async ({ page }) => {
    for (const path of ["/", "/fr/", "/about/", "/fr/about/", "/phase1-notes/"]) {
      await page.goto(path);
      const broken = page.locator('[data-test="lang-switcher"] a:not([href])');
      await expect(broken, `broken <a> on ${path}`).toHaveCount(0);
    }
  });
});
