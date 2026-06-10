import { Page } from "@playwright/test";

// Derives a theme×format pill combination that matches no rendered item,
// then activates it. Template-level by construction: the pick comes from
// the live DOM, so adding or retagging content can never invalidate a
// hardcoded assumption (it can only exhaust the matrix, in which case the
// caller should skip — there is no empty state to exercise).
//
// DOM contract: assets/js/filter-list.js — controls carry
// `data-test="<filtersTestId>"` with `[data-group]` pill groups; items
// carry `data-filter-item` + `data-themes` + `data-format`.
export async function activateNoMatchCombination(
  page: Page,
  filtersTestId: string,
): Promise<boolean> {
  const combo = await page.evaluate((testId) => {
    const controls = document.querySelector(`[data-test="${testId}"]`);
    const root = controls?.closest("[data-filter-list]");
    if (!controls || !root) return null;
    const pillValues = (axis: string) =>
      Array.from(controls.querySelectorAll(`[data-group="${axis}"] .filter-pill`))
        .map((b) => b.getAttribute("data-filter") || "")
        .filter(Boolean);
    const items = Array.from(root.querySelectorAll("[data-filter-item]")).map((el) => ({
      themes: (el.getAttribute("data-themes") || "").split(/\s+/).filter(Boolean),
      formats: (el.getAttribute("data-format") || "").split(/\s+/).filter(Boolean),
    }));
    for (const theme of pillValues("themes")) {
      for (const format of pillValues("format")) {
        const occupied = items.some(
          (it) => it.themes.includes(theme) && it.formats.includes(format),
        );
        if (!occupied) return { theme, format };
      }
    }
    return null;
  }, filtersTestId);

  if (!combo) return false;
  const controls = page.locator(`[data-test="${filtersTestId}"]`);
  await controls
    .locator(`[data-group="themes"] .filter-pill[data-filter="${combo.theme}"]`)
    .click();
  await controls
    .locator(`[data-group="format"] .filter-pill[data-filter="${combo.format}"]`)
    .click();
  return true;
}

// Result of activating a single pill that partially narrows the list.
export interface PartialPillResult {
  axis: string;
  value: string;
  total: number;
  expectedNarrowed: number;
}

// Derives a SINGLE pill (any axis) that matches some-but-not-all rendered
// items, clicks it, and returns the expected post-click counts. Template-
// level by construction: the pick comes from the live DOM, so retagging or
// adding content can never invalidate a hardcoded pill assumption (e.g.
// "data-ai narrows but doesn't empty the list"). It can only exhaust the
// matrix — every pill matching all items or none — in which case there is
// nothing to exercise and the caller should skip.
//
// DOM contract (assets/js/filter-list.js): within an axis the filter is OR,
// across axes AND. A single pill in axis X selects value V, so an item is
// visible iff its `data-X` attribute contains V. The expected narrowed
// count is therefore the number of items whose `data-X` includes V.
export async function activatePartialPill(
  page: Page,
  filtersTestId: string,
): Promise<PartialPillResult | null> {
  const pick = await page.evaluate((testId) => {
    const controls = document.querySelector(`[data-test="${testId}"]`);
    const root = controls?.closest("[data-filter-list]");
    if (!controls || !root) return null;
    const items = Array.from(root.querySelectorAll("[data-filter-item]"));
    const total = items.length;
    if (total === 0) return null;
    const groups = Array.from(controls.querySelectorAll("[data-group]"));
    for (const group of groups) {
      const axis = group.getAttribute("data-group") || "";
      if (!axis) continue;
      const pills = Array.from(group.querySelectorAll(".filter-pill"))
        .map((b) => b.getAttribute("data-filter") || "")
        .filter(Boolean);
      for (const value of pills) {
        const matches = items.filter((el) =>
          (el.getAttribute(`data-${axis}`) || "")
            .split(/\s+/)
            .filter(Boolean)
            .includes(value),
        ).length;
        if (matches > 0 && matches < total) {
          return { axis, value, total, expectedNarrowed: matches };
        }
      }
    }
    return null;
  }, filtersTestId);

  if (!pick) return null;
  await page
    .locator(`[data-test="${filtersTestId}"]`)
    .locator(`[data-group="${pick.axis}"] .filter-pill[data-filter="${pick.value}"]`)
    .click();
  return pick;
}
