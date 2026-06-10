# delabie-tech

Personal site of Ghislain Delabie — a bilingual (EN/FR) Jekyll + Chirpy build.
Live in production at **[https://delabie.tech](https://delabie.tech)** (apex host;
`www.delabie.tech` 301-redirects to it).

**Stack:** Jekyll + [`jekyll-theme-chirpy`](https://github.com/cotes2020/jekyll-theme-chirpy)
(gem, with a few forked `_includes`), a custom plugin-free bilingual EN/FR layer,
GitHub Actions → GitHub Pages.

For the full project state, decisions, and roadmap, see
[`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md).

## Local development

```bash
bundle install          # Ruby deps
npm ci                  # Node deps (Playwright)
npx playwright install  # browsers
```

Use the dev loop for UI / content iteration — it rebuilds and live-reloads on
any file change:

```bash
scripts/dev             # serves http://127.0.0.1:4000 (EN) and /fr/
scripts/dev --lan       # also bind 0.0.0.0 for LAN/phone preview
```

Stop any running `jekyll serve` before a clean build or the structural specs
(sitemap/canonical) can fail spuriously:

```bash
pkill -f "jekyll serve"
JEKYLL_ENV=production bundle exec jekyll build
```

## Running tests locally

```bash
npm test                # build + structural (RSpec) + E2E (Playwright)
```

Individual suites:

```bash
npm run test:structural          # RSpec structural checks
npm run test:e2e:local           # Playwright against a local build
npm run test:e2e:preview         # Playwright against v2.delabie.tech (opt-in)
```

Tests are **template-level**: they operate over layouts and components, not
specific content. Adding a publication, case study, or archive item must never
require touching a test. Every new layout or component gets its own
template-level test under `tests/playwright/e2e/`.

## Workflow (summary)

Full rules in [`CLAUDE.md`](CLAUDE.md).

1. Branch from `main` (`feature/…`, `fix/…`, `docs/…` — never commit to `main`).
2. Run the **local review checklist** before opening a PR (code review +
   security review, findings answered) — see the "Local review workflow"
   section of `CLAUDE.md`.
3. Open a PR. CI must be green on the single required check:
   **`Build + structural + links + Playwright`**.
4. Ghislain reviews and merges via the GitHub UI.
5. Deploy fires automatically on push to `main` → `https://delabie.tech`,
   followed by a post-deploy smoke test (`scripts/verify-deploy.sh`).

## GitHub configuration

Configured once, then left alone:

- GitHub Pages source: GitHub Actions.
- Custom domain (apex): `delabie.tech`, committed in `CNAME`.
- Branch protection on `main` per `.github/branch-protection.json`.
- Analytics: GoatCounter (cookieless), fires only on the production host.
