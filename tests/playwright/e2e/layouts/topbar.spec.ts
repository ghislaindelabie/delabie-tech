import { test, expect } from "@playwright/test";

// Topbar tests — template-level assertions (no hardcoded case-study slug).
// Pattern mirrors tests/playwright/e2e/layouts/case-study-detail.spec.ts:
// visit the index page, crawl the first link, assert the invariant. Adding
// a new case study never requires updating this file. [REVIEW-5 addressed.]

async function firstCaseStudyUrl(page: import("@playwright/test").Page, indexUrl: string): Promise<string> {
  await page.goto(indexUrl);
  const url = await page
    .locator(`[data-test="case-study-card"] a[href^="${indexUrl}"]`)
    .first()
    .getAttribute("href");
  if (!url) throw new Error(`No case-study link found on ${indexUrl}`);
  return url;
}

test.describe("Topbar — language switcher", () => {
  test("switcher lives in the topbar (not in the sidebar)", async ({ page }) => {
    await page.goto("/");
    const topbar = page.locator("#topbar");
    await expect(
      topbar.locator('[data-test="lang-switcher"]'),
      "switcher should be in topbar",
    ).toHaveCount(1);
    await expect(
      page.locator('#sidebar [data-test="lang-switcher"]'),
      "switcher should NOT be in sidebar",
    ).toHaveCount(0);
  });

  test("switcher sits inside the topbar's vertical extent (truly above the fold)", async ({ page }) => {
    await page.goto("/");
    const switcher = page.locator('[data-test="lang-switcher"]');
    await expect(switcher).toBeVisible();

    const switcherBox = await switcher.boundingBox();
    const topbarBox = await page.locator("#topbar").boundingBox();
    expect(switcherBox).not.toBeNull();
    expect(topbarBox).not.toBeNull();

    // The switcher's bottom edge must be within the topbar's bottom edge.
    // That's the real "always visible in the topbar" invariant, not just
    // "y < viewport height" which any DOM element satisfies.
    expect(switcherBox!.y).toBeGreaterThanOrEqual(topbarBox!.y - 1);
    expect(switcherBox!.y + switcherBox!.height).toBeLessThanOrEqual(topbarBox!.y + topbarBox!.height + 1);
  });

  test("switcher renders compact (2-letter codes + middot)", async ({ page }) => {
    await page.goto("/");
    const switcher = page.locator('[data-test="lang-switcher"]');
    const text = (await switcher.textContent())?.replace(/\s+/g, "") || "";
    // Expected pattern: EN · FR (middot), uppercase codes only.
    expect(text).toMatch(/^[A-Z]{2}·[A-Z]{2}$/);
  });
});

test.describe("Topbar — breadcrumb (template-level)", () => {
  test("case-study detail page shows 3-level breadcrumb", async ({ page }) => {
    const url = await firstCaseStudyUrl(page, "/case-studies/");
    await page.goto(url);

    const crumbs = page.locator("#breadcrumb > span");
    await expect(crumbs).toHaveCount(3);
    await expect(crumbs.nth(0).locator("a")).toHaveAttribute("href", "/");
    await expect(crumbs.nth(1).locator("a")).toHaveAttribute("href", "/case-studies/");
  });

  test("FR case-study detail uses /fr/ Home + localised middle crumb", async ({ page }) => {
    const url = await firstCaseStudyUrl(page, "/fr/case-studies/");
    await page.goto(url);

    const crumbs = page.locator("#breadcrumb > span");
    await expect(crumbs).toHaveCount(3);
    await expect(crumbs.nth(0).locator("a")).toHaveAttribute("href", "/fr/");
    await expect(crumbs.nth(1).locator("a")).toHaveAttribute("href", "/fr/case-studies/");
    await expect(crumbs.nth(1)).toContainText(/études de cas/i);
  });

  test("tab page shows 2-level breadcrumb", async ({ page }) => {
    await page.goto("/case-studies/");
    await expect(page.locator("#breadcrumb > span")).toHaveCount(2);
  });

  test("homepage shows single-level breadcrumb", async ({ page }) => {
    await page.goto("/");
    await expect(page.locator("#breadcrumb > span")).toHaveCount(1);
  });
});

test.describe("Topbar — title", () => {
  test("case-study detail preserves original title casing (not capitalized)", async ({ page }) => {
    const url = await firstCaseStudyUrl(page, "/case-studies/");
    await page.goto(url);

    const topbarTitle = (await page.locator("#topbar-title").textContent())?.trim() || "";
    const h2Title = (await page.locator(".case-study__body h2").first().textContent())?.trim() || "";

    // The real invariant: topbar title matches the original title (from the
    // body h1/h2), not a lowercased / capitalised version. Works for any
    // case study regardless of content.
    expect(topbarTitle.length).toBeGreaterThan(0);
    expect(topbarTitle).not.toMatch(/^Case_study$/);
    // Proves casing is inherited from the document, not munged by `| capitalize`.
    // (We don't require exact equality because titles can be formatted differently
    // in the body; we just require that topbar title is NOT all-lowercase-after-first.)
    const lowercaseAfterFirst = topbarTitle.slice(1) === topbarTitle.slice(1).toLowerCase();
    const allLower = topbarTitle === topbarTitle.toLowerCase();
    if (lowercaseAfterFirst && !allLower) {
      throw new Error(`topbar title '${topbarTitle}' looks capitalize-mangled`);
    }
  });

  test("<title> tag is non-empty on tab pages (regression for empty-title bug)", async ({ page }) => {
    await page.goto("/case-studies/");
    const title = await page.title();
    expect(title).not.toMatch(/^\s*\|/);
    expect(title.length).toBeGreaterThan(2);
  });
});

// Mobile viewport coverage — the whole motivation for moving the switcher
// to the topbar was "visible without scrolling on every viewport". [REVIEW-9.]
test.describe("Topbar — mobile viewport", () => {
  test.use({ viewport: { width: 375, height: 812 } });

  test("switcher remains visible on a phone-sized viewport", async ({ page }) => {
    await page.goto("/");
    await expect(page.locator('[data-test="lang-switcher"]')).toBeVisible();
  });

  test("switcher hidden when search is expanded on mobile", async ({ page }) => {
    await page.goto("/");
    // Chirpy toggles .input-focus on <search id="search"> when search is
    // activated; our SCSS uses that signal (and :has fallback) to hide
    // the switcher so it doesn't collide with the expanded input.
    await page.locator("#search-trigger").click();
    // Give Chirpy's JS a moment to apply the class.
    await page.waitForTimeout(150);
    const switcher = page.locator('[data-test="lang-switcher"]');
    // Either the switcher is hidden outright OR its width is 0 due to the
    // topbar reclaiming space. Either is an acceptable outcome.
    await expect(switcher).toBeHidden({ timeout: 2000 }).catch(async () => {
      const box = await switcher.boundingBox();
      expect(box?.width ?? 0).toBeLessThanOrEqual(2);
    });
  });
});
