import { defineConfig, devices } from "@playwright/test";

/**
 * delabie-tech Playwright config
 *
 * TEST_ENV selects the base URL:
 *  - local (default): jekyll-built _site served at 127.0.0.1:4000
 *  - preview: https://v2.delabie.tech
 *  - prod: https://www.delabie.tech  (only after cutover)
 *
 * Projects (current):
 *  - chromium-en only.
 *
 * The plan's full matrix (chromium-en/fr, webkit-en, iPad-en) lands in a
 * later phase once real content is in place — browser/viewport differences
 * matter most on rendered layouts, not on Phase 1 i18n scaffolding.
 * Addresses [REVIEW-23]: previous comment advertised the full matrix while
 * the array only had chromium-en.
 *
 * Note on FR coverage: the Playwright browser's Accept-Language header is
 * not used by our Jekyll static site (no server-side content negotiation);
 * language is selected by URL path (/ vs /fr/). So chromium-en is sufficient
 * to exercise both locales' rendered output.
 */

type Env = "local" | "preview" | "prod";
const TEST_ENV: Env = (process.env.TEST_ENV as Env) || "local";

const baseURLs: Record<Env, string> = {
  local: "http://127.0.0.1:4000",
  preview: "https://v2.delabie.tech",
  prod: "https://www.delabie.tech",
};
const baseURL = baseURLs[TEST_ENV];

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 2 : undefined,
  timeout: 30 * 1000,

  reporter: [
    ["html", { outputFolder: "../../playwright-report", open: "never" }],
    ["list"],
  ],

  use: {
    baseURL,
    trace: "on-first-retry",
    screenshot: "only-on-failure",
    video: "retain-on-failure",
  },

  // Phase 0 ships chromium only. The richer matrix (chromium-fr, webkit-en,
  // iPad-en) comes in later phases once the i18n layer and layout-level tests
  // need real browser coverage. This keeps CI under 5 min for the scaffolding.
  projects: [
    { name: "chromium-en", use: { ...devices["Desktop Chrome"] } },
  ],

  // When running against the local build, serve the static _site/ directory.
  // The _site/ must have been built beforehand (npm test does this; CI does this).
  webServer:
    TEST_ENV === "local"
      ? {
          command: "python3 -m http.server 4000 --bind 127.0.0.1 --directory _site",
          cwd: "../..",
          url: "http://127.0.0.1:4000",
          reuseExistingServer: !process.env.CI,
          timeout: 30 * 1000,
        }
      : undefined,
});
