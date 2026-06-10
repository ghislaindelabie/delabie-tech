# Full-project code review — 2026-06-10

**Scope:** the complete repo source on `main` at `92f765a` (post-launch, v1.0.0) — templates, plugin, SCSS, JS, data files, both test suites, scripts, CI. Content collections in scope for mechanical defects only.
**Method:** `/code-review` max-effort methodology applied repo-wide (no diff — everything is merged): 9 independent finder angles → dedup (64 → 47 candidates) → 3-state verification → ranked findings.
**Process transparency:** all 9 finders completed. 33/47 verifications ran as independent agents (32 CONFIRMED, 1 REFUTED) before an org rate-limit stopped the run; the remaining 14 were verified by the lead reviewer inline (marked ✋). The gap-sweep phase was skipped to conserve budget — historically it adds 0–3 minor findings on top of a 9-angle pass, so the residual risk is low but non-zero.

---

## Top findings (ranked)

### 1. 🔴 HIGH — the production sitemap omits every tab page
`sitemap.xml:21` — The URL set is built from `site.pages | concat: site.posts | concat: site.case_studies | concat: site.archive`. The `tabs` **collection** (output: true) is never concatenated, and collection documents are not in `site.pages`. **Verified against the live build: 32 `<loc>` entries, zero of them `/about/`, `/cv/`, `/publications/`, `/teaching/`, `/contact/`, `/case-studies/`, `/archive/`, `/repositories/`, `/writing/`** (32 = 2 home + 2 ia-mobilite + 12 case studies + 16 archive). Live consequence: the sitemap submitted to Search Console omits the site's primary pages. They remain crawlable via nav links and hreflang, but the freshest-signal channel is materially incomplete.
**Fix:** add `{%- assign all = all | concat: site.tabs -%}` (and decide deliberately for publications/teaching if they ever gain detail pages). One line + the spec fix below.

### 2. 🔴 HIGH — sitemap_spec promises far more than it asserts (the hole that shipped #1)
`tests/structural/sitemap_spec.rb:27` — The example named "lists every bilingual content surface in both languages" only iterates `_archive/*.md`. Tabs, case studies and home are asserted nowhere, so finding #1 sailed through a green suite — twice (it also survived the cutover re-checks).
**Fix:** derive the expected URL set generically (all output-true collections + pages with permalinks, both languages) and diff it against the built sitemap. Keeps the template-level mandate: new content auto-covered.

### 3. 🔴 HIGH — case-study `<lastmod>` is build-time noise
`sitemap.xml:39` — `{%- if item.date %}<lastmod>…` relies on `Jekyll::Document#date`, which **defaults to `site.time`** for documents without a `date` frontmatter key. Case studies have `date_start`, not `date` — so all 12 case-study URLs get a `<lastmod>` equal to the moment of the deploy, rewritten on every build. Search engines learn that the value is meaningless.
**Fix:** emit `<lastmod>` only from explicit frontmatter (`date` or a mapped `date_start`), omit otherwise.

### 4. 🟠 MEDIUM — the FR-permalink incident class is still unguarded
`tests/structural/i18n_pairs_spec.rb:89` ✋ — The "FR files have /fr/ permalink" example does `next unless fm["permalink"]` — it validates the *format* of permalinks that exist, never the *requirement*. An FR file in a collection whose permalink pattern has no lang prefix (archive: `/archive/:year/:slug/`) that **omits** the explicit permalink silently collides with its EN sibling — exactly the franceculture incident of PR #30, which the build reports as a warning, not an error, so CI stays green. The guard for the one failure mode that already happened doesn't exist.
**Fix:** for collections with lang-neutral permalink patterns, require explicit `/fr/` permalinks on FR files (or fail on built-path collisions).

### 5. 🟠 MEDIUM — `lato-300` is preloaded on every page but unconsumable
`_includes/head.html:132` ✋ — The preload (added in the Phase-6 perf follow-ups, justified as "Lato 300 sets `.lead`") is wrong: `.lead` is a Bootstrap class — `font-weight: 300` with **inherited body family (Source Sans Pro)**, not Lato. No CSS rule pairs Lato with weight 300, so every page force-downloads ~23 KB it can never use, and the `fonts.scss` `@font-face` for lato-300 is dead.
**Fix:** drop the preload + the face; optionally add a real SSP-300 face if `.lead`'s synthesized weight looks off (it currently synthesizes from SSP-400 — visually fine).

### 6. 🟠 MEDIUM — broken Liquid fallback in the language switcher
`_includes/lang-switcher.html:29` — `default_lang.code | default: site.data.i18n.languages | first.code` is not valid Liquid (`first.code` is parsed as a filter argument, not a chained property). The expression happens to work today because the primary value is always present, but the fallback path would render garbage the day `_data/i18n.yml` loses its `default: true` flag.
**Fix:** `{% assign fallback = site.data.i18n.languages | first %}{{ default_lang.code | default: fallback.code }}`.

### 7. 🟠 MEDIUM — teaching resource links can never render
`_includes/teaching-item.html:57` — The partial renders links from `external_url` / `pdf` / `slides` / `video_url`, but no `_teaching` file defines those fields (they define other link fields). The "resources" affordance is dead UI for all 21 entries — content authored to surface there silently doesn't.
**Fix:** align the field contract (either rename frontmatter or the include) and add a structural check that declared resources render.

### 8. 🟠 MEDIUM — the `talk` filter pill matches nothing, by construction
`_data/publications_taxonomy.yml:25` — `publication-filters.html` renders a pill for every taxonomy format with no hide-empty logic; no publication carries `format: talk`, so the pill is a guaranteed dead end (click → empty list). The DOM-derived empty-state *test* handles this gracefully — the *UI* doesn't.
**Fix:** render pills only for formats present in the collection (one `where` filter), which also future-proofs every taxonomy addition.

### 9. 🟠 MEDIUM — `science` category allowed by spec, missing from the label map
`tests/structural/case_studies_spec.rb:15` — `ALLOWED_CATEGORIES` includes `science`, but `_data/case_study_categories.yml` has no entry for it — a future `category: science` case study passes the suite and renders the raw slug (the exact bug the map was built to prevent). The archive spec asserts taxonomy completeness; this one doesn't.
**Fix:** derive `ALLOWED_CATEGORIES` from the data file's keys (single source of truth) and assert every key has both labels.

### 10. 🟠 MEDIUM — unescaped `cover_alt` on case studies
`_layouts/case_study.html:39` — `alt="{{ page.cover_alt | default: page.title }}"` is emitted raw while the identical pattern in `archive_item.html` is escaped. Owner-authored content, so not exploitable today — but a title containing `"` breaks the attribute, and the inconsistency invites copy-paste of the unsafe variant.
**Fix:** `| escape` (match the archive layout).

### 11. 🟠 MEDIUM — email-privacy spec narrower than its promise
`tests/structural/email_privacy_spec.rb:28` — The header promises "email + phone never in **any** web-served file… HTML, JSON, sitemap, RSS, downloadable files," but the glob misses some served types (e.g. `.pdf` planned for CV/teaching artifacts, `.webmanifest`, feed XML naming variants). The invariant is the site's flagship privacy promise; its enforcement should match its words before PDFs land.
**Fix:** widen the glob to everything in `_site` minus binary images/fonts, or scan by MIME family.

### 12. 🟠 MEDIUM — hooks enforce less than CLAUDE.md claims
`scripts/hooks/pre-bash.sh:56` — CLAUDE.md states `gh pr merge` and pushes to main are "blocked by hooks"; the hook's patterns miss equivalent forms (API merges via `gh api -X PUT .../merge`, `git push origin HEAD:main`, force-push variants). Process documentation overstates the technical guard (the recent admin-merges happened through exactly such a gap).
**Fix:** either tighten the patterns or soften the CLAUDE.md claim to "guard-rail, not enforcement" — drift between stated and real controls is the actual bug.

### 13. 🟠 MEDIUM — config promises detail pages that can't exist
`_config.yml:213` — Publications and teaching comments say "optional detail pages when `has_detail_page: true`", but both collections are `output: false` — Jekyll will never route a detail page regardless of frontmatter. Several content files carry the flag in good faith.
**Fix:** delete the promise or implement it (flip output + add a layout + guard).

### 14. 🟠 MEDIUM — archive-detail spec can test the wrong document
`tests/playwright/e2e/layouts/archive-detail.spec.ts:58` — `pickArchiveItemUrl` resolves a row by grabbing the **first** `/archive/<year>/…` sitemap match for that year; with multiple same-year items it can assert against a different document than the row it started from (latent false-green/false-red as the archive grows).
**Fix:** match on the full slug, not the year prefix.

### 15. 🟠 MEDIUM — filter-narrowing tests are content-coupled again
`tests/playwright/e2e/layouts/publications.spec.ts:60` (+ teaching twin) — The "pill narrows the list" tests hardcode the `data-ai` pill and assert `0 < narrowed < total`, which breaks the day all (or no) publications are data-ai — the same content-coupling class that was fixed for the empty-state tests in PR #30.
**Fix:** derive a pill guaranteed partial from the DOM, like `activateNoMatchCombination` does.

---

## Appendix A — remaining confirmed findings

**Correctness / consistency (MEDIUM unless noted):**
- `_includes/analytics-goatcounter.html:25` — gate tests config identity, not deployment identity: any future build with the production URL (local prod builds included) renders the live counter. Cosmetic risk only because local prod builds aren't browsed; derive from `jekyll.environment` *and* host to be exact.
- `_data/locales/fr.yml:8` — manual byte-copy of the gem's `fr-FR.yml` with a "re-sync on gem bump" instruction nothing enforces; a locale key added upstream renders EN/raw silently. Candidate for a structural spec comparing key sets. (Same family: the forked `head.html` reproduces the gem's per-layout asset allowlist — re-diff on every gem bump.)
- `tests/structural/seo_spec.rb:153` — `Date.parse(fm["date"])` re-derives the `/archive/:year/` path differently from Jekyll's own date handling; divergence risk for non-ISO dates (LOW-leaning).
- `scripts/apply-branch-protection.sh:54` — instructs updating an `applied_at` field that doesn't exist in the JSON schema it ships.
- `README.md:38` — still describes the pre-solo-mode, pre-cutover world (four required checks, Claude review jobs, v2 hostname). Misleads any future contributor in the first five minutes. **Quick win.**
- `tests/playwright/e2e/components/lang-switcher.spec.ts:33` — the only coverage of `translated: false` hardcodes a content fixture (template-mandate violation; breaks when that file gains a translation).
- `tests/playwright/e2e/layouts/topbar.spec.ts:97` — dead `h2Title` locator; assertion block never reads it (a check that silently checks nothing).
- `tests/playwright/e2e/layouts/cv.spec.ts:45` ✋ — non-null assertions on `boundingBox()` (null for hidden elements) → opaque crash instead of a useful failure message if layout changes.

**Reuse / single-source-of-truth (all ✋-confirmed, LOW–MEDIUM):**
- The archive type→Schema.org mapping exists in **four** hand-synced copies (include `case`, its comment table, `seo_spec` constant, taxonomy yml).
- `publication-filters.html` and `teaching-filters.html` are byte-identical modulo the collection token — one parameterized include.
- `scripts/check-i18n-pairs.rb` re-implements all six invariants that `i18n_pairs_spec` also implements — drift guaranteed eventually; extract a shared checker that both call.
- Spec files re-derive the `_site` path under 7 constant aliases (`SITE`, `SEO_SITE`, `PERF_SITE`…) to dodge Ruby const collisions — move to `spec_helper`.
- Taxonomy allow-lists hand-duplicated in specs (`PUB_ALLOWED_*`, `TEACH_ALLOWED_*`) vs `_data/*.yml` — derive from the data files.
- The page-lang/i18n-strings lookup boilerplate is repeated in ~20 templates under 4 idioms — one `include` (or assign in `default` layout).
- The case-study meta strip (icon + label + dates expression) is duplicated between card include and detail layout.

**Simplification / dead weight (✋, LOW):**
- `Gemfile`: `jekyll-sitemap` is a no-op (custom `sitemap.xml` + custom `robots.txt` shadow both of its outputs) and `html-proofer` is never invoked by anything — two dependencies to drop (verify lockfile impact).
- `_sass/addon/phase-4.scss:283` — `.cv-split__intro/__lede/__meta` style markup that no longer exists.
- `_config.yml:259` — exclude-list drift: `docs` listed twice, `playwright-results` (never created; the real dir is `playwright-report`), `tools` (doesn't exist).
- `_data/i18n.yml` — `content_coming` + `archive_title` keys defined in both languages, referenced nowhere.
- `_includes/sidebar.html:83` — retains upstream's ~50-line contact-icons loop over a `site.data.contact` that doesn't exist.
- `_layouts/case_study.html:75` — back-link bypasses `relative_url` (works with empty baseurl; inconsistent with every other internal href).
- `tests/structural/publications_collection_spec.rb:10` — requires `type` frontmatter that no template consumes.
- `playwright.config.ts:32` — `prod` env comment still says "(only after cutover)".

**Efficiency (✋ where unmarked):**
- `package.json:11` — `npm test` performs two identical full Jekyll builds (`test` builds, then `test:e2e:local` builds again). Cut one.
- `.github/workflows/tests.yml:60` — Playwright browser re-downloaded every CI run (~110 MB); cache `~/.cache/ms-playwright` keyed on the Playwright version.

**Altitude (✋):**
- `_tabs/cv.md` + `cv.fr.md` are two hand-mirrored ~208-line HTML grids; every CV change is a parallel edit in two files (the early-career addition proved it). The deep fix: `_data/cv.yml` + one bilingual include. Largest single maintainability win available.
- `_data/case_study_categories.yml` duplicate FR-slug keys (`mobilité` mirroring `mobility`) paper over un-normalized category values — normalize at the data edge instead.
- `_includes/metadata-hook.html:60` — the aria-label DOM patch script fixes Chirpy's anchor markup after parse; a build-time content filter would fix it before.

## Appendix B — refuted during verification
- `_includes/head.html:61` (JSON-LD strip corruption scenario) — REFUTED: the split/remove_first surgery is correctly guarded for the cases that occur; the upstream-format-change risk is already covered by the fork-maintenance discipline.

## What this review did *not* cover
- The **gap-sweep phase was skipped** (budget) — moderate confidence nothing major is missing given 9-angle coverage, but second-tier footguns (encoding, glob ordering, teardown asymmetries) got less attention than the methodology prescribes.
- No build/runtime execution during verification (agents read code only); findings #1/#3/#5 were additionally confirmed against the actual `_site` output by the lead reviewer.
- Editorial content quality (out of scope by design).

## Suggested fix batches
1. **SEO hotfix (do first, ~1 h):** #1 + #3 + #2's spec. The sitemap is live-wrong today.
2. **Guards & contracts (~half day):** #4, #6–#10, #13, #14, #15, archive type-map single-sourcing.
3. **Hygiene sweep (~half day):** README, dead CSS/keys/gems/config, lato-300, CI playwright cache, double build, escape fix.
4. **Structural (when convenient):** CV → `_data/cv.yml`, filter-include unification, spec constant/taxonomy derivation, i18n boilerplate include.
