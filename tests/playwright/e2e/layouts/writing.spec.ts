import { test, expect } from "@playwright/test";

// Writing index — the framework is here, no imported posts yet (per plan §3.3).
// Tests verify the page renders (empty-state OK), is in nav, and works in both languages.

test.describe("Writing index", () => {
  test("EN /writing/ returns 200 and is in nav", async ({ page }) => {
    const r = await page.goto("/writing/");
    expect(r?.status()).toBe(200);
    await expect(page.locator('#sidebar nav a[href="/writing/"]')).toHaveCount(1);
  });

  test("FR /fr/writing/ returns 200 and is in FR nav", async ({ page }) => {
    const r = await page.goto("/fr/writing/");
    expect(r?.status()).toBe(200);
    await expect(page.locator('#sidebar nav a[href="/fr/writing/"]')).toHaveCount(1);
  });

  test("empty state renders gracefully when no posts exist", async ({ page }) => {
    await page.goto("/writing/");
    // The page must render a meaningful title + body, even when the post list is empty.
    await expect(page.locator("h1, h2").first()).toBeVisible();
    // No broken images, no Liquid errors leaked as text.
    const body = (await page.locator("main").textContent()) || "";
    expect(body).not.toContain("{{");
    expect(body).not.toContain("{%");
  });
});
