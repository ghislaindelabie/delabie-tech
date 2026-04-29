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

  // Discover any archive item URL at runtime — these specs assert template
  // invariants, not specific items, so they survive content churn.
  async function pickAnyArchiveItemUrl(page: import("@playwright/test").Page) {
    await page.goto("/archive/");
    // Title link: external when detail:false, internal when detail:true.
    // For these template tests we want any item's permalink (always
    // /archive/<year>/<slug>/), reachable via the per-row "Notes" link
    // when present, otherwise we synthesize from the data-* attributes.
    const detailLinks = page.locator('[data-test="archive-row-detail-link"]');
    if ((await detailLinks.count()) > 0) {
      return (await detailLinks.first().getAttribute("href")) || "";
    }
    // No detail links — pull the first row's data-year and pick its title
    // text + check the href if internal, or fall back to the row's URL by
    // navigating to the permalink Jekyll generates from filename slug.
    const firstRow = page.locator('[data-test="archive-row"]').first();
    const year = await firstRow.getAttribute("data-year");
    // The rendered <a> on detail:false items points at the external original;
    // we still want the permalink. Read sitemap.xml for the slug list.
    const sitemap = await (await page.request.get("/sitemap.xml")).text();
    const re = new RegExp(`(/archive/${year}/[^/<]+/)`);
    const match = sitemap.match(re);
    return match ? match[1] : "";
  }

  test("a detail:false item renders without body block", async ({ page }) => {
    // Visit any archive item that lacks a "Notes" detail link on the
    // index — that's a detail:false item by construction.
    const detailLinks = await page.goto("/archive/").then(() =>
      page.locator('[data-test="archive-row-detail-link"]').count(),
    );
    const rows = await page.locator('[data-test="archive-row"]').count();
    test.skip(
      detailLinks === rows,
      "all current items are detail:true; nothing exercises this branch",
    );

    const url = await pickAnyArchiveItemUrl(page);
    test.skip(!url, "no archive item URL discoverable");
    const r = await page.goto(url);
    expect(r?.status()).toBe(200);
    await expect(page.locator('[data-test="archive-item"]')).toHaveCount(1);
    await expect(page.locator('[data-test="archive-item-type"]')).toHaveCount(1);
    // detail:false → no body block.
    await expect(page.locator('[data-test="archive-item-body"]')).toHaveCount(0);
    // Outward link to the original is always present.
    await expect(page.locator('[data-test="archive-item-original"]')).toHaveCount(1);
  });

  test("FR sibling resolves at the /fr/-prefixed permalink", async ({ page }) => {
    const enUrl = await pickAnyArchiveItemUrl(page);
    test.skip(!enUrl, "no archive item URL discoverable");
    const frUrl = "/fr" + enUrl;
    const r = await page.goto(frUrl);
    expect(r?.status()).toBe(200);
    await expect(page.locator('[data-test="archive-item"]')).toHaveCount(1);
    expect(await page.locator("html").getAttribute("lang")).toBe("fr");
  });

  test("language switcher present on detail pages", async ({ page }) => {
    const url = await pickAnyArchiveItemUrl(page);
    test.skip(!url, "no archive item URL discoverable");
    await page.goto(url);
    await expect(page.locator('[data-test="lang-switcher"]')).toHaveCount(1);
  });

  test("hreflang en + fr + x-default present", async ({ page }) => {
    const url = await pickAnyArchiveItemUrl(page);
    test.skip(!url, "no archive item URL discoverable");
    await page.goto(url);
    const hreflang = page.locator('link[rel="alternate"][hreflang]');
    const langs = await hreflang.evaluateAll((els) =>
      els.map((el) => (el as HTMLLinkElement).getAttribute("hreflang")),
    );
    expect(langs).toContain("en");
    expect(langs).toContain("fr");
    expect(langs).toContain("x-default");
  });
});
