import { defineConfig, devices } from "@playwright/test";

/**
 * delabie-tech Playwright config
 *
 * TEST_ENV selects the base URL:
 *  - local (default): jekyll-built _site served at 127.0.0.1:4000
 *  - preview: https://v2.delabie.tech
 *  - prod: https://www.delabie.tech  (only after cutover)
 *
 * Projects: chromium-en, chromium-fr, webkit-en, iPad-en
 *   - English + French on chromium to catch language-specific issues
 *   - WebKit + iPad on English only for browser/viewport coverage
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

  projects: [
    { name: "chromium-en", use: { ...devices["Desktop Chrome"] } },
    { name: "chromium-fr", use: { ...devices["Desktop Chrome"], locale: "fr-FR" } },
    { name: "webkit-en", use: { ...devices["Desktop Safari"] } },
    { name: "iPad-en", use: { ...devices["iPad Pro 11"] } },
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
