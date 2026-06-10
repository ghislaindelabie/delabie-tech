# delabie.tech — project status & roadmap

**Living record for resuming work.** Last updated: 2026-06-10.

> **2026-06-10:** full-project code review done → [`docs/CODE_REVIEW_2026-06.md`](CODE_REVIEW_2026-06.md) (3 HIGH — sitemap omits all tab pages, live; fix batches at the end). A separate hub-vision strategy report (15 options, tiered) lives **in the vault** (`personal/projects/delabie-tech-website/`) — kept private because it touches career strategy.
Build-excluded (`docs/` is in `_config.yml` `exclude`) — never served publicly.

> Companion: the Claude project memory `delabie-tech-launch-plan.md` carries a
> condensed version of this for session continuity. Keep them roughly in sync.

---

## 1. Status — ✅ LAUNCHED

- **Live at https://delabie.tech (apex).** `www.delabie.tech` **301-redirects → apex.**
- **`v1.0.0` tagged** (2026-06-09) on the PR #36 merge commit.
- Migration phases **0–8 complete** (scaffolding → i18n → case studies → writing/activity/repos → CV/publications/teaching → archive → SEO → redirects+perf → cutover).
- Stack: Jekyll + `jekyll-theme-chirpy ~> 7.5.0` (gem, with a few forked `_includes`), custom plugin-free bilingual EN/FR layer, GitHub Actions → GitHub Pages.

### Live-verified at launch
indexable (no `noindex`) · canonical / hreflang / sitemap / og / Person JSON-LD all apex · **zero `www.delabie.tech` leak** in served output · GoatCounter firing · TLS valid · FR + case studies + CV + contact + legacy redirect stubs all 200 · Lighthouse ~90+ perf / **a11y 100** / CLS ≈ 0.

---

## 2. Merged PRs

| PR | What |
|----|------|
| #30 | Phase 5 SEO — Person + per-archive JSON-LD, GSC hook, GoatCounter scaffold, hreflang sitemap, email-privacy sweep |
| #31 | Content launch sprint — real About, 3 Alien case-study overviews, home hero+CTA, contact rewrite, tagline/title unification |
| #32 | CV early career (Solucom 2006, La Poste apprenticeship 2009, Greenovia 2011 — backs the "18 years" claim) |
| #33 | Phase 6 (slim) — legacy→Chirpy redirect stubs; self-hosted fonts (dropped Google origins); WebP avatar/covers; a11y 100; Lighthouse ≥90 |
| #34 | UX polish + content feedback — Alien case-study rewrites (LDS=Legal DataSpace/CNB, BnF simplified, OpenAIRE hackathon, all 2026), repos reorg, CV dates/credentials/links, dark-mode toggle → topbar, search hidden, OG banner, mobile/CV/case-study polish |
| #35 | Phase 8 production cutover (config flip to production host, robots_noindex off, GoatCounter live) |
| #36 | Canonical-host fix — flipped www → **apex** to match live serving; added `canonical_host_spec` guard |

**In flight — PR #37** (branch `content/archive-additions`): adds the RFI 2017 smart-city interview archive item (EN+FR) and unlinks the two 2017 OuiShare-era items from `maas-standards` (anachronistic). CI green; awaiting admin-merge.

---

## 3. Decisions (settled — do not re-litigate)

- **Canonical host = apex `delabie.tech`** (not www). The pre-existing apex A-records made GitHub Pages canonicalise to apex (`www` 301s to it); owner chose apex. `url`, `CNAME`, and `_data/schema_person.yml` `url` are all apex.
- **Launch = Scenario C** (hybrid): shipped on mobility strength + honest one-paragraph Alien case studies, then iterate. Done.
- **Alien client disclosure resolved**: all 3 AI case studies (OpenAIRE MCP, Gallica/BnF, LDS) are publishable with care — Claude drafts, Ghislain redacts. **LDS** = the Legal DataSpace (legal professionals, **CNB** ecosystem first; Alien provides the core tech — legal MCP servers, AI gateway, data contracts; **Copyfair** = a planned extension). All 3 dated **2026**.
- **Theme stays** (Chirpy). Only mini-optimisations — never a redesign.
- **Search is hidden** (CSS in `_sass/addon/ux-polish.scss`; DOM kept so the theme JS still initialises). Chirpy's index covers only `_posts`, which is empty. A real, "powerful enough" search must index the collections **and** be language-aware — deferred (see `KNOWN_ISSUES.md`).
- **Fonts self-hosted** (`_sass/addon/fonts.scss` + `assets/fonts/*.woff2`) — no Google Fonts origins (privacy + perf + CLS). `font-display: optional`; above-the-fold faces preloaded.
- **Dark mode auto-follows the OS** (`theme_mode` left blank → Chirpy derives from `prefers-color-scheme`); the **toggle was moved to the topbar** next to the language switcher (same `id="mode-toggle"`).
- **Analytics = GoatCounter, hosted** (cookieless, GDPR-clean). Value in `_config.yml` `analytics.goatcounter.code` = `https://delabie.goatcounter.com/count`. The include only fires on the production host.
- **Google Search Console = DNS-verified** (Domain property) → `seo.google_site_verification` stays blank (no meta-tag method needed).
- **Squash-and-merge** is the default: `main` gets one clean commit per PR; the full per-commit granularity, diffs, and review thread stay preserved on the PR. Revert/bisect operate per-feature.

---

## 4. Operational gotchas (these bit us repeatedly)

- **Branch-protection drift.** Live `main` protection still lists **3 phantom required checks** (`Claude Review (Opus 4.7)` ×, `Claude Security Review`, `Review gate`) that were removed from CI in solo-mode. So a green `Build + structural + links + Playwright` never satisfies the UI Merge button. Every merge needs **admin** (Ghislain authorized this 2026-06-05), OR run `scripts/apply-branch-protection.sh` once (Ghislain-only, interactive confirm) to push the committed single-check snapshot — note that sets `enforce_admins: true`, which then **removes** the admin bypass, so afterwards merges rely on the corrected check list.
- **Workflow OAuth scope.** The `gh` HTTPS token lacks the `workflow` scope, so pushing any branch that edits `.github/workflows/` is **rejected over HTTPS**. Push those via **SSH**: `git push git@github.com:ghislaindelabie/delabie-tech.git HEAD:refs/heads/<branch>`. (Or have Ghislain run `gh auth refresh -h github.com -s workflow` once.)
- **Dev server fights the test suite.** `scripts/dev --lan` (livereload; reachable on the tailnet, e.g. `http://100.127.169.14:4000` — LAN was blocked, Tailscale works) continuously rebuilds `_site` with a `http://0.0.0.0:4000` URL, which makes the sitemap/canonical structural specs fail spuriously. **Always `pkill -f "jekyll serve"` before a clean `JEKYLL_ENV=production bundle exec jekyll build` + `bundle exec rspec tests/structural`.**
- **Local review ritual** (repo `CLAUDE.md` honor system, replaces CI review jobs): before each PR, run the `code-reviewer` subagent + the `security-review` skill, commit `docs/security/PR-N.md`, include the Review-summary block in the PR body. Conventional commits, English, no AI mentions. Never commit to `main`; Ghislain merges.
- **Tests must stay template-level** — adding content must never require touching a test. Several content-coupled specs were de-coupled along the way (filter empty-states, tab-slug list, etc.).

---

## 5. Test & deploy facts

- CI gate (`tests.yml`, on PR): build → RSpec structural (currently **135 examples**) → lychee link-check (`--offline`) → Playwright (chromium, **~95** specs). All green at launch.
- Deploy (`build-and-deploy.yml`, on push to main): build (`JEKYLL_ENV=production`) → `actions/deploy-pages` → post-deploy **smoke test** (`scripts/verify-deploy.sh https://delabie.tech` — does **not** follow redirects, so it must target the 200-serving apex, not www).
- The structural noindex spec self-skips post-cutover (`robots_noindex` is false).
- No nightly cron in CI (the plan's "3 green nightly runs" gate was effectively waived at cutover).

---

## 6. Backlog / options (none started)

Ordered roughly by owner interest:

1. **GitHub contribution heatmap** (owner asked). Build at deploy time from the GitHub API (the Actions runner has a token) and render inline SVG/HTML — **not** third-party image embeds (github-readme-stats / ghchart / skyline), which would phone a third party per visitor and break the privacy/perf stance. Add a **weekly scheduled cron** rebuild so it refreshes without commits. ⚠️ GitHub **auto-disables scheduled workflows after 60 days of repo inactivity** (a scheduled run doesn't count as activity); for bulletproof freshness, trigger externally (P710 `gh workflow run` on a cron). Pair with featured-repo language bars on the Repositories page. *Recommended next build.*
2. **OuiShare / pre-2021 mobility & smart-city case study.** The older archive citations (RFI 2017, Autonomy Paris 2017, France Culture 2016) link to nothing because no era-appropriate case study exists. Writing one gives them a `projects:` home and fills a CV→case-study gap.
3. **Full Alien case-study write-ups** (currently one honest paragraph each).
4. **Outcome metrics** on the mobility case studies (moB, 30-LEV, MaaS — users/volumes/territories).
5. **2–3 writing posts** (the blog is empty; demonstrates AI expertise vs. asserting it).
6. **Client/partner logos + 1–2 testimonials** (BnF, OpenAIRE, ADEME, FabMob, Moovance).
7. **Designed OG banner** (current `assets/img/og-banner-1200x630.jpg` is an auto-generated placeholder on the site palette).
8. **Contact form** (Formspree default) — currently the contact page is an icon-led channel list (LinkedIn primary). Email/phone must never appear in served HTML (enforced by `email_privacy_spec`).
9. **Real bilingual search** (see `KNOWN_ISSUES.md`).
10. **300-post WordPress blog migration** — normalization scripts built & tested on samples; deferred to post-launch.
11. **CV: richer past-experience descriptions** (owner's TODO — currently terse).

---

## 7. How to resume

1. Read this file + the Claude memory `delabie-tech-launch-plan.md`.
2. `git fetch`; check open PRs (`gh pr list`) — #37 may still be awaiting merge.
3. Before testing: stop any `jekyll serve`, then `JEKYLL_ENV=production bundle exec jekyll build && bundle exec rspec tests/structural`.
4. For any change: feature branch → local code+security review → `docs/security/PR-N.md` → PR (admin-merge by Ghislain). Workflow edits push via SSH.
5. Don't re-ask about launch strategy, Alien disclosure, or apex-vs-www — all settled (§3).
