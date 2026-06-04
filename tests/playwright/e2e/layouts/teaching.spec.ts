import { test, expect } from "@playwright/test";
import { activateNoMatchCombination } from "../helpers/filters";

test.describe("Teaching index", () => {
  test("EN /teaching/ returns 200 with items", async ({ page }) => {
    const r = await page.goto("/teaching/");
    expect(r?.status()).toBe(200);
    const items = page.locator('[data-test="teaching-item"]');
    expect(await items.count()).toBeGreaterThan(0);
  });

  test("FR /fr/teaching/ mirrors the EN structure", async ({ page }) => {
    await page.goto("/teaching/");
    const enCount = await page.locator('[data-test="teaching-item"]').count();
    expect(enCount).toBeGreaterThan(0);
    const r = await page.goto("/fr/teaching/");
    expect(r?.status()).toBe(200);
    const frCount = await page.locator('[data-test="teaching-item"]').count();
    expect(frCount).toBeGreaterThan(0);
    expect(frCount).toBe(enCount);
  });

  test("every teaching item has institution + years + title", async ({ page }) => {
    await page.goto("/teaching/");
    const items = page.locator('[data-test="teaching-item"]');
    const n = await items.count();
    for (let i = 0; i < n; i++) {
      const item = items.nth(i);
      await expect(item.locator('[data-test="teaching-institution"]')).toHaveCount(1);
      await expect(item.locator('[data-test="teaching-years"]')).toHaveCount(1);
      await expect(item.locator('[data-test="teaching-title"]')).toHaveCount(1);
      // `years` must render an actual 4-digit year — guards against a prior
      // Liquid-filter-chain bug that rendered an empty span.
      await expect(item.locator('[data-test="teaching-years"]')).toContainText(/\d{4}/);
    }
  });

  test("reachable from sidebar nav (EN + FR)", async ({ page }) => {
    await page.goto("/");
    await expect(page.locator('#sidebar nav a[href="/teaching/"]')).toHaveCount(1);
    await page.goto("/fr/");
    await expect(page.locator('#sidebar nav a[href="/fr/teaching/"]')).toHaveCount(1);
  });

  test("filter pill narrows the list and reset restores it", async ({ page }) => {
    await page.goto("/teaching/");
    const items = page.locator('[data-test="teaching-item"]');
    const total = await items.count();
    expect(total).toBeGreaterThan(0);

    // Click the `Data & AI` theme pill.
    await page.locator('[data-test="teaching-filters"] .filter-pill[data-filter="data-ai"]').click();
    await expect(
      page.locator('[data-test="teaching-filters"] .filter-pill[data-filter="data-ai"]'),
    ).toHaveAttribute("aria-pressed", "true");
    const narrowed = await items.evaluateAll((els) =>
      els.filter((el) => !(el as HTMLElement).hidden).length,
    );
    expect(narrowed).toBeGreaterThan(0);
    expect(narrowed).toBeLessThan(total);

    // Reset clears filters and restores full list.
    await page.locator('[data-test="teaching-filter-reset"]').click();
    const restored = await items.evaluateAll((els) =>
      els.filter((el) => !(el as HTMLElement).hidden).length,
    );
    expect(restored).toBe(total);
  });

  test("empty-state message appears when no item matches", async ({ page }) => {
    await page.goto("/teaching/");
    // Derive a no-match theme×format pair from the rendered DOM instead of
    // hardcoding one — adding content must never break this test.
    const found = await activateNoMatchCombination(page, "teaching-filters");
    test.skip(!found, "every theme×format combination currently has a matching item");
    await expect(page.locator('[data-test="teaching-empty"]')).toBeVisible();
  });
});
