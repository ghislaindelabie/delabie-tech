# delabie.tech → Chirpy Migration Plan

**Date:** 2026-04-22
**Status:** Draft for review (v1.1 — revised after first feedback round)
**Current stack:** Jekyll + al-folio + jekyll-polyglot, deployed via GitHub Actions to GitHub Pages (`delabie.tech`)
**Target stack:** Jekyll + Chirpy (as gem, with targeted overrides) + custom bilingual Liquid helpers, deployed via GitHub Actions to GitHub Pages, with CI-based quality gates (Playwright + Claude Review + Claude Security Review)

---

## 0. Scope & guiding principles

### 0.1 What this plan does
1. Build a **parallel test repo** with the new stack that reproduces current `delabie.tech` content structure, fixes the most damaging audit findings (`/about/` 404, placeholder projects, Einstein publication, template Teaching, etc.), and serves at a test URL so the live site is never at risk.
2. Replace al-folio with **Chirpy** (gem-based, minimal overrides).
3. Replace `jekyll-polyglot` with a **plain-Jekyll bilingual pattern** (manual duplication + ~50 lines of custom Liquid + front-matter-driven language switcher and SEO tags).
4. Build a **test harness** adapted from `datastreaming-testing/` (Playwright + link-checker + structural/content validators) so we can verify parity with the current site before cutting over.
5. Execute migration **TDD-style**: tests first for each feature, implementation second, refactor third. No feature is "done" until its test is green.

### 0.2 What this plan deliberately does NOT do
- Does **not** migrate the 300-post WordPress archive, **nor the 3 legacy normalized posts**. All blog-post imports wait for the editorial-review cycle in the separate blog migration project. v1 ships with an empty (or near-empty) blog/writing section and accepts new posts written fresh after cutover.
- Does **not** fork Chirpy. Chirpy stays a gem dependency; we override individual files via Jekyll's standard theme-override mechanism.
- Does **not** introduce translation automation (editor/rewriter/trans-localiser agents per `WEBSITE_AUDIT.md` §3.7). All content stays as-is or gets hand-written case studies; agent pipelines are a later phase.
- Does **not** add DE/ES/IT yet. The i18n pattern is built to scale, but v1 ships EN + FR.
- Does **not** change the `delabie.tech` domain or any production DNS until the cutover gate.
- Does **not** add video transcriptions in v1. Publications with video get YouTube embed + short description; transcriptions and article versions come later.

### 0.3 Guiding principles (inspired by Alien's `HYBRID_TESTING_STRATEGY_PLAN.md`)
1. **Test-first, every feature.** Red → green → refactor. No merge to `main` without a green test.
2. **Parallel, not destructive.** New repo, new URL, zero risk to the live site until explicit cutover.
3. **Golden-file discipline** (carried over from `_migration/ITERATION_METHODOLOGY.md`). Compare actual output against hand-curated expected output. Every bug becomes a regression fixture.
4. **Minimal theme surface area.** Override only what's necessary; everything else stays upstream so Chirpy updates flow in via `bundle update`.
5. **Plain-Jekyll over plugins.** i18n is 50 lines of legible Liquid, not a niche plugin dependency.
6. **CI is the only safety net.** Because commits are infrequent (a few per month), we do not run live monitoring. The full test suite runs on every PR and on a weekly schedule against the deployed preview. No flaky tests tolerated — a red CI blocks merge.
7. **Tests are template-based, not content-based.** A new blog post MUST NOT require a new test. Tests assert "every post detail page has ≥1 published date, a title, a lang attribute, and a working switcher" — not "post /blog/foo/ contains the word bar". Adding content is a pure write operation.
8. **Claude Review and Claude Security Review are blocking PR checks.** Both run on Opus 4.7. Every warning must be either resolved in code or explicitly answered in a PR comment. Security Review produces a per-PR security-decision document. See §4.5.
9. **Five-pillar testing**, adapted from Alien:
   - **Availability:** URLs return 200 in both languages
   - **Quality:** no broken links, no broken images, no missing translations
   - **SEO/Structural:** correct `hreflang`, canonical, OG, Schema.org, sitemap
   - **Visual/UX:** Playwright template-level smoke tests across browsers and viewports
   - **Content parity** (during migration only): migrated pages match expected content snapshots. Retired after cutover.

---

## 1. Target architecture

### 1.1 Repo layout (new test repo)

```
delabie-tech-v2/                          # new repo, parallel to existing
├── .github/workflows/
│   ├── build-and-deploy.yml              # Jekyll build → GH Pages
│   └── tests.yml                         # Playwright + lychee + Ruby specs on every PR
├── _config.yml                           # minimal, no jekyll-polyglot
├── _config_dev.yml                       # local-dev overrides
├── Gemfile                               # jekyll-theme-chirpy, jekyll-redirect-from, jekyll-sitemap, jekyll-seo-tag, jekyll-feed
├── _data/
│   ├── navigation.yml                    # nav items per language
│   ├── i18n.yml                          # UI strings per language (footer, switcher, meta labels)
│   └── socials.yml
├── _posts/                               # flat directory (Pattern 1 — same folder suffix)
│   ├── 2026-MM-DD-mcp-enterprise.md      # lang: en, ref: mcp-enterprise
│   ├── 2026-MM-DD-mcp-enterprise.fr.md   # lang: fr, ref: mcp-enterprise
│   └── (3 normalized legacy posts, FR only for now)
├── _case_studies/                        # NEW Jekyll collection (replaces _projects/)
│   ├── openaire-mcp.md + .fr.md
│   ├── bnf-gallica.md + .fr.md
│   ├── lds-copyfair.md + .fr.md
│   ├── le-feral.md + .fr.md
│   └── (3 existing real projects ported: moB, 30LEV, MaaS-standards)
├── _publications/                        # NEW collection (replaces BibTeX)
│   └── barometre-standards-mobilite-2024.md + .fr.md
├── _teaching/                            # NEW collection (MVP: 2-3 entries, short descriptions only)
├── _tabs/                                # Chirpy convention for top-nav pages
│   ├── about.md + about.fr.md
│   ├── cv.md + cv.fr.md
│   ├── case-studies.md + case-studies.fr.md
│   ├── publications.md + publications.fr.md
│   ├── teaching.md + teaching.fr.md
│   └── writing.md + writing.fr.md
├── _includes/                            # OVERRIDES ONLY — everything else comes from Chirpy gem
│   ├── lang-switcher.html                # NEW — 15 lines of Liquid
│   ├── hreflang.html                     # NEW — 10 lines of Liquid
│   ├── head-custom.html                  # Chirpy extension point for per-page OG/Schema
│   └── (any Chirpy _includes we need to patch for page.lang vs site.lang)
├── _layouts/
│   ├── case_study.html                   # NEW layout for case-study detail pages
│   └── publication.html                  # NEW layout for publications detail pages
├── _plugins/                             # local-only Ruby plugins (don't work on GH Pages native, but we use GH Actions so OK)
│   └── i18n_filters.rb                   # Liquid filter: translated_post_url(ref, lang)
├── assets/
│   ├── img/                              # ported from current site
│   └── css/jekyll-theme-chirpy.scss      # SASS override entry point
├── tests/
│   ├── playwright/                       # E2E browser tests
│   ├── structural/                       # Ruby/Python: file presence, frontmatter validity, ref-pairing
│   └── content/                          # golden-file parity tests vs current site
├── tests/fixtures/                       # expected HTML snapshots, golden pages
├── scripts/
│   ├── new-post.sh                       # scaffolding: creates -en + -fr stubs with correct frontmatter
│   ├── check-i18n-pairs.rb               # CLI: every ref has both en + fr, or explicit `translated: false`
│   └── verify-build.sh                   # wrapper: build + structural tests + link check
├── CNAME                                 # v2.delabie.tech (test), then delabie.tech (cutover)
├── robots.txt                            # allow GPTBot, ClaudeBot, PerplexityBot, Google-Extended
├── sitemap.xml                           # auto-generated by jekyll-sitemap
└── README.md
```

### 1.2 Hosting & deployment

**Decision: new repo (Option B).** Confirmed 2026-04-22.

- **Repo name:** `delabie-tech` (descriptive, not legacy-named). Owned by `ghislaindelabie`.
- **Why the "username-matching" repo name is not required:** GitHub Pages only auto-serves the `username.github.io` URL from a repo named `username.github.io`. With a custom domain (`delabie.tech`), any repo name works. A GitHub Actions workflow builds the site and deploys to GH Pages via `actions/deploy-pages`, which publishes to the custom domain configured in repo Settings → Pages.
- **Test phase:** `delabie-tech` deploys via GH Actions → GH Pages → subdomain `v2.delabie.tech`. DNS: one CNAME record (`v2 → ghislaindelabie.github.io`), zero risk to production.
- **Cutover:** when all tests green + content parity confirmed:
  1. Switch `delabie.tech` CNAME from old repo's Pages target to new repo's Pages target.
  2. Remove `noindex` meta on the new site.
  3. Archive `ghislaindelabie/ghislaindelabie.github.com` (keep read-only for 90-day rollback window).
  4. Tag `v1.0.0` on the new repo.
- **Workflow:** `.github/workflows/build-and-deploy.yml` uses `ruby/setup-ruby` → `bundle exec jekyll build` → `actions/deploy-pages`. No GH Pages native-build magic. Matches the pattern already shipped in `ai-mobilite` branch (commit `f98cd215`).
- **CI is separate from CD.** `.github/workflows/tests.yml` runs on PR, blocks merge on failure. `build-and-deploy.yml` only runs on `main` push, only after CI has already passed.

### 1.3 Why gem-based Chirpy (not fork, not starter)

| Approach | Upstream sync cost | Override flexibility | Verdict |
|---|---|---|---|
| chirpy-starter (remote theme) | Zero (always latest) | Low — can't edit theme files | Too rigid |
| **Gem with local overrides** | `bundle update` | High — override any file by copying to site root | **Pick this** |
| Fork of theme repo | Merge upstream releases | Unlimited | Overkill + maintenance tax |

Any file we need to modify (layouts, includes, SASS) — we copy from the gem into our site and edit. Everything else stays upstream and auto-updates.

---

## 2. The custom i18n design

### 2.1 Content pattern (flat, suffix-based)

```
_posts/2026-05-10-mcp-enterprise.md        # EN (default)
_posts/2026-05-10-mcp-enterprise.fr.md     # FR

_tabs/about.md                              # EN
_tabs/about.fr.md                           # FR

_case_studies/openaire-mcp.md               # EN
_case_studies/openaire-mcp.fr.md            # FR
```

**Frontmatter contract:**
```yaml
---
title: "Article title in this language"
lang: en          # or fr
ref: mcp-enterprise    # shared across translations — the linkage key
permalink: /blog/mcp-enterprise/   # EN uses /blog/...
# FR equivalent has:
# permalink: /fr/blog/mcp-enterprise/
translated: true  # set to false if no translation exists yet — excludes from switcher
---
```

**Permalink rule** (enforced by `_config.yml` defaults + validation script):
- `lang: en` → `permalink: /<collection>/<slug>/`
- `lang: fr` → `permalink: /fr/<collection>/<slug>/`

### 2.2 Liquid helpers (the whole i18n core)

Three small files replace the Polyglot plugin:

#### `_plugins/i18n_filters.rb` (Ruby — works with GH Actions build, NOT GH Pages native)
```ruby
module Jekyll
  module I18nFilters
    def translation_of(page, target_lang)
      # Given a page hash and target lang, find the sibling page with same ref + target lang
      ref = page['ref']
      return nil if ref.nil?
      @context.registers[:site].documents.find do |doc|
        doc.data['ref'] == ref && doc.data['lang'] == target_lang
      end
    end
  end
end
Liquid::Template.register_filter(Jekyll::I18nFilters)
```

#### `_includes/lang-switcher.html`
```liquid
{%- assign langs = site.data.i18n.languages -%}
<ul class="lang-switcher">
  {%- for l in langs -%}
    {%- if l.code == page.lang -%}
      <li class="active">{{ l.label }}</li>
    {%- else -%}
      {%- assign alt = page | translation_of: l.code -%}
      {%- if alt -%}
        <li><a href="{{ alt.url | relative_url }}" hreflang="{{ l.code }}">{{ l.label }}</a></li>
      {%- else -%}
        <li class="unavailable" title="{{ site.data.i18n.strings[page.lang].no_translation }}">{{ l.label }}</li>
      {%- endif -%}
    {%- endif -%}
  {%- endfor -%}
</ul>
```

#### `_includes/hreflang.html`
```liquid
{%- for l in site.data.i18n.languages -%}
  {%- if l.code == page.lang -%}
    <link rel="alternate" hreflang="{{ l.code }}" href="{{ page.url | absolute_url }}">
  {%- else -%}
    {%- assign alt = page | translation_of: l.code -%}
    {%- if alt -%}
      <link rel="alternate" hreflang="{{ l.code }}" href="{{ alt.url | absolute_url }}">
    {%- endif -%}
  {%- endif -%}
{%- endfor -%}
<link rel="alternate" hreflang="x-default" href="{{ page.url | absolute_url }}">
<link rel="canonical" href="{{ page.url | absolute_url }}">
```

#### `_data/i18n.yml`
```yaml
languages:
  - code: en
    label: English
    flag: 🇬🇧
  - code: fr
    label: Français
    flag: 🇫🇷

strings:
  en:
    no_translation: "Not available in English"
    read_more: "Read more"
    # ... UI strings
  fr:
    no_translation: "Pas encore traduit en français"
    read_more: "Lire la suite"
```

### 2.3 Chirpy patches required

Chirpy hardcodes `site.lang` in several places. We override these files by copying them into our site's `_includes/`:

- `_includes/head.html` — replace `site.lang` with `page.lang | default: site.lang`; inject `_includes/hreflang.html`
- `_includes/sidebar.html` — inject `_includes/lang-switcher.html` near the social icons
- `_includes/footer.html` — localize footer text via `site.data.i18n.strings[page.lang]`
- `_layouts/default.html` — set `<html lang="{{ page.lang | default: site.lang }}">`

**Expected override count:** 4–6 files. All others inherited from Chirpy gem.

### 2.4 `_config.yml` defaults

```yaml
defaults:
  - scope: { path: "", type: posts }
    values:
      layout: post
      lang: en
  - scope: { path: "*.fr.md", type: posts }
    values:
      lang: fr
      permalink: /fr/blog/:slug/
  - scope: { path: "", type: case_studies }
    values:
      layout: case_study
      lang: en
  # ... same pattern for each collection
```

*(Scope path globbing in Jekyll has nuances; validation script in §5.2 enforces the pairing invariant regardless of config parsing.)*

### 2.5 Nav per language

`_data/navigation.yml` returns per-language nav arrays, consumed by Chirpy's sidebar override. `{% assign nav = site.data.navigation[page.lang] %}`.

---

## 3. Content inventory & migration mapping

### 3.1 Pages (current → new)

| Current | Status | Migrated to | Notes |
|---|---|---|---|
| `_pages/about.md` (permalink `/`) | **BUG:** `/about/` 404s, page serves at `/` | `_tabs/about.md` (permalink `/about/`) + home layout separately | Fix the 404. |
| `_pages/about-fr.md` | OK | `_tabs/about.fr.md` | |
| `_pages/blog.md` + `blog-fr.md` | OK | Chirpy's built-in `/posts/` OR `_tabs/writing.md` renamed | Rename to "Writing" per audit §3.2 |
| `_pages/cv.md` + `cv-fr.md` | Builds from rendercv YAML (issue #3587) | `_tabs/cv.md` as plain markdown + PDF link | Drop rendercv; use hand-written MD |
| `_pages/ia-mobilite.md` (+ fr) | OK, orphan (not in nav) | **Keep as orphan page** at a stable URL (`/ia-mobilite/` + `/fr/ia-mobilite/`). NOT in nav. | Used as a landing page that course descriptions / external links can point to. Preserve URL across migration. |
| `_pages/news.md` | 2 stale items | **Transform to "Recent activity"** — surfaced on homepage, not in nav. Reverse-chrono list rendered from a `_activity/` collection (short-form posts, single paragraph each). | Feeds homepage hero section. Each entry has date, title, optional link. Low-ceremony content. |
| `_pages/projects.md` + `projects-fr.md` | Points at al-folio _projects | `_tabs/case-studies.md` + `.fr.md` | Renamed per audit §3.2 |
| `_pages/publications.md` | Jekyll-scholar + BibTeX (Einstein) | `_tabs/publications.md` + `_publications/` collection | Drop jekyll-scholar |
| `_pages/repositories.md` + fr | TTalex + self-deprecating line | **Keep, restructure into 3 sections:** (1) OpenClassrooms AI Engineering — course project repos; (2) Tech stuff — personal technical projects; (3) AI-enhanced professional — mobility/Alien-related public repos. Remove TTalex. Remove self-deprecating line. | Populated from a `_data/repositories.yml` grouped by section. |
| `_pages/teaching.md` | Raw al-folio placeholder | `_tabs/teaching.md` + `_teaching/` collection | Real content needed |
| `_pages/books.md` | al-folio feature | **Drop** | Not engineer-relevant |
| `_pages/dropdown.md` | al-folio nav config | **Drop** | |
| `_pages/404.md` | 3s redirect (too fast) | Custom 404 with 10s+ or no redirect | |

### 3.2 Projects → Case Studies

| Current project | Action |
|---|---|
| `mob.md` (+fr) | **Port** to `_case_studies/mob.md` + `.fr.md`. Clean during port: refresh dates, tighten description if needed. |
| `30VELI.md` (+fr) | **Port**, fix 2023–2026 vs 2023–2025 date inconsistency. Clean during port. |
| `maas-standards.md` (+fr) | **Port**, clean during port. |
| `2_project.md` through `9_project.md` (8 files) | **Delete** — all al-folio placeholders |
| **NEW:** `openaire-mcp` | **Write** — content supplied by Ghislain. |
| **NEW:** `gallica-bnf` | **Write** — content supplied by Ghislain. |
| **NEW:** `lds-copyfair` | **Write** — content supplied by Ghislain. |
| ~~`le-feral`~~ | **Not in v1.** Deferred. |

Total target in v1: **6 case studies** (3 ported + cleaned, 3 new). Each Alien case study ships once Ghislain has provided its content; the page framework (layout, frontmatter schema, i18n pairing) ships first with a content-stub body.

### 3.3 Posts

**No post imports in v1.** All blog-post publications wait for the editorial-review cycle tracked in the separate blog-migration project. Posts are not published until cleaned.

| File | Status in repo | Action in v1 |
|---|---|---|
| `2024-12-04-photo-gallery.md` | Published (al-folio demo) | **Delete** — not real content |
| `2019-06-10-trottinette-jay-walker.NORMALIZED.md` | Untracked | **Not published in v1.** Remains in the blog-migration pipeline. |
| `2020-05-04-mobilite-urbanisme-surfusion.NORMALIZED.md` | Untracked | **Not published in v1.** |
| `2020-06-30-retour-vers-le-futur.NORMALIZED.md` | Untracked | **Not published in v1.** |
| `.NORMALIZED.NORMALIZED.md` duplicates | Test artifacts | **Delete** |
| `meteo-mobilite-ia.md` (draft) | `draft: true` | **Not published in v1.** |

**Writing section at launch:** either empty with a "coming soon" one-liner, or seeded with 1–2 fresh posts written clean for launch (Ghislain decides). The writing *framework* is fully functional so posts can be added after cutover as pure content operations — no code changes needed.

### 3.4 Publications

Replace the BibTeX bibliography with a hand-rolled `_publications/` collection. The section is explicitly a catalog of Ghislain's produced content — reports, talks, webinars, interviews, papers — with optional local artifacts (video, PDF, slides).

| Item | Action |
|---|---|
| Einstein 1920 (BibTeX) | **Delete** |
| Baromètre des standards 2024 | **Port** to `_publications/barometre-standards-mobilite-2024.md` |
| Full publication list | **Supplied later by Ghislain.** Do not guess titles. |

**Per-item schema** (finalized in Phase 4):
```yaml
---
title: "..."
date: 2024-XX-XX
venue: "..."
type: report | talk | webinar | interview | paper
lang: en | fr
ref: unique-slug
external_url: https://...      # optional, e.g. YouTube
pdf: /assets/pdf/...            # optional
video:                          # optional
  youtube_id: "xxx"
  self_hosted: /assets/video/... # optional .mp4 for small videos
slides: /assets/pdf/...          # optional
short_description: "One-paragraph summary"
co_authors: []                   # optional
tags: [...]
transcript: false                # v1 default; flip to true later when transcripts are produced
---
{{ long_description_body }}
```

**Video hosting strategy for v1:**
- **Primary:** YouTube embed, referenced by `youtube_id`.
- **Optional self-hosted:** small `.mp4` (<30 MB / 480p) committed to repo under `assets/video/`, used as `<video>` fallback. Only where the video is short and high-value.
- **Deferred:** Cloudflare R2 / Bunny / S3 CDN fallback. Only re-evaluate when the library exceeds ~10 items per the audit guidance.
- **No transcripts in v1.** Transcription pipeline ships in a later phase.

Publications detail pages (one per item) are built from `_layouts/publication.html` and share a common template — adding a new publication is pure content (no template changes, no test changes).

### 3.5 Teaching

**Default:** each course ships with a short description (a few lines) and a summary. That is the baseline for v1 — no PPT-derived auto-generation.

**Optional detail subpage:** where Ghislain has enough material, a course can have its own detail page (`/teaching/{slug}/` + `/fr/teaching/{slug}/`) with a longer description, learning outcomes, and related-content links. Courses without a detail page still get a stable URL that external references can link to.

**External resources per course (optional, any subset):**
- `external_url` — course homepage on the institution's site
- `pdf` — handout, syllabus, or main document
- `slides` — slide deck
- `video` — lecture recording

All external-resource links are optional; they render only when populated.

**Per-course schema:**
```yaml
---
title: "..."
institution: "..."
years: [2024, 2025]
level: undergrad | grad | pro | exec
hours: 12
role: lead | co | guest
lang: en | fr
ref: unique-slug
short_description: "..."
external_url: https://...     # optional
pdf: /assets/pdf/...           # optional
slides: /assets/pdf/...        # optional
video_url: https://...         # optional
has_detail_page: false         # if true, body is rendered as a detail page
tags: [ai, mobility, data]
---
{{ optional_long_description }}
```

Adding a new course = one new markdown file (plus optional `.fr.md`). No test changes.

### 3.6 CV

- **Port existing CV first** (EN + FR) to `_tabs/cv.md` + `cv.fr.md`. Content is preserved as-is initially.
- **Drop `rendercv` YAML pipeline** (known-broken, issue #3587) — replace with plain markdown.
- **Update during the migration process** — during Phase 4, Ghislain revises content to reflect current Alien role and recent developments. The migration is the natural moment to refresh, not a separate task.
- **Include PDF download link** — generated via browser print-to-PDF through a `print.scss` stylesheet (simplest, no toolchain). Regenerated on significant updates.
- **Reframe per audit §3.1** during the update pass: remove "transitioning into AI Engineering" language; replace with a present-tense frame that bridges 18 yrs of mobility product work into current Alien Intelligence AI-infrastructure work.

### 3.7 Assets (images)

- Copy `assets/img/posts/` and any real project images from current repo to new repo.
- **Drop** `assets/img/1.jpg` through `/12.jpg` (al-folio demo images).
- Keep `pic_ghislain_color.jpg` and any real working images.
- New case studies need new cover images (TBD during writing).

### 3.8 SEO & meta — expanded scope

SEO is a first-class goal of the migration, not a toggle at the end. The plan budgets real design effort here. A parallel SEO optimization task (run by Ghislain outside this plan) feeds in requirements; this migration surfaces structural slots for them.

**3.8.1 Baseline (from first build, no exceptions):**
- `serve_og_meta: true` and per-page OG overrides (title, description, image).
- `serve_schema_org: true` — Chirpy's Person schema is the starting point.
- Default `og_image` (site-wide card), plus per-page override slot.
- Site-wide `description`, `keywords`, language, twitter handle.
- `robots.txt` allowing GPTBot, ClaudeBot, PerplexityBot, Google-Extended (see §3.9).
- `sitemap.xml` via `jekyll-sitemap`, customized to include hreflang alternates for every multilingual URL.
- RSS/Atom feed via `jekyll-feed`, per-language.
- Analytics: Plausible recommended (no cookie-consent overhead, GDPR-simple). GA4 available if preferred — gated behind a consent banner we add.
- Fix typo: `contact_note: "dedicatd"` → `"dedicated"`.

**3.8.2 Schema.org — full usage per content type:**

| Content type | JSON-LD types to emit |
|---|---|
| Home / About | `Person` (Ghislain) + `Organization` (Alien Intelligence, La Fabrique des Mobilités as `affiliation`) |
| Case studies | `CreativeWork` or `SoftwareApplication`, with `author: Person`, `about: Thing`, `mentions: Organization` |
| Publications → Reports | `Report` or `ScholarlyArticle`, `author`, `publisher`, `datePublished`, `url` |
| Publications → Talks | `PresentationDigitalDocument` or `VideoObject` (when video present), `performer`, `recordedAt: Event`, `uploadDate`, `embedUrl`, `thumbnailUrl`, `duration` |
| Publications → Interviews | `InterviewObject` with `interviewer`, `interviewee` |
| Publications → Papers | `ScholarlyArticle` |
| Teaching courses | `Course` (`name`, `provider: Organization`, `educationalLevel`, `timeRequired`, `teaches`, `inLanguage`) |
| Posts / Writing | `BlogPosting` or `Article` with `author`, `datePublished`, `dateModified`, `headline`, `image`, `articleSection` |
| CV | `Person` extended with `alumniOf`, `worksFor`, `knowsAbout`, `jobTitle`, `sameAs` (LinkedIn/GitHub/etc.) |
| Repositories page | `CollectionPage` listing `SoftwareSourceCode` items |

Each JSON-LD block lives in `_includes/schema/{type}.html` as a partial and is included by the relevant layout. Adding a new content type = adding one partial + wiring it from the layout; not a broader schema rewrite.

**3.8.3 Cross-linking strategy (feeds homepage + reciprocal hubs):**

Every content page surfaces *related* entries via a shared include (`_includes/related.html`). Relations are declared in frontmatter (`related_case_studies`, `related_publications`, `related_posts`, `related_teaching`, `related_repos`). This turns each page into an internal-link hub and spreads link equity across the site.

Homepage structure (revised): hero + recent activity + 3 featured case studies + latest publication + latest post + CTA. Every element is dynamic (collection-driven), so the homepage refreshes as content is added without template changes.

**3.8.4 Social & external alignment (tracked in a companion checklist):**
- LinkedIn profile tagline matches site tagline
- GitHub bio + pinned repos align with Repositories page structure
- Twitter bio consistent
- `sameAs` URLs in Person schema point at all of the above

The full SEO optimization task (Ghislain, in parallel) produces a specific list of keywords, internal-link additions, and off-site signals to align; this plan guarantees the *structural slots* exist to implement anything that task surfaces.

**3.8.5 Preview-site precaution:**
Until cutover, `v2.delabie.tech` serves a `<meta name="robots" content="noindex">` on every page (configured via site-wide default). Removed at cutover in one commit.

### 3.9 robots.txt & AI crawlers

Per audit §3.6 "Robots policy":
```
User-agent: *
Allow: /

User-agent: GPTBot
Allow: /

User-agent: ClaudeBot
Allow: /

User-agent: PerplexityBot
Allow: /

User-agent: Google-Extended
Allow: /

Sitemap: https://www.delabie.tech/sitemap.xml
```

---

## 4. Testing methodology (CI-first, template-based, AI-reviewed)

### 4.1 Design principles

Because the site is static with infrequent commits (a few per month), testing is **100 % CI-driven**. No live production monitoring. No cron-based nightly runs in v1 (added later if we see flakiness). Tests run on every PR; merges are blocked until green.

The single most important property: **adding content must not require updating tests.** If Ghislain adds a blog post or a case study, zero test files change. This is enforced by making every Playwright assertion template-level ("every case-study detail page has X, Y, Z") rather than content-level ("post /blog/foo/ contains bar"). Exceptions are called out explicitly in §4.3.

### 4.2 Five-pillar adaptation

| Pillar | Applied to static site | Tool | Runs on |
|---|---|---|---|
| **Availability** | Build succeeds; homepage + nav routes return 200 in both languages | `scripts/verify-build.sh` + Playwright smoke | PR |
| **Quality** | No broken internal links; no broken images; no missing alt text on images flagged as decorative-not | `lychee` + HTMLProofer + RSpec | PR |
| **SEO / Structural** | Valid `hreflang`, canonical, OG, Schema.org per layout; sitemap coverage; `robots.txt` correct | RSpec + custom validator | PR |
| **Visual / UX (template-level)** | Each *layout* renders correctly across browsers + viewports; shared components (nav, switcher, footer, related) behave across pages | Playwright | PR |
| **AI Review** | Claude Review flags code smells, regressions, unfixed warnings | Claude Code GH Action (Opus 4.7) | PR — blocking |
| **AI Security Review** | Claude Security Review documents security posture per change | Claude Security Review GH Action (Opus 4.7) | PR — blocking |

Content parity (golden snapshots against the live site) runs only during the migration window to verify ported pages. Retired after cutover.

### 4.3 Template-based testing — what this means concretely

Tests target **page-type templates**, not individual content items. Example test spec tree:

```
tests/playwright/e2e/
├── layouts/
│   ├── home.spec.ts                # homepage hero + recent activity + featured CS
│   ├── tab-generic.spec.ts         # every _tabs/* page has nav, switcher, footer, canonical
│   ├── case-study-detail.spec.ts   # foreach case-study: title, cover, category, related, schema.org JSON-LD
│   ├── publication-detail.spec.ts  # foreach publication: date, venue, optional video embed, related
│   ├── teaching-detail.spec.ts     # foreach teaching item WITH detail page: institution, summary
│   ├── post-detail.spec.ts         # foreach post: date, title, switcher, related
│   └── 404.spec.ts                 # 404 page loads, doesn't auto-redirect in <10s
├── components/
│   ├── nav.spec.ts                 # nav items per language; active state
│   ├── lang-switcher.spec.ts       # switcher present; clicking FR goes to /fr/ pair; unavailable state renders
│   ├── related.spec.ts             # related-links block renders when frontmatter populated
│   └── footer.spec.ts              # footer content + socials
└── cross-cutting/
    ├── seo.spec.ts                 # every indexable page has OG, canonical, schema JSON-LD valid
    ├── accessibility.spec.ts       # axe-core on every layout sample
    ├── no-orphan-translations.spec.ts  # all /fr/ URLs have an EN counterpart referenced in lang switcher
    └── no-noindex-after-cutover.spec.ts # after cutover, no page carries noindex (would reveal a mistake)
```

**Foreach patterns:** `case-study-detail.spec.ts` iterates `_site/case-studies/**/index.html` at test time. A new case study added next month runs through the same assertions automatically.

**Content-specific assertions, when unavoidable:** a small `tests/content/critical-pages.spec.ts` covers the handful of pages where exact content is contractually important (home hero copy, CV structure, nav items, footer copyright). These are explicitly marked as content-level tests and updated when their content is revised. Kept under 10 assertions total.

### 4.4 Directory structure (mirroring `datastreaming-testing/`)

```
tests/
├── playwright/
│   ├── e2e/                        # see §4.3
│   ├── fixtures/
│   │   └── layout-samples.json     # one sample URL per layout, for lightweight a11y + SEO sampling
│   └── playwright.config.ts        # projects: chromium-en, chromium-fr, webkit-en, iPad-en
├── structural/                     # Ruby RSpec
│   ├── test_i18n_pairs.rb          # every content file has a .fr.md pair OR explicit translated: false
│   ├── test_frontmatter.rb         # required fields per collection; types valid
│   ├── test_permalinks.rb          # EN has no /fr/, FR has /fr/ prefix
│   ├── test_sitemap.rb             # every content page in sitemap with hreflang alternates
│   ├── test_robots.rb              # AI crawlers allowed
│   ├── test_schema_present.rb      # every layout emits the right JSON-LD type
│   └── test_no_stale_content.rb    # no al-folio placeholder strings (“Every project has a beautiful feature showcase page…”, “Replace this text…”)
├── content/
│   ├── test_critical_pages.rb      # the <10 content-level assertions
│   └── test_migration_parity.rb    # RETIRED AFTER CUTOVER: snapshots vs live delabie.tech
├── scripts/
│   ├── run-all-tests.sh
│   ├── serve-and-test.sh           # jekyll serve + wait + playwright + kill
│   ├── run-locally.sh              # one-command local test suite — identical to CI
│   └── verify-deploy.sh            # post-deploy smoke against v2.delabie.tech
└── findings/                       # human-readable issues surfaced by Claude Review / manual review
    └── YYYY-MM-DD-slug.md
```

### 4.5 Claude Review and Claude Security Review — mandatory PR checks

Two blocking CI checks, both running on **Claude Opus 4.7**. Both are configured as required status checks in branch-protection rules on `main`; a PR cannot merge without both green (or with documented overrides).

#### 4.5.1 Claude Review (general code review)

**Action:** `anthropics/claude-code-action` (official Claude Code GitHub Action), configured to run on every PR open/synchronize.
**Model:** `claude-opus-4-7`.
**Scope:** Reviews the full diff. Flags bugs, regressions, anti-patterns, unused code, unclear names, brittle tests, violations of plan conventions.
**Policy (per Ghislain's feedback):** "Not every item is mandatory to solve, but the PR must contain an answer to each Claude Review warning." Enforced in CI via a gate script:

- Claude Review posts findings as a structured PR comment with each finding tagged (e.g., `[REVIEW-1]`, `[REVIEW-2]`).
- A gate workflow (`.github/workflows/review-gate.yml`) checks that each `[REVIEW-N]` has at least one of: (a) a commit that references the tag, (b) a PR reply comment that quotes the tag and provides a response, or (c) a `wontfix` label with a justification comment.
- If any `[REVIEW-N]` is unanswered, the check fails.
- Ghislain (or a delegate) is the only one who can mark a finding `wontfix`.

#### 4.5.2 Claude Security Review (dedicated security pass)

**Action:** Claude Security Review (invoked via the `security-review` skill in Claude Code, run as a GH Action step using the same Opus 4.7 model, separate from Claude Review so its findings are not conflated).
**Model:** `claude-opus-4-7`.
**Scope:** Security-specific review — OWASP top-10-adjacent issues, secret leakage, CSP/headers misconfiguration, third-party script risks, dependency vulnerabilities, authentication edge cases (N/A for a static site but still checked by the pass), data leakage through build artifacts or metadata.
**Deliverable per PR:** a `docs/security/PR-{number}.md` file auto-generated by the action, committed back to the branch, documenting:
- Changes reviewed
- Security-relevant decisions made (and why)
- Risks accepted (and why)
- Recommended follow-ups

The presence and non-emptiness of this file is a CI check. The file is part of the permanent record; after cutover, `docs/security/` becomes an audit trail.

**Policy:** every Security Review finding must be resolved in code OR explicitly risk-accepted with a documented rationale in the security decision document. No unanswered security findings allowed — this is stricter than the general review policy.

#### 4.5.3 Combining with structural + Playwright + lychee checks

The full CI chain on every PR, in order:

1. **Build** (`jekyll build`) — fast fail if Jekyll breaks.
2. **Structural** (RSpec) — fast fail on invariant violations.
3. **Link check** (`lychee --offline _site/`) — fast fail on broken internal links.
4. **Playwright** (e2e against a jekyll-serve'd local build) — browser-level validation.
5. **HTMLProofer** (or axe-core via Playwright) — accessibility + HTML validity.
6. **Claude Review** (Opus 4.7) — posts findings; review-gate enforces responses.
7. **Claude Security Review** (Opus 4.7) — posts findings + produces `docs/security/PR-{n}.md`.
8. **Review-gate** — fails if any Claude finding is unanswered.

Steps 1–5 fail fast and cheap. Steps 6–8 run in parallel with each other but after 1–5 pass (no point asking an LLM to review broken code).

### 4.6 Playwright config adaptation

Adapted from `datastreaming-testing/playwright.config.ts`:

- `TEST_ENV`: `local` (localhost:4000, default in CI and local) | `preview` (v2.delabie.tech) | `prod` (delabie.tech after cutover)
- Projects: `chromium-en`, `chromium-fr`, `webkit-en`, `iPad-en`. Cross-language rendering is mostly identical, so we don't duplicate every project across both languages — `chromium-{en,fr}` covers language differences, `webkit-en` + `iPad-en` cover browser/viewport differences.
- No auth layer (public static site).
- Trace on first retry, screenshot on failure, video retained on failure (same as Alien).
- HTML + JSON + list reporters (same as Alien).

### 4.7 Local testing — parity with CI

The same scripts run locally. `npm run test` (or `make test`) reproduces CI exactly — build, structural, link check, Playwright, HTMLProofer — so Ghislain can run the full suite locally before pushing. Claude Review and Claude Security Review run only in CI (they need the PR context).

### 4.8 GitHub Actions workflows

`.github/workflows/tests.yml` — runs on every PR:
```yaml
name: Tests
on: pull_request
jobs:
  build-and-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with: { bundler-cache: true }
      - run: bundle exec jekyll build
      - run: bundle exec rspec tests/structural
      - run: bundle exec rspec tests/content
      - uses: lycheeverse/lychee-action@v2
        with: { args: '--offline _site/' }
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
      - run: npx playwright install --with-deps chromium webkit
      - run: npm run test:e2e:local
      - run: npm run test:a11y
  claude-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          model: claude-opus-4-7
          mode: review
  claude-security-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          model: claude-opus-4-7
          mode: security-review
          output_file: docs/security/PR-${{ github.event.pull_request.number }}.md
  review-gate:
    needs: [claude-review, claude-security-review]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: scripts/ci/review-gate.sh
```

`.github/workflows/build-and-deploy.yml` — runs only on `main` push, after tests are green:
```yaml
name: Build & Deploy
on:
  push: { branches: [main] }
permissions:
  pages: write
  id-token: write
jobs:
  deploy:
    environment: { name: github-pages, url: ${{ steps.deployment.outputs.page_url }} }
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with: { bundler-cache: true }
      - run: bundle exec jekyll build
      - uses: actions/upload-pages-artifact@v3
      - id: deployment
        uses: actions/deploy-pages@v4
```

### 4.9 Bootstrap CI from Day 1

**Critical per Ghislain's feedback:** the CI goes in from Phase 0, not bolted on later. The very first PR on the new repo (the scaffolding PR) includes:
- Both workflows above
- The empty test directory structure with at least one trivial passing test per file
- Branch protection rules on `main` requiring all checks green
- The `ANTHROPIC_API_KEY` secret configured

This guarantees good practices are in place before any real content ships, and that no PR ever merges to `main` without the full quality gate exercised. Tests grow with the codebase; the scaffolding is in place from commit #1.

### 4.10 Test-findings discipline

Adopted from Alien's pattern — `tests/findings/` for any bug that isn't trivially fixed in the same PR. Each finding:

```markdown
---
id: FIND-001
discovered: 2026-05-02
severity: low | medium | high | blocker
status: open | fixed | wontfix
source: claude-review | claude-security-review | manual | playwright
---
## What
## Why it matters
## Repro
## Root cause (if known)
## Fix / workaround
```

Findings inform the plan without gating PRs (unless blocker-severity).

### 4.11 Branch discipline, CLAUDE.md, and Claude Code hooks

Because execution is intentionally parallelized (Ghislain reviews phase N while I build phase N+1 — see §5.0), branch discipline is the safety mechanism that prevents unreviewed work from reaching `main`. Three layers of enforcement, in order of authority:

#### 4.11.1 GitHub branch-protection rules (server-side, authoritative)

Configured on the `main` branch of `delabie-tech`:
- **Require a pull request before merging.** No direct commits to `main`, ever, by any actor.
- **Require status checks to pass before merging:** `build-and-check`, `claude-review`, `claude-security-review`, `review-gate`. All four must be green.
- **Require branches to be up to date before merging** (prevents stale merges that bypass tests).
- **Dismiss stale pull request approvals when new commits are pushed** (optional — mostly relevant if Ghislain reviews via GitHub UI and I then push new commits).
- **Do not allow bypassing the above settings**, including for repo admins. This is the hard guardrail.
- **Restrict who can push to matching branches:** none (nobody can force-push `main`).
- **Allow force-pushes on feature branches only.** Useful for me to rewrite/squash during development without polluting history.

These rules are configured via `gh api` in the Phase 0 setup and live in a versioned `.github/branch-protection.json` snapshot for auditability.

#### 4.11.2 CLAUDE.md in the repo root

A CLAUDE.md file, modeled on `datastreaming-testing/CLAUDE.md`, captures the workflow rules for any Claude Code agent (including me) operating on the repo. Required sections:

```markdown
# CLAUDE.md — delabie-tech

## Git workflow (hard rules)
- NEVER commit directly to `main`. Always work on a `feature/*`, `fix/*`, `docs/*`, or `hotfix/*` branch.
- NEVER force-push to `main`.
- EVERY change reaches `main` through a pull request that has all CI checks green.
- Wait for Ghislain's feedback on phase N before merging phase N+1 (see plan §5.0).

## Commit guidelines
- Conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `perf:`, `security:`, `test:`, `refactor:`.
- No AI/Claude mentions in commit messages or PR descriptions.
- Keep commits atomic.
- Never commit secrets or `.env` files.

## PR policy
- Every PR must answer each Claude Review finding (§4.5.1).
- Every PR must have a non-empty `docs/security/PR-{n}.md` from Claude Security Review (§4.5.2).
- Every PR must reference the phase it belongs to and the plan section that defines its exit gate.

## Allowed operations
- All git operations except push to main, force-push to main, and config changes.
- All `gh` CLI operations except `gh pr merge` on a PR that hasn't met all gates.
- `bundle`, `npm`, `jekyll`, `rspec`, `playwright`, `lychee` as defined in the test suite.
- Reading files anywhere in the repo; writing files only where the phase scope allows.

## Restricted operations
- Never push to `main`.
- Never run `git reset --hard` on `main` without explicit Ghislain approval.
- Never modify GH branch-protection rules.
- Never commit API keys, secrets, or local state files.
- Never skip hooks (`--no-verify`, `--no-gpg-sign`) without explicit Ghislain approval.
```

#### 4.11.3 Claude Code hooks (`.claude/settings.json`)

Hooks provide a second enforcement layer at the tool-call level. These fire before Claude Code executes risky commands, blocking them if they violate the rules.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "command": "scripts/hooks/pre-bash.sh",
        "description": "Block direct main commits, pushes, force-pushes, hook skipping"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "scripts/hooks/post-write.sh",
        "description": "Warn on edits to protected paths (.github/workflows, branch-protection.json)"
      }
    ]
  },
  "permissions": {
    "allow": [
      "Bash(git status:*)", "Bash(git diff:*)", "Bash(git log:*)",
      "Bash(git add:*)", "Bash(git commit:*)", "Bash(git push origin feature/*:*)",
      "Bash(git push origin fix/*:*)", "Bash(git push origin docs/*:*)",
      "Bash(git checkout -b feature/*:*)",
      "Bash(gh pr create:*)", "Bash(gh pr view:*)", "Bash(gh pr list:*)",
      "Bash(bundle exec:*)", "Bash(npm run:*)", "Bash(npx playwright:*)"
    ],
    "deny": [
      "Bash(git push origin main:*)",
      "Bash(git push --force*)",
      "Bash(git commit --no-verify:*)",
      "Bash(gh pr merge:*)",
      "Bash(gh api -X PATCH /repos/*/branches/main/protection*)",
      "Bash(gh api -X DELETE /repos/*/branches/main/protection*)"
    ]
  }
}
```

`scripts/hooks/pre-bash.sh` parses the command, rejects any `git push` targeting `main`, any `--force` on a push, any `--no-verify` on a commit, and any `gh pr merge` (Ghislain merges PRs, not me — unless explicitly delegated for a specific PR).

Why three layers and not just one:
- **Branch protection** is the real safety net (server-side, cannot be bypassed).
- **CLAUDE.md** documents intent — what agents *should* do — and is visible in every conversation where I work on the repo.
- **Hooks** catch mistakes before they reach GitHub, producing faster and clearer feedback than waiting for CI to reject.

Redundancy is intentional. A single layer failing is fine; two failing simultaneously would require a deliberate override.

---

## 5. TDD execution sequence

Each phase = one feature branch, one PR, red-green-refactor cycle.

### 5.0 Per-phase collaboration protocol (parallelized)

The goal is to let Ghislain review phase N while I build phase N+1 — never blocking on each other, never letting unreviewed work stack up. The cadence, per phase:

1. **I open a feature branch** `feature/phase-N-<short-name>` from current `main`.
2. **TDD loop on the branch:** red → green → refactor for each feature in the phase's scope.
3. **I open a PR** against `main` once the phase's exit gate is met locally.
4. **CI runs** — build, structural, Playwright, lychee, a11y, Claude Review (Opus 4.7), Claude Security Review (Opus 4.7), review-gate.
5. **I address every Claude Review / Security finding** per §4.5 policy, either in code or with a documented PR comment, until the review-gate check goes green.
6. **When all required checks are green, I ping Ghislain with the PR URL.** I do NOT merge. Ghislain clicks Merge in the GitHub UI. This is intentional: branch protection is strong against accidents, not against a malicious or rushed actor; keeping the merge click in Ghislain's hands makes the rule uniform across pre- and post-cutover, and adds one human gate to every deployment at negligible cost (~8 clicks total across the migration).
7. **Ghislain merges on green CI.** Deployment to `v2.delabie.tech` fires automatically. Ghislain's ping-back to me confirms the URL is up OR requests fixes.
8. **While Ghislain reviews phase N, I start phase N+1 on a new feature branch.** I do all the TDD work up to and including the PR. CI can run. But the PR stays open, unmerged.
9. **Ghislain returns feedback on phase N.** Three possible outcomes:
   - **(a) Approved as-is:** I merge phase N+1 (now that its premise is confirmed stable).
   - **(b) Small fixes needed on phase N:** I open `fix/phase-N-<issue>` from `main`, apply fixes, merge to `main`. Then I rebase phase N+1 onto the updated `main` and merge.
   - **(c) Significant rework of phase N:** I abandon phase N+1's PR (or park it), rebuild phase N, and we re-synchronize before resuming forward progress.
10. **Repeat** for N+1, N+2, …

**Invariant:** I never have more than one unmerged feature branch awaiting Ghislain's review at the same time. If phase N is unreviewed and phase N+1's PR is also ready, I wait rather than open phase N+2 — otherwise a rework of N cascades and wastes work.

**Why Ghislain-clicks-Merge rather than Claude-auto-merges (Option A, decided 2026-04-22):**
- Branch protection with `Do not allow bypassing` = ON is strong protection against mistakes (mine or Ghislain's) but zero protection against a malicious actor holding admin credentials. Since I run with Ghislain's `gh` CLI credentials, I inherit his admin powers — any merge I make could technically be forced through. Keeping the merge click in a human hand removes that risk class entirely.
- Uniform rule across pre- and post-cutover means no "rule change" moment at cutover (previously §5.9).
- Cost is ~8 clicks total across the migration — negligible.
- CI remains the authoritative correctness gate. Ghislain's click is an integrity gate, not a correctness one.

**Communication channels:**
- Each phase's PR description links to the plan section(s) it implements and lists the exit-gate checks.
- Ghislain's review comes back either as PR-review comments (if still open) or as a plain message if already merged.
- Any finding that doesn't warrant a fix becomes a `tests/findings/*` entry per §4.10.

### 5.1 Phase 0 — Scaffolding, CI, and **live V0 website** (Day 1)

**Goal:** end Phase 0 with a **publicly-viewable V0 of the site** running default Chirpy at `v2.delabie.tech`, reached exclusively through the full CI/CD pipeline. Everything afterwards is incremental customization on top of a working, deployed, test-gated site.

Red (tests written first, all failing):
- `tests/structural/test_smoke.rb`: the built site has an `index.html`.
- `tests/playwright/e2e/layouts/home.spec.ts`: the homepage at the deployed URL returns 200 and has a `<title>` tag.
- `scripts/hooks/test-hooks.sh`: verifies the Claude Code pre-bash hook rejects `git push origin main` (runs in CI via a dry-run matrix).
- `tests/structural/test_branch_protection.rb`: queries `gh api` to assert the required branch-protection rules are set on `main`.

Green — in this order, on `feature/phase-0-scaffolding`:
1. Create the new `delabie-tech` repo on GitHub (private initially, flipped to public at cutover).
2. Initialize local repo, install Chirpy via `Gemfile`:
   ```ruby
   gem "jekyll", "~> 4.3"
   gem "jekyll-theme-chirpy", "~> 7.0"
   gem "jekyll-redirect-from"
   gem "jekyll-sitemap"
   gem "jekyll-seo-tag"
   gem "jekyll-feed"
   group :test do
     gem "rspec"
     gem "html-proofer"
   end
   ```
3. Copy Chirpy's starter `_config.yml`, `_tabs/`, `index.html` into the repo as baseline. Minimal edits: site title, URL (`https://v2.delabie.tech`), `url` / `baseurl`.
4. Add `CNAME` file with `v2.delabie.tech`.
5. Add site-wide `<meta name="robots" content="noindex">` (preview precaution per §3.8.5).
6. Write `.github/workflows/tests.yml` and `.github/workflows/build-and-deploy.yml` per §4.8, wired to Chirpy out of the box.
7. Write `CLAUDE.md` per §4.11.2.
8. Write `.claude/settings.json` per §4.11.3 with the hooks script at `scripts/hooks/pre-bash.sh`.
9. Write the minimal test scaffolding (empty RSpec + empty Playwright + one passing trivial test per file, so CI exercises the full pipeline).
10. Configure GitHub branch-protection rules on `main` per §4.11.1 via `gh api`; snapshot to `.github/branch-protection.json`.
11. Add `ANTHROPIC_API_KEY` repo secret (Ghislain provides).
12. Configure the custom domain `v2.delabie.tech` in GitHub Pages settings; add the DNS CNAME (one-time by Ghislain).
13. Open PR; CI runs end-to-end including Claude Review + Security Review; address findings; merge PR.
14. Deploy workflow publishes to `v2.delabie.tech`; post-deploy smoke test (`scripts/verify-deploy.sh v2.delabie.tech`) runs and must pass.

Refactor:
- Extract repeated CI steps into a composite action if duplication appears.
- Confirm local-dev parity: `bundle exec jekyll serve` + `npm run test` reproduces CI.

**Exit gate — all of the following simultaneously:**
- [ ] `v2.delabie.tech` returns 200 and shows the default Chirpy homepage.
- [ ] Full CI (`tests.yml`) is green on the merged PR.
- [ ] `build-and-deploy.yml` ran successfully against `main`.
- [ ] Branch-protection rules verified on `main`.
- [ ] `docs/security/PR-1.md` exists and was generated by Claude Security Review.
- [ ] The hook scripts correctly block a simulated `git push origin main`.
- [ ] Ghislain has been pinged with the preview URL and confirmed it loads for him.

After merge + ping, I immediately open `feature/phase-1-i18n` and start TDD work on the i18n layer per §5.2, **without waiting for Ghislain's feedback on Phase 0** (per §5.0, I can build ahead; I just can't merge Phase 1 until Phase 0 feedback is in).

### 5.2 Phase 1 — Custom i18n (Days 2–3)

Red:
- Write `tests/structural/test_i18n_pairs.rb`: for every content file, assert there's a paired `.fr.md` (or explicit `translated: false`).
- Write `tests/playwright/e2e/i18n.spec.ts`: lang switcher present; clicking FR goes to `/fr/...`; `hreflang` tags correct; `<html lang>` matches `page.lang`.
- Both tests red.

Green:
- Write `_plugins/i18n_filters.rb`.
- Write `_includes/lang-switcher.html`, `_includes/hreflang.html`.
- Copy Chirpy's `head.html`, `sidebar.html`, `footer.html`, `default.html` into local `_includes/` / `_layouts/`, patch for `page.lang`.
- Create `_tabs/about.md` + `.fr.md` as first paired content.
- Tests green.

Refactor:
- Extract repeated patterns to `_includes/`.
- `scripts/check-i18n-pairs.rb` CLI for local dev.

**Exit gate:** i18n pair invariants hold; lang switcher works end-to-end in Playwright; `hreflang`/canonical/HTML-lang all correct for both languages; PR merged; `v2.delabie.tech` auto-redeployed with the switcher visible on every page; Ghislain pinged.

### 5.3 Phase 2 — Content model (Days 4–5)

Red:
- `test_case_study_snapshots.rb`: golden HTML for 3 existing projects (moB, 30LEV, MaaS) — fails.
- `test_frontmatter.rb`: required fields on case studies (title, lang, ref, category, year, cover).
- Playwright: case-studies index page shows 3 cards, filterable by category; detail pages render.

Green:
- Define `_case_studies/` collection in `_config.yml`.
- Write `_layouts/case_study.html`.
- Port 3 existing projects (deleting the 8 al-folio placeholders).
- Add 4 stub `.md` files for the Alien case studies (frontmatter only; body TBD per §9.1 gate).
- Write `_tabs/case-studies.md` + `.fr.md` as index/filterable grid.

Refactor:
- Shared partials for case-study cards (index and "related" sections).

**Exit gate:** case-studies collection renders in both languages; category filter works; golden snapshots match for 3 real projects; PR merged; `v2.delabie.tech/case-studies/` is live with 3 ported + 3 stub Alien entries; Ghislain pinged.

### 5.4 Phase 3 — Writing framework + Recent Activity + Repositories (Day 6)

No post imports. Build the *framework* so posts can be added after cutover as pure content operations. Build the homepage-feeding activity collection. Build the restructured Repositories page.

Red:
- Template-level Playwright: `post-detail.spec.ts` asserts every post (even a stub test post) renders title, date, switcher, related block.
- Template-level Playwright: `home.spec.ts` asserts homepage shows ≥1 activity entry, ≥3 featured case studies, latest publication section.
- `test_repositories.rb`: the Repositories page renders 3 sections (OC, Tech, AI-enhanced pro), zero reference to TTalex, zero self-deprecating strings.

Green:
- Create `_tabs/writing.md` + `.fr.md` (index). Post layout inherited from Chirpy, extended with switcher + related.
- Create `_activity/` collection. Schema: `date`, `title`, `body` (single paragraph), optional `link`. Homepage pulls the last 5 entries reverse-chrono.
- Seed `_activity/` with 2–3 entries announcing the new site.
- Create `_tabs/repositories.md` + `.fr.md` driven by `_data/repositories.yml` with 3 sections.
- Populate `repositories.yml` with Ghislain's current repos grouped by section.
- Delete the `2024-12-04-photo-gallery.md` demo post. Leave the normalized legacy posts untouched in the current repo — they stay in the blog-migration project.

Refactor:
- Shared `_includes/repo-card.html` for Repositories rendering.
- Shared `_includes/activity-item.html` for recent activity.

**Exit gate:** writing index renders (empty state OK); homepage hero + recent activity + featured case studies render; Repositories page has 3 real sections; no al-folio placeholder strings anywhere (`test_no_stale_content.rb` green); PR merged; `v2.delabie.tech` home, `/writing/`, `/repositories/` all live; Ghislain pinged.

### 5.5 Phase 4 — CV + Publications + Teaching (Days 7–8)

Red:
- `test_cv_sections.rb`: required CV sections present; no "transitioning" language; contains Alien role.
- `test_publications.rb`: no Einstein; ≥ 1 real entry; correct hreflang.
- Playwright: CV page renders in EN and FR; PDF download link works.

Green:
- Write `_tabs/cv.md` + `.fr.md` in plain markdown.
- Generate initial PDF via Pandoc or browser print-to-PDF; commit to `assets/pdf/`.
- Create `_publications/` collection; port Baromètre; add ≥3 talk entries (DSS26, Tech & Fest, GFII) with YouTube embeds, short descriptions only.
- Create `_teaching/` collection with 2–3 entries.

Refactor:
- Shared date-formatting filter; pull all hard-coded dates into frontmatter.

**Exit gate:** CV, Publications, Teaching all render in both languages with real (not placeholder) content; PR merged; `v2.delabie.tech/cv/`, `/publications/`, `/teaching/` all live; Ghislain pinged.

### 5.6 Phase 5 — SEO & quality pass (Day 9)

Red:
- `test_seo.rb`: OG tags present on every page; canonical set; Schema.org JSON-LD on about/case-studies.
- `test_sitemap.rb`: sitemap includes every content page across both languages with hreflang annotations.
- lychee: zero broken internal links.

Green:
- Set `serve_og_meta: true`, `serve_schema_org: true`, `og_image`, Schema.org Person + Organization (Alien).
- Customize `jekyll-sitemap` template to emit `<xhtml:link rel="alternate">` per page.
- Wire GA4 behind a consent banner include.
- Fix `contact_note` typo.

Refactor:
- Extract all SEO logic to `_includes/seo-extras.html`.

**Exit gate:** PageSpeed Insights ≥ 90; all SEO tests green; Google Rich Results Test passes on home + one case study; PR merged; `v2.delabie.tech` has full SEO stack live; Ghislain pinged.

### 5.7 Phase 6 — Pre-cutover parity sweep (Day 10)

Deployment is no longer a distinct phase — since Phase 0 every merge has been deploying to `v2.delabie.tech`. Phase 6 is the final sweep comparing `v2.delabie.tech` against live `delabie.tech` to make sure nothing was dropped silently.

Red:
- `tests/content/test_migration_parity.rb`: for every URL on current `delabie.tech` that we promised to preserve (per §3.1 page mapping), assert there is an equivalent URL on `v2.delabie.tech` returning 200 with matching canonical title.
- `scripts/build-redirect-map.rb`: produces `_data/redirects.yml` for any URLs that changed shape; fails if any old URL maps to nothing.

Green:
- Audit the mapping table in §3.1 against real URLs on production (`curl`-driven).
- Populate `_data/redirects.yml` with every old-path → new-path mapping.
- Add `jekyll-redirect-from` entries where old slugs changed.
- Run Google Search Console on `v2` (verify ownership) to catch indexation issues early.
- Run Lighthouse on home + one case study + one publication; target ≥ 90 across all four categories.

**Exit gate:**
- [ ] Every preserved URL on old site has a corresponding URL on `v2.delabie.tech`.
- [ ] Redirect map complete, every entry tested by Playwright.
- [ ] Lighthouse ≥ 90 on sampled pages.
- [ ] No open `blocker` or `high` findings in `tests/findings/`.
- [ ] Parity-test retirement commit queued for post-cutover (those tests go away since the comparison target disappears).

### 5.8 Phase 7 — Parity review + cutover decision (Day 11+, async)

- Ghislain reviews v2 side-by-side with production.
- Open findings in `test-findings/`.
- Cutover conditions (checklist):
  - [ ] All automated tests green for 3 consecutive nightly runs
  - [ ] Zero open `severity: blocker` findings
  - [ ] Ghislain's manual sign-off on every page
  - [ ] At least 2 Alien case studies with real content (not stubs)
  - [ ] 301 redirect map drafted for any URL shape changes from legacy site

### 5.9 Phase 8 — Cutover (Day N)

- Generate the final 301 redirect map from Phase 6 via `jekyll-redirect-from`.
- DNS swap: `delabie.tech` → new repo's GH Pages deployment.
- Remove `noindex` meta in one commit; verify on live.
- Submit new `sitemap.xml` to Google Search Console; file a Change-of-Address request pointing from the old repo's Pages URL to `delabie.tech` if helpful.
- Archive `ghislaindelabie/ghislaindelabie.github.com` (read-only, 90-day rollback window).
- Tag `v1.0.0` on new repo.

**Collaboration rule at cutover:** no change. Option A (Ghislain clicks Merge) has applied since Phase 0, so the cutover doesn't require a rule flip. Branch protection stays with `Do not allow bypassing` = ON; Claude Review + Security Review + review-gate continue as blocking; Ghislain continues to be the one who clicks Merge.

---

## 6. Tooling to install

| Tool | Purpose | Install |
|---|---|---|
| Ruby 3.2+ | Jekyll runtime | rbenv / ruby-install |
| `jekyll-theme-chirpy` | theme | Gemfile |
| `jekyll-seo-tag`, `jekyll-sitemap`, `jekyll-redirect-from`, `jekyll-feed` | SEO + redirects + RSS | Gemfile |
| `rspec` | Ruby structural tests | Gemfile (dev group) |
| `html-proofer` | HTML validity + link check (alternative/supplement to lychee) | Gemfile |
| Node 20+ | Playwright runtime | nvm |
| `@playwright/test` | E2E browser tests | package.json |
| `lychee` | fast link checker | cargo or action |
| `difftastic` | tree-aware diff (carried from `_migration/ITERATION_METHODOLOGY.md`) | brew |
| `pandoc` + `wkhtmltopdf` (or `weasyprint`) | CV → PDF | brew |

---

## 7. GitHub Pages compatibility

Decision: **GitHub Actions build + GitHub Pages deploy** (not GH Pages native build).

Why:
- GH Pages native build only allows whitelisted plugins. Our `_plugins/i18n_filters.rb` is custom Ruby — **not allowed** in native build.
- The `ai-mobilite` branch already ships a working GH Actions workflow (commit `f98cd215`). We reuse the pattern.
- Benefit: any Jekyll plugin, any Ruby version, any build step is allowed.
- Cost: Actions minutes (free tier plenty for this scale).

If we ever want to go native-only, we have two fallbacks:
1. Rewrite `i18n_filters.rb` as pure Liquid (Jekyll's `where` filter can substitute for `translation_of` at some readability cost).
2. Generate the translation linkage at pre-build time into a `_data/translation_map.yml` via a script.

Keeping the option open; not exercising it in v1.

---

## 8. Risks & mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Chirpy gem breaking change during development | Medium | Medium | Pin exact version in Gemfile; document upgrade process. |
| Custom i18n breaks a Chirpy feature we haven't tested (search, TOC, comments) | Medium | Medium | Each Chirpy feature gets an explicit Playwright test; we catch regressions on `bundle update`. |
| GH Actions quota / performance | Low | Low | Build + tests < 3 min; well under limits. |
| DNS cutover misconfiguration | Low | High | Pre-test with a staging subdomain; keep TTLs short (300s) during cutover window; rollback = DNS revert. |
| SEO loss during cutover (URL changes, new site in index) | Medium | Medium | 301 redirect map for every changed URL; keep stable permalinks where possible; submit new sitemap + change-of-address in Search Console. |
| Alien case studies not approvable in time | Medium | Medium | Case-study framework ships stubs; real content fills in incrementally; NOT a blocker for cutover if ≥2 exist. |
| `rendercv` replacement (plain MD CV) loses features | Low | Low | Acceptable tradeoff; rendercv is already broken (#3587). |
| Bilingual SEO misconfiguration (duplicate content penalty) | Low | Medium | `hreflang` tests catch 99% of this; Google Search Console monitoring post-cutover. |
| Chirpy's opinions fight us somewhere we don't expect | Medium | Low | Same risk we have with al-folio today; tests surface regressions early. |

---

## 9. Decisions log and remaining open questions

### 9.1 Resolved (from feedback round 1, 2026-04-22)

| # | Decision | Status |
|---|---|---|
| Repo strategy | **Option B** — new repo `delabie-tech`, parallel, DNS cutover when ready | ✅ Confirmed |
| ia-mobilite page | Keep as orphan with stable URL, not in nav | ✅ Confirmed |
| News section | Becomes "Recent activity" on homepage, not in nav | ✅ Confirmed |
| Repositories page | Keep, clean, restructure into 3 sections (OC / Tech / AI-enhanced pro) | ✅ Confirmed |
| Projects in v1 | 3 current (cleaned) + OpenAIRE + LDS + Gallica; no Le Féral | ✅ Confirmed |
| Posts in v1 | No legacy post imports; blog-migration project owns post publication | ✅ Confirmed |
| Publications list | Framework only in v1; Ghislain supplies item list | ✅ Confirmed |
| Video transcription | Not in v1; deferred | ✅ Confirmed |
| Teaching default | Short description + optional detail subpage + optional external resources | ✅ Confirmed |
| CV approach | Port existing, update during migration | ✅ Confirmed |
| SEO priority | First-class; schema.org per content type; parallel SEO task feeds requirements | ✅ Confirmed |
| Testing strategy | CI-only, template-based, Claude Review + Claude Security Review blocking on PR, Opus 4.7 | ✅ Confirmed |
| CI from Day 1 | All workflows + branch protection in place before any real content ships | ✅ Confirmed |

### 9.2 Still open — Alien client disclosure (blocker for the 3 new case studies)
Which of OpenAIRE MCP / LDS / Gallica can be published, and at what depth? This gates the *content* of those pages, not the *framework*. Framework ships first; content fills in as Ghislain provides it. **Action: Ghislain resolves with Alien stakeholders; no CI/migration work blocked.**

### 9.3 Still open — small tooling picks (low stakes)

| # | Question | Recommendation | Decide before |
|---|---|---|---|
| a | Analytics: Plausible vs GA4 vs Umami vs GoatCounter | Plausible (GDPR-simple, no banner needed) | Phase 5 |
| b | Search: Chirpy's local search (default ON) vs Algolia | Keep local | Phase 4 |
| c | Comments: Giscus ON/OFF | OFF in v1 (reduce surface area) | Phase 4 |
| d | Chirpy override depth — abort threshold | If >15 files overridden, pause and reassess theme | Phase 1 |
| e | Branch convention | `feature/*`, `fix/*`, `docs/*`, `hotfix/*`, no AI mentions in commits (mirror Alien's `CLAUDE.md`) | Phase 0 |
| f | PDF-CV toolchain | **Two outputs.** *Public* PDF (if any): browser print-to-PDF via `print.scss`, sourced from public `resume.json` (no email/phone). *Private* PDF (with email + phone): local-only script reading from gitignored `resume.private.json`, never built or hosted by the site. Revisit print quality only if it fails the bar. | Phase 4 |
| g | `_activity/` collection cadence | User-driven, no minimum. Homepage shows "Recent activity" only if ≥1 entry in last 6 months; otherwise collapses. | Phase 3 |
| h | Language roadmap | EN + FR only in v1; i18n pattern accepts DE/ES/IT additively later | Confirmed default |
| i | Contact form provider | Formspree (default) or Web3Forms (no signup) — see §13 | Phase 5 |

---

## 10. Deliverables summary

At the end of this plan's execution:

1. A new repo (`delabie-tech-v2` or chosen name) on GitHub, publicly visible.
2. Live preview at `v2.delabie.tech` with full content parity + fixes vs. current site.
3. A passing test suite (Playwright + RSpec + lychee) running on PR and nightly.
4. A `test-findings/` directory with any open issues discovered during migration.
5. A cutover checklist (§5.7) with every item ticked.
6. A 301 redirect map for the URL shape changes.
7. This plan updated with lessons learned and a short "v2 retrospective" appendix.

---

## 11. What I need from you before starting execution

Most big decisions are resolved (§9.1). Remaining items to close before Phase 0:

1. **Approve this v1.1 plan** or request another revision round.
2. Confirm §9.3 sub-picks (analytics, search, comments, branch conventions) — or delegate them to me with a default choice per the recommendation column.
3. Alien case-study content (§9.2) — can trickle in during Phases 2–4; not Phase 0 blocker.

Once 1 is resolved (and defaults accepted for 2), I move to the self-review pass (v1.2) and then Phase 0.

---

## 12. Appendix — review cycle

Per your instruction, this plan follows a three-step review:

1. **You read this plan**, challenge assumptions, request changes. I revise.
2. When you approve, I **self-review and criticize once more**, produce an improved v2 of the plan (including expanded tests — per-phase test specs with concrete assertions, not just intent), and show it to you.
3. Only after v2 is approved do I begin TDD execution starting at Phase 0.

The self-review in step 2 will specifically look for: load-bearing assumptions I haven't validated, premature abstractions, tests that describe intent rather than behavior, and hidden dependencies between phases.

---

## 13. Appendix — contact form options (Phase 5)

**Constraint** — destination email *and* phone number must never appear in built HTML, in JSON served by the site, in feeds, in downloadable files hosted by the site, or anywhere else a public visitor or scraper can reach. Inbound contact routes through a hosted form-service endpoint whose config holds the destination address; the site only knows the public action URL or access key.

A résumé PDF that includes email + phone is allowed **only as a locally-generated, privately-distributed file** — Ghislain produces it on his own machine and emails it to recipients of his choice. The PDF is never committed, never hosted on `delabie.tech`, never linked from any page, and never produced by the public CI pipeline. Source data for the private PDF lives in a **gitignored** local file (e.g. `resume.private.json`); the public `assets/json/resume.json` keeps the personal-detail fields empty.

### 13.1 Hosted form services (recommended)

| Service | Free tier | Signup required | Notes |
|---|---|---|---|
| **Formspree** | 50 submissions/mo | Yes | The Jekyll-blog default. Spam filter, file uploads, email + webhook destinations. Mature. |
| **Web3Forms** | Unlimited (per-IP cap) | No (just an access key) | Lighter trust footprint but genuinely free. |
| **Formcarry** | 100/mo | Yes | Polished UX, autoresponder built in. |
| **Formspark** | 250 lifetime → paid | Yes | One-time payment model, no recurring. |

### 13.2 Booking link in lieu of (or alongside) a form

Cal.com or Calendly. If most inbound is "let's talk", a booking link skips the form entirely. Pairs well with a form: form for written messages, link for meetings.

### 13.3 Self-hosted endpoint

Cloudflare Worker or Vercel serverless function receiving the POST and forwarding to inbox. Adds infra to maintain. Skip unless zero third-party dependency is a hard requirement.

### 13.4 Recommendation

**Formspree** as default; **Web3Forms** as fallback if signup friction matters. Either takes ~10 min in Phase 5: a `<form action="..." method="POST">` block on a new `/contact/` page (and `/fr/contact/`), wired into the nav and the footer's "contact" affordance. Add a CAPTCHA later only if spam materialises.

### 13.5 Phase 5 deliverables (form sub-task)

- New `/contact/` and `/fr/contact/` pages with the chosen provider's form markup.
- `contact_form_endpoint` in `_config.yml` (Formspree URL) or `contact_form_access_key` (Web3Forms) — value committed is the endpoint identifier, not the email.
- Replace any "Contact" affordance on `/cv/`, footer, etc. with a link to `/contact/`.
- Test (`tests/forms/test_contact.rb`): the rendered HTML contains zero `mailto:` links, zero `tel:` links, zero email-shaped strings, and zero phone-shaped strings (regex covers `+33` and `0[67]…` French formats).
- Test: the form's `action` attribute is non-empty and points at the configured provider.
