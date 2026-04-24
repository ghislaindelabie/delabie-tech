import { test, expect } from "@playwright/test";

// Template-level: adding a publication is a pure content operation.

test.describe("Publications index", () => {
  test("EN /publications/ returns 200 with items", async ({ page }) => {
    const r = await page.goto("/publications/");
    expect(r?.status()).toBe(200);
    const items = page.locator('[data-test="publication-item"]');
    expect(await items.count()).toBeGreaterThan(0);
  });

  test("FR /fr/publications/ mirrors structure", async ({ page }) => {
    await page.goto("/publications/");
    const enCount = await page.locator('[data-test="publication-item"]').count();
    expect(enCount).toBeGreaterThan(0);
    const r = await page.goto("/fr/publications/");
    expect(r?.status()).toBe(200);
    const frCount = await page.locator('[data-test="publication-item"]').count();
    expect(frCount).toBeGreaterThan(0);
    expect(frCount).toBe(enCount);
  });

  test("every publication item exposes date + title + type", async ({ page }) => {
    await page.goto("/publications/");
    const items = page.locator('[data-test="publication-item"]');
    const n = await items.count();
    for (let i = 0; i < n; i++) {
      const item = items.nth(i);
      await expect(item.locator("time")).toHaveCount(1);
      await expect(item.locator('[data-test="publication-type"]')).toHaveCount(1);
      const title = (await item.locator('[data-test="publication-title"]').textContent()) || "";
      expect(title.trim().length).toBeGreaterThan(0);
    }
  });

  test("no Einstein placeholder on rendered page", async ({ page }) => {
    await page.goto("/publications/");
    const html = (await page.content()).toLowerCase();
    expect(html).not.toContain("einstein");
    expect(html).not.toContain("relativity: the special and general theory");
  });

  test("reachable from sidebar nav (EN + FR)", async ({ page }) => {
    await page.goto("/");
    await expect(page.locator('#sidebar nav a[href="/publications/"]')).toHaveCount(1);
    await page.goto("/fr/");
    await expect(page.locator('#sidebar nav a[href="/fr/publications/"]')).toHaveCount(1);
  });

  test("filter pill narrows the list and reset restores it", async ({ page }) => {
    await page.goto("/publications/");
    const items = page.locator('[data-test="publication-item"]');
    const total = await items.count();
    expect(total).toBeGreaterThan(0);

    // Narrow to "Data & AI" theme.
    await page
      .locator('[data-test="publications-filters"] .filter-pill[data-filter="data-ai"]')
      .click();
    const narrowed = await items.evaluateAll((els) =>
      els.filter((el) => !(el as HTMLElement).hidden).length,
    );
    expect(narrowed).toBeGreaterThan(0);
    expect(narrowed).toBeLessThan(total);

    await page.locator('[data-test="publications-filter-reset"]').click();
    const restored = await items.evaluateAll((els) =>
      els.filter((el) => !(el as HTMLElement).hidden).length,
    );
    expect(restored).toBe(total);
  });

  test("empty-state appears when no item matches", async ({ page }) => {
    await page.goto("/publications/");
    // No current entry carries format=talk, so selecting it alone should
    // empty the list.
    await page
      .locator('[data-test="publications-filters"] .filter-pill[data-filter="talk"]')
      .click();
    await expect(page.locator('[data-test="publications-empty"]')).toBeVisible();
  });
});
