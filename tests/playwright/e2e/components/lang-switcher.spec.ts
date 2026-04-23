import { test, expect } from "@playwright/test";

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
  test("translated:false page renders unavailable state for the missing lang", async ({ page }) => {
    await page.goto("/phase1-notes/");
    const switcher = page.locator('[data-test="lang-switcher"]');
    await expect(switcher).toBeVisible();

    // Current page is EN, so FR entry must be in the unavailable state.
    const unavailable = switcher.locator(".lang-switcher__unavailable");
    await expect(unavailable).toHaveCount(1);
    await expect(unavailable).toHaveAttribute("aria-disabled", "true");
    await expect(unavailable).toHaveAttribute("lang", "fr");

    // And no <a> in the switcher may be missing an href.
    const brokenLinks = switcher.locator("a:not([href])");
    await expect(brokenLinks).toHaveCount(0);
  });

  // Addresses [REVIEW-9]: archive-shaped pages get no switcher at all.
  test("archive/tag/category pages do not render the switcher", async ({ page }) => {
    for (const path of ["/archives/", "/categories/", "/tags/", "/fr/archives/"]) {
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
