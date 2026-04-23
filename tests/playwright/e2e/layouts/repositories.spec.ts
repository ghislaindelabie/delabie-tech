import { test, expect } from "@playwright/test";

// Template-level tests for /repositories/ — page is driven by
// _data/repositories.yml; adding/removing a repo OR a section must NOT
// touch any test. [REVIEW-3 addressed: no hardcoded section list.]

test.describe("Repositories page", () => {
  test("EN page renders ≥ 1 data-driven section", async ({ page }) => {
    const r = await page.goto("/repositories/");
    expect(r?.status()).toBe(200);

    const sections = page.locator('[data-test="repos-section"]');
    expect(await sections.count()).toBeGreaterThan(0);

    // Every rendered section has a non-empty data-key attribute.
    const keys = await sections.evaluateAll((els) =>
      els.map((e) => e.getAttribute("data-key") || ""),
    );
    for (const k of keys) expect(k.length).toBeGreaterThan(0);
    expect(new Set(keys).size).toBe(keys.length); // no duplicate keys
  });

  test("FR page renders the same number of sections as EN", async ({ page }) => {
    await page.goto("/repositories/");
    const enCount = await page.locator('[data-test="repos-section"]').count();
    const rFr = await page.goto("/fr/repositories/");
    expect(rFr?.status()).toBe(200);
    const frCount = await page.locator('[data-test="repos-section"]').count();
    expect(frCount).toBe(enCount);
  });

  test("every section has at least one repo card", async ({ page }) => {
    await page.goto("/repositories/");
    const sections = page.locator('[data-test="repos-section"]');
    const count = await sections.count();
    expect(count).toBeGreaterThan(0);
    for (let i = 0; i < count; i++) {
      const section = sections.nth(i);
      const cards = section.locator('[data-test="repo-card"]');
      expect(await cards.count(), `section ${i} should have ≥ 1 repo card`).toBeGreaterThan(0);
    }
  });

  test("every repo card has a link + name + description", async ({ page }) => {
    await page.goto("/repositories/");
    const cards = page.locator('[data-test="repo-card"]');
    const count = await cards.count();
    for (let i = 0; i < count; i++) {
      const card = cards.nth(i);
      await expect(card.locator("a[href]")).toHaveCount(1);
      const text = (await card.textContent())?.trim() || "";
      expect(text.length).toBeGreaterThan(5);
    }
  });

  test("page contains no legacy-site strings (TTalex + self-deprecating)", async ({ page }) => {
    await page.goto("/repositories/");
    const html = await page.content();
    expect(html).not.toContain("TTalex");
    expect(html.toLowerCase()).not.toContain("je débute encore");
  });

  test("reachable from sidebar nav (EN + FR)", async ({ page }) => {
    await page.goto("/");
    await expect(page.locator('#sidebar nav a[href="/repositories/"]')).toHaveCount(1);
    await page.goto("/fr/");
    await expect(page.locator('#sidebar nav a[href="/fr/repositories/"]')).toHaveCount(1);
  });
});
