import { test, expect } from "@playwright/test";

// Head-level metadata: hreflang, canonical, <html lang>, robots noindex.
// Moved here from components/lang-switcher per [REVIEW-10] — these assertions
// are page-metadata concerns, not switcher-component concerns.

test.describe("hreflang + canonical", () => {
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

  // Addresses [REVIEW-3]: x-default must point at the default (EN) version.
  test("x-default href points to the default (EN) version on BOTH pages", async ({ page }) => {
    await page.goto("/");
    const enXDef = await page.locator('head link[rel="alternate"][hreflang="x-default"]').getAttribute("href");
    expect(enXDef).toMatch(/\/$/);
    expect(enXDef).not.toContain("/fr/");

    await page.goto("/fr/");
    const frXDef = await page.locator('head link[rel="alternate"][hreflang="x-default"]').getAttribute("href");
    expect(frXDef).toMatch(/\/$/);
    expect(frXDef, "FR page must still reference the EN URL as x-default").not.toContain("/fr/");
  });

  test("FR home emits canonical pointing to /fr/", async ({ page }) => {
    await page.goto("/fr/");
    const canonical = page.locator('head link[rel="canonical"]');
    const href = await canonical.getAttribute("href");
    expect(href).toMatch(/\/fr\/?$/);
  });

  test("<html lang> matches page language on EN and FR", async ({ page }) => {
    await page.goto("/");
    expect(await page.locator("html").getAttribute("lang")).toBe("en");
    await page.goto("/fr/");
    expect(await page.locator("html").getAttribute("lang")).toBe("fr");
  });
});

test.describe("robots noindex (preview precaution)", () => {
  // Addresses [REVIEW-12]: single-source emission.
  test("robots noindex appears exactly once on home", async ({ page }) => {
    await page.goto("/");
    const metas = await page.locator('head meta[name="robots"]').count();
    expect(metas).toBe(1);
  });
});
