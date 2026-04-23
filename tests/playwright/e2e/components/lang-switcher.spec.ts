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

  test("page without translation shows unavailable state in switcher", async ({ page }) => {
    // ia-mobilite is orphan-but-translated; pick a file explicitly marked translated: false in a future test.
    // Here we just assert that the switcher never renders a broken <a> without href.
    await page.goto("/");
    const brokenLinks = page.locator('[data-test="lang-switcher"] a:not([href])');
    await expect(brokenLinks).toHaveCount(0);
  });
});

test.describe("hreflang + canonical (Phase 1)", () => {
  test("EN home emits hreflang=en self-link", async ({ page }) => {
    await page.goto("/");
    const enHreflang = page.locator('head link[rel="alternate"][hreflang="en"]');
    await expect(enHreflang).toHaveCount(1);
  });

  test("EN home emits hreflang=fr pointing to /fr/", async ({ page }) => {
    await page.goto("/");
    const frHreflang = page.locator('head link[rel="alternate"][hreflang="fr"]');
    await expect(frHreflang).toHaveCount(1);
    const href = await frHreflang.getAttribute("href");
    expect(href).toMatch(/\/fr\/?$/);
  });

  test("EN home emits hreflang=x-default", async ({ page }) => {
    await page.goto("/");
    const xDefault = page.locator('head link[rel="alternate"][hreflang="x-default"]');
    await expect(xDefault).toHaveCount(1);
  });

  test("FR home emits canonical pointing to /fr/", async ({ page }) => {
    await page.goto("/fr/");
    const canonical = page.locator('head link[rel="canonical"]');
    const href = await canonical.getAttribute("href");
    expect(href).toMatch(/\/fr\/?$/);
  });

  test("<html lang> matches page language on EN", async ({ page }) => {
    await page.goto("/");
    expect(await page.locator("html").getAttribute("lang")).toBe("en");
  });

  test("<html lang> matches page language on FR", async ({ page }) => {
    await page.goto("/fr/");
    expect(await page.locator("html").getAttribute("lang")).toBe("fr");
  });
});
