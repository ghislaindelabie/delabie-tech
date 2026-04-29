import { test, expect } from "@playwright/test";

// Template-level: adding an archive item is a pure content operation.
// Tests assert structure (rows, year groups, lang-switcher), not specific
// item content.

test.describe("Archive index", () => {
  test("EN /archive/ returns 200 with at least one row", async ({ page }) => {
    const r = await page.goto("/archive/");
    expect(r?.status()).toBe(200);
    const rows = page.locator('[data-test="archive-row"]');
    expect(await rows.count()).toBeGreaterThan(0);
  });

  test("FR /fr/archive/ mirrors structure", async ({ page }) => {
    await page.goto("/archive/");
    const enCount = await page.locator('[data-test="archive-row"]').count();
    expect(enCount).toBeGreaterThan(0);
    const r = await page.goto("/fr/archive/");
    expect(r?.status()).toBe(200);
    const frCount = await page.locator('[data-test="archive-row"]').count();
    // Strict bilingual rule: every EN item has an FR sibling, so counts match.
    expect(frCount).toBe(enCount);
  });

  test("every row exposes date, title, type", async ({ page }) => {
    await page.goto("/archive/");
    const rows = page.locator('[data-test="archive-row"]');
    const n = await rows.count();
    for (let i = 0; i < n; i++) {
      const row = rows.nth(i);
      await expect(row.locator("time")).toHaveCount(1);
      const title =
        (await row.locator('[data-test="archive-row-title"]').textContent()) || "";
      expect(title.trim().length).toBeGreaterThan(0);
      const type =
        (await row.locator('[data-test="archive-row-type"]').textContent()) || "";
      expect(type.trim().length).toBeGreaterThan(0);
    }
  });

  test("rows expose data-type and data-year facets for filtering", async ({ page }) => {
    await page.goto("/archive/");
    const rows = page.locator('[data-test="archive-row"]');
    const n = await rows.count();
    for (let i = 0; i < n; i++) {
      const row = rows.nth(i);
      const type = await row.getAttribute("data-type");
      const year = await row.getAttribute("data-year");
      expect((type || "").length).toBeGreaterThan(0);
      expect((year || "").match(/^\d{4}$/)).not.toBeNull();
    }
  });

  test("reachable from sidebar nav (EN + FR)", async ({ page }) => {
    await page.goto("/");
    await expect(page.locator('#sidebar nav a[href="/archive/"]')).toHaveCount(1);
    await page.goto("/fr/");
    await expect(page.locator('#sidebar nav a[href="/fr/archive/"]')).toHaveCount(1);
  });

  test("the index page itself shows the language switcher", async ({ page }) => {
    await page.goto("/archive/");
    await expect(page.locator('[data-test="lang-switcher"]')).toHaveCount(1);
  });

  test("filter pill narrows the list and reset restores it", async ({ page }) => {
    await page.goto("/archive/");
    // Filter section renders only when ≥2 distinct types exist (hide-empty).
    // Skip this assertion gracefully if the current content state has < 2 types.
    const filtersCount = await page
      .locator('[data-test="archive-filters"]')
      .count();
    test.skip(filtersCount === 0, "no filters rendered (single-type state)");

    const items = page.locator('[data-test="archive-row"]');
    const total = await items.count();
    const firstPill = page
      .locator('[data-test="archive-filters"] .filter-pill')
      .first();
    await firstPill.click();
    const narrowed = await items.evaluateAll((els) =>
      els.filter((el) => !(el as HTMLElement).hidden).length,
    );
    expect(narrowed).toBeGreaterThan(0);
    expect(narrowed).toBeLessThanOrEqual(total);

    await page.locator('[data-test="archive-filter-reset"]').click();
    const restored = await items.evaluateAll((els) =>
      els.filter((el) => !(el as HTMLElement).hidden).length,
    );
    expect(restored).toBe(total);
  });

  test("filter pills are hidden when only one type is present", async ({ page }) => {
    // The filters section renders only when ≥2 distinct types exist in
    // the current language. With one type, the section is collapsed.
    await page.goto("/archive/");
    const filtersCount = await page
      .locator('[data-test="archive-filters"]')
      .count();
    const items = page.locator('[data-test="archive-row"]');
    const distinctTypes = new Set<string>();
    const n = await items.count();
    for (let i = 0; i < n; i++) {
      const t = (await items.nth(i).getAttribute("data-type")) || "";
      if (t) distinctTypes.add(t);
    }
    if (distinctTypes.size > 1) expect(filtersCount).toBe(1);
    else expect(filtersCount).toBe(0);
  });

  test("title link target depends on `detail` flag", async ({ page }) => {
    await page.goto("/archive/");
    const rows = page.locator('[data-test="archive-row"]');
    const n = await rows.count();
    for (let i = 0; i < n; i++) {
      const row = rows.nth(i);
      const linkLocator = row.locator('[data-test="archive-row-title"] a').first();
      const linkCount = await linkLocator.count();
      if (linkCount === 0) continue;
      const href = (await linkLocator.getAttribute("href")) || "";
      const hasDetailLink =
        (await row.locator('[data-test="archive-row-detail-link"]').count()) > 0;
      if (hasDetailLink) {
        // detail: true → title goes internal (relative URL under /archive/)
        expect(href.startsWith("/")).toBe(true);
      } else {
        // detail: false → title goes external (http(s)://)
        expect(href.match(/^https?:\/\//)).not.toBeNull();
      }
    }
  });
});
