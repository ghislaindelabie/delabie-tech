# delabie-tech

Parallel test site for the migration from `delabie.tech` (Jekyll + al-folio) to Chirpy + custom bilingual setup. Serves at [v2.delabie.tech](https://v2.delabie.tech). Cuts over to `delabie.tech` when migration exit criteria are met.

**Master plan:** `../ghislaindelabie/CHIRPY_MIGRATION_PLAN.md` (copy committed here once migration reaches that phase).

## Local development

```bash
bundle install          # Ruby deps
npm ci                  # Node deps (Playwright)
npx playwright install  # browsers
bundle exec jekyll serve
```

Open http://127.0.0.1:4000.

## Running tests locally

```bash
npm test                # structural + E2E (identical to CI)
```

Individual suites:

```bash
npm run test:structural          # RSpec structural checks
npm run test:e2e:local           # Playwright against localhost
npm run test:e2e:preview         # Playwright against v2.delabie.tech
```

## Workflow (summary)

Full rules in `CLAUDE.md`.

1. Branch from `main`: `feature/phase-N-slug`
2. Work TDD (red → green → refactor)
3. PR to `main`; CI must be green on all four required checks
4. Address every Claude Review + Security Review finding
5. Ghislain merges via the GitHub UI
6. Deploy fires automatically to v2.delabie.tech

## Required GitHub configuration

Configured once, then left alone:

- Secret `ANTHROPIC_API_KEY` (for Claude Review + Security Review)
- GitHub Pages source: GitHub Actions
- Custom domain: `v2.delabie.tech`
- Branch protection on `main` per `.github/branch-protection.json`
- DNS `CNAME v2.delabie.tech → ghislaindelabie.github.io`

## Status

Phase 0 — scaffolding. See `CHIRPY_MIGRATION_PLAN.md` §5.1.
