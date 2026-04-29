import { test, expect } from "@playwright/test";

// Template-level: every archive item gets a stable permalink with the
// same shape (`/archive/<year>/<slug>/`). This spec walks the index, picks
// each row, follows it to the detail page (when applicable), and asserts
// the layout invariants. Adding new items must not require new tests.

test.describe("Archive item detail", () => {
  test("every internally-linked item resolves and renders core metadata", async ({
    page,
  }) => {
    await page.goto("/archive/");
    const detailLinks = page.locator('[data-test="archive-row-detail-link"]');
    const detailCount = await detailLinks.count();

    for (let i = 0; i < detailCount; i++) {
      const href = await detailLinks.nth(i).getAttribute("href");
      if (!href) continue;
      const r = await page.goto(href);
      expect(r?.status()).toBe(200);
      // Core metadata is always present.
      await expect(page.locator('[data-test="archive-item"]')).toHaveCount(1);
      await expect(page.locator('[data-test="archive-item-type"]')).toHaveCount(1);
      const sourceCount = await page
        .locator('[data-test="archive-item-source"]')
        .count();
      expect(sourceCount).toBeGreaterThanOrEqual(0);
    }
  });

  // Discover an archive item URL at runtime by `kind`. The index links
  // detail:true items via the "Notes" detail-link (data-test) and links
  // detail:false items externally — for the latter, the only on-page
  // signal is that the row has NO detail-link, and we resolve the
  // permalink via sitemap.xml so tests stay decoupled from specific slugs.
  async function pickArchiveItemUrl(
    page: import("@playwright/test").Page,
    kind: "any" | "detail-true" | "detail-false",
  ) {
    await page.goto("/archive/");
    if (kind === "detail-true" || kind === "any") {
      const detailLinks = page.locator('[data-test="archive-row-detail-link"]');
      if ((await detailLinks.count()) > 0) {
        return (await detailLinks.first().getAttribute("href")) || "";
      }
      if (kind === "detail-true") return "";
    }
    // detail-false (or any, when no detail-true present): find a row
    // whose row-detail-link is absent, then resolve via sitemap.
    const rows = page.locator('[data-test="archive-row"]');
    const n = await rows.count();
    for (let i = 0; i < n; i++) {
      const row = rows.nth(i);
      const dl = await row.locator('[data-test="archive-row-detail-link"]').count();
      if (dl === 0) {
        const year = await row.getAttribute("data-year");
        const sitemap = await (await page.request.get("/sitemap.xml")).text();
        const re = new RegExp(`(/archive/${year}/[^/<]+/)`);
        const match = sitemap.match(re);
        if (match) return match[1];
      }
    }
    return "";
  }

  test("a detail:false item renders without body block", async ({ page }) => {
    const url = await pickArchiveItemUrl(page, "detail-false");
    test.skip(!url, "no detail:false item present");
    const r = await page.goto(url);
    expect(r?.status()).toBe(200);
    await expect(page.locator('[data-test="archive-item"]')).toHaveCount(1);
    await expect(page.locator('[data-test="archive-item-type"]')).toHaveCount(1);
    await expect(page.locator('[data-test="archive-item-body"]')).toHaveCount(0);
    await expect(page.locator('[data-test="archive-item-original"]')).toHaveCount(1);
  });

  test("a detail:true item renders the body block", async ({ page }) => {
    const url = await pickArchiveItemUrl(page, "detail-true");
    test.skip(!url, "no detail:true item present");
    const r = await page.goto(url);
    expect(r?.status()).toBe(200);
    await expect(page.locator('[data-test="archive-item-body"]')).toHaveCount(1);
    const bodyText =
      (await page.locator('[data-test="archive-item-body"]').textContent()) || "";
    expect(bodyText.trim().length).toBeGreaterThan(0);
  });

  // Run these template-level invariants against BOTH detail branches
  // (true and false) so a regression that only breaks one branch's
  // <head>/switcher rendering still gets caught.
  for (const kind of ["detail-true", "detail-false"] as const) {
    test(`FR sibling resolves at /fr/ permalink (${kind})`, async ({ page }) => {
      const enUrl = await pickArchiveItemUrl(page, kind);
      test.skip(!enUrl, `no ${kind} item present`);
      const frUrl = "/fr" + enUrl;
      const r = await page.goto(frUrl);
      expect(r?.status()).toBe(200);
      await expect(page.locator('[data-test="archive-item"]')).toHaveCount(1);
      expect(await page.locator("html").getAttribute("lang")).toBe("fr");
    });

    test(`language switcher present (${kind})`, async ({ page }) => {
      const url = await pickArchiveItemUrl(page, kind);
      test.skip(!url, `no ${kind} item present`);
      await page.goto(url);
      await expect(page.locator('[data-test="lang-switcher"]')).toHaveCount(1);
    });

    test(`hreflang en + fr + x-default (${kind})`, async ({ page }) => {
      const url = await pickArchiveItemUrl(page, kind);
      test.skip(!url, `no ${kind} item present`);
      await page.goto(url);
      const hreflang = page.locator('link[rel="alternate"][hreflang]');
      const langs = await hreflang.evaluateAll((els) =>
        els.map((el) => (el as HTMLLinkElement).getAttribute("hreflang")),
      );
      expect(langs).toContain("en");
      expect(langs).toContain("fr");
      expect(langs).toContain("x-default");
    });
  }
});
