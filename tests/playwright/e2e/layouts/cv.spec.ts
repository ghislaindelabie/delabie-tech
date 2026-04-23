import { test, expect } from "@playwright/test";

test.describe("CV page", () => {
  test("EN /cv/ returns 200 with lang + canonical", async ({ page }) => {
    const r = await page.goto("/cv/");
    expect(r?.status()).toBe(200);
    expect(await page.locator("html").getAttribute("lang")).toBe("en");
    await expect(page.locator('link[rel="canonical"]')).toHaveCount(1);
  });

  test("FR /fr/cv/ returns 200 with lang=fr", async ({ page }) => {
    const r = await page.goto("/fr/cv/");
    expect(r?.status()).toBe(200);
    expect(await page.locator("html").getAttribute("lang")).toBe("fr");
  });

  test("CV is in the sidebar nav (EN + FR)", async ({ page }) => {
    await page.goto("/");
    await expect(page.locator('#sidebar nav a[href="/cv/"]')).toHaveCount(1);
    await page.goto("/fr/");
    await expect(page.locator('#sidebar nav a[href="/fr/cv/"]')).toHaveCount(1);
  });

  test("body contains Alien Intelligence and does NOT contain 'transitioning' framing", async ({ page }) => {
    await page.goto("/cv/");
    const main = (await page.locator("main").textContent()) || "";
    expect(main.toLowerCase()).toContain("alien intelligence");
    expect(main.toLowerCase()).not.toContain("transitioning into ai");
  });

  test("language switcher works on the CV page", async ({ page }) => {
    await page.goto("/cv/");
    const fr = page.locator('[data-test="lang-switcher"] a[hreflang="fr"]');
    await expect(fr).toHaveCount(1);
    await fr.click();
    await expect(page).toHaveURL(/\/fr\/cv\/?$/);
  });
});
