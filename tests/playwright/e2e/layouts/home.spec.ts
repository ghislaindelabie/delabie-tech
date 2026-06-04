import { test, expect } from "@playwright/test";

// Phase 0 smoke stays; Phase 3 adds Recent Activity + Featured case studies.

test.describe("Homepage (Phase 0 smoke)", () => {
  test("returns 200 and has a title", async ({ page }) => {
    const response = await page.goto("/");
    expect(response?.status()).toBe(200);
    await expect(page).toHaveTitle(/Ghislain Delabie/i);
  });

  test("has <html lang> attribute", async ({ page }) => {
    await page.goto("/");
    const lang = await page.locator("html").getAttribute("lang");
    expect(lang).toBeTruthy();
  });

  test("has a canonical link", async ({ page }) => {
    await page.goto("/");
    const canonical = page.locator('link[rel="canonical"]');
    await expect(canonical).toHaveCount(1);
  });
});

test.describe("Homepage — hero lede + CTA", () => {
  test("renders hero with non-empty lede and a CTA link on EN home", async ({ page }) => {
    await page.goto("/");
    const hero = page.locator('[data-test="home-hero"]');
    await expect(hero).toBeVisible();
    const lede = (await hero.locator("p.lead").textContent())?.trim() || "";
    expect(lede.length).toBeGreaterThan(0);
    const cta = hero.locator('[data-test="home-hero-cta"]');
    await expect(cta).toHaveAttribute("href", "/contact/");
  });

  test("FR hero CTA links to the FR contact page", async ({ page }) => {
    await page.goto("/fr/");
    const hero = page.locator('[data-test="home-hero"]');
    await expect(hero).toBeVisible();
    const cta = hero.locator('[data-test="home-hero-cta"]');
    await expect(cta).toHaveAttribute("href", "/fr/contact/");
  });
});

test.describe("Homepage — Recent Activity (Phase 3)", () => {
  test("renders Recent Activity section with ≥ 1 entry on EN home", async ({ page }) => {
    await page.goto("/");
    const section = page.locator('[data-test="home-activity"]');
    await expect(section).toBeVisible();
    await expect(section.locator('[data-test="activity-item"]').first()).toBeVisible();
  });

  test("renders Recent Activity section with ≥ 1 entry on FR home", async ({ page }) => {
    await page.goto("/fr/");
    const section = page.locator('[data-test="home-activity"]');
    await expect(section).toBeVisible();
    await expect(section.locator('[data-test="activity-item"]').first()).toBeVisible();
  });

  test("each activity item exposes date + title", async ({ page }) => {
    await page.goto("/");
    const items = page.locator('[data-test="activity-item"]');
    const count = await items.count();
    expect(count).toBeGreaterThan(0);
    for (let i = 0; i < count; i++) {
      const item = items.nth(i);
      await expect(item.locator("time"), `activity item ${i} missing <time>`).toHaveCount(1);
      // Title or text content must be non-empty.
      const text = (await item.textContent())?.trim() || "";
      expect(text.length).toBeGreaterThan(0);
    }
  });

  test("caps at 5 items (homepage density discipline)", async ({ page }) => {
    await page.goto("/");
    const items = await page.locator('[data-test="activity-item"]').count();
    expect(items).toBeLessThanOrEqual(5);
  });
});

test.describe("Homepage — Featured case studies (Phase 3)", () => {
  test("renders ≥ 3 featured case studies on EN home", async ({ page }) => {
    await page.goto("/");
    const section = page.locator('[data-test="home-featured-case-studies"]');
    await expect(section).toBeVisible();
    const cards = section.locator('[data-test="case-study-card"]');
    expect(await cards.count()).toBeGreaterThanOrEqual(3);
  });

  test("FR home's featured case studies link to /fr/case-studies/ only", async ({ page }) => {
    await page.goto("/fr/");
    const section = page.locator('[data-test="home-featured-case-studies"]');
    await expect(section).toBeVisible();
    // `/case-studies/` prefix (without /fr/) is the EN-only shape.
    const enLeak = await section.locator('a[href^="/case-studies/"]').count();
    expect(enLeak).toBe(0);
  });
});
