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
