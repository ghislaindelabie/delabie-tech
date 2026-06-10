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

test.describe("CV — mobile section interleave (UX-10)", () => {
  test("Skills and Education render above Experience at phone width", async ({ page }) => {
    await page.setViewportSize({ width: 600, height: 900 });
    await page.goto("/cv/");
    // boundingBox() returns null for hidden/detached elements; guard with a
    // named expect so a layout regression fails informatively instead of
    // throwing an opaque "cannot read .y of null".
    const top = async (sel: string) => {
      const box = await page.locator(sel).boundingBox();
      expect(box, `${sel} should be visible (boundingBox not null)`).not.toBeNull();
      return box!.y;
    };
    const skills = await top(".cv-split__card--skills");
    const education = await top(".cv-split__card--education");
    const experience = await top(".cv-split__section--experience");
    expect(skills).toBeLessThan(experience);
    expect(education).toBeLessThan(experience);
  });

  test("sidebar facts stay in the side column on desktop", async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.goto("/cv/");
    const main = await page.locator(".cv-split__main").boundingBox();
    const skills = await page.locator(".cv-split__card--skills").boundingBox();
    expect(main, ".cv-split__main should be visible (boundingBox not null)").not.toBeNull();
    expect(skills, ".cv-split__card--skills should be visible (boundingBox not null)").not.toBeNull();
    // sidebar card sits to the right of the main column, not below it
    expect(skills!.x).toBeGreaterThan(main!.x + main!.width - 1);
  });
});
