# delabie.tech — Audit & Scenarios

**Date:** 2026-04-15
**Site:** https://www.delabie.tech (Jekyll/al-folio, bilingual EN/FR via Polyglot)
**Repo:** github.com/ghislaindelabie/ghislaindelabie.github.com
**Current branch:** `ai-mobilite` (3 commits ahead of `main`, unmerged)

This document synthesizes four parallel audits: (1) site history & documentation, (2) live site page-by-page review, (3) personal-branding strategy for an AI-engineer positioning, (4) blog consolidation process. Each topic ends with **scenarios** so you can review and decide next steps.

---

## 0. TL;DR

### What's actually on fire right now
1. **`/about/` returns 404 in both EN and FR.** Navigation says "About" but the page does not exist. Any LinkedIn/email link pointing there is broken. **Highest-damage item.**
2. **7 of 11 projects are al-folio template placeholders** ("Every project has a beautiful feature showcase page…", Unsplash stock photos, Bootstrap tutorial code). A recruiter sees template noise drowning 3 real projects.
3. **Blog has zero real posts** — the only published entry is `"a post with image galleries"` (demo). Homepage promises "fresh posts on AI use cases" — not delivered.
4. **Publications page still contains Einstein's "Relativity" (1920)** as a placeholder.
5. **Teaching page is raw al-folio placeholder** ("Replace this text with your description.") in both languages.
6. **Alien Intelligence appears nowhere on the site.** The most interesting current work (OpenAIRE MCP, BnF, LDS, Le Feral) is invisible.

### What's surprisingly solid
- `BLOG_MIGRATION_PLAN.md` (23k) + `NORMALIZATION_SCRIPT_DEV_PLAN.md` (26k) are genuinely comprehensive and current. Scripts in `_migration/scripts/` are production-ready and tested on 3 reference articles.
- WordPress export is done: 303 posts, 30 pages, 487 images (328 MB) sitting in `wp-import/` ready to process.
- Bilingual plumbing (Polyglot) works; the 3 real project detail pages (moB, 30 LEV, MaaS) are genuinely well-translated.
- `ai-mobilite` branch has real new content (Mistral Vibe guide, Vibe Coding workshop) ready to ship.

### What this document argues
- **Branding:** Scenario 2 (Reframed Portfolio) — recommended
- **Blog migration:** Scenario A + incremental B — recommended
- **Cleanup:** do the cheap P0 fixes this week regardless of which branding scenario you pick

---

## 1. What's been done and what's planned (history audit)

### 1.1 Phases completed
| Phase | Status | Evidence |
|---|---|---|
| WordPress export | ✅ Done | 303 posts in `wp-import/…/output/posts/` |
| Normalization scripts (Features A–G) | ✅ Done | `_migration/scripts/normalize.py`, 7 utility modules, tested on 3 ref articles |
| Bilingual plumbing (Polyglot EN/FR) | ✅ Done | `_config.yml`, page variants, language switcher |
| Domain & deploy | ✅ Live | `delabie.tech` via CNAME, GitHub Pages |
| IA & Mobilité section (new) | ✅ Done on `ai-mobilite` | Mistral Vibe guide + Vibe Coding workshop, unmerged |
| Phase 4 bilingual tagging on imported posts | ⬜ Pending | Only 3 posts imported |
| Phase 5 LLM enhancement | ⬜ Not started | Deferred by plan |
| Phase 6 validation | ⚠️ Partial | Link check done on test set only |

### 1.2 Unmerged branches
- **`ai-mobilite` (current)** — 3 commits ahead of `main`. Contains workshop guides and clean GH Actions deploy workflow. **Decision needed: merge to main?**
- **`feature/blog-migration`** — contains normalization scripts + 3 normalized articles. **Decision needed: merge or keep isolated?**
- **`content`**, **`feature/0.2.0-dependency-updates`** — older feature branches, status unclear
- Upstream al-folio is ~50 commits ahead; local patches for `jekyll-imagemagick` and `jekyll-polyglot` were applied during the last sync

### 1.3 Open issues / red flags
- **#3587 CV page broken** — `rendercv` YAML not building
- **#3583 CSS display** — `_layouts/book-review.liquid` lines 220/245
- **#3565 Docker setup broken** — missing gems
- **`_site/` and `_site_clean/` (193 MB combined) are checked into the repo.** Should be in `.gitignore`.
- Duplicate folders with " 2" suffix: `assets 2`, `bin 2`, `lighthouse_results 2`, `readme_preview 2` (Finder/iCloud artifacts).
- Duplicate normalized posts in `_posts/`: `*.NORMALIZED.md` and `*.NORMALIZED.NORMALIZED.md` (leftovers from testing).
- **35 drafts in `_drafts/`** — roughly 23 are al-folio template examples, 12 appear to be genuine WIP. Needs triage.

---

## 2. Live site audit (content & consistency)

### 2.1 Critical findings (blocking credibility)

| # | Page | Issue |
|---|---|---|
| 1 | `/about/` (EN + FR) | **HTTP 404.** Navigation points here but the page does not exist. |
| 2 | `/projects/` | **7 template placeholders** publicly visible (Projects 2–9). Stock photos, tutorial text, Unsplash external links. |
| 3 | `/blog/` | **No real content.** Only published post is `"a post with image galleries"` (Dec 2024 demo with PhotoSwipe CDN stock photos). |
| 4 | `/teaching/` | **Raw template placeholder** ("Materials for courses you taught. Replace this text…") in both EN and FR. |

### 2.2 Major issues

- **Einstein placeholder** on `/publications/` alongside the real 2024 mobility standards baromètre entry.
- **French nav bug** — the French menu links to `/publications/` (no `/fr/` prefix), so the page loads with English UI inside a French shell.
- **Repositories page shows a colleague's GitHub** (`TTalex` = Alex Bourreau, FabMob tech lead) alongside Ghislain's two accounts. Also contains self-deprecating line *"Je débute encore dans le code — mes stats le montrent !"* — undercuts the AI-engineer positioning.
- **Untracked drafts** — trottinette, mobilite-urbanisme-surfusion, retour-vers-le-futur, meteo-mobilite-ia exist in `_posts/` but are not published.

### 2.3 Minor issues

- Homepage "latest post" highlights the sample demo.
- News section has 2 items, both from site launch (May 21, 2025), nothing in 11 months since.
- `30 LEV` project date inconsistent (index says 2023–2025, detail page says 2023–2026).
- `/fr/cv/` serves English CV body text inside French shell.
- 404 page auto-redirects after 3s (too fast to read).

### 2.4 Overall positioning read
Tagline *"AI engineer. Data innovator. Sustainable-mobility expert."* is strong. CV backs it up (18 yrs, solid technical skills). But the site undermines the tagline in three ways: (a) blog promises thought leadership, delivers nothing; (b) Repositories page highlights PO past with a "beginner coder" disclaimer; (c) 7 template projects dilute the 3 genuinely impressive real ones.

---

## 3. Personal-branding upgrade plan

### 3.1 Current vs. target positioning

| | Current reads as | Should read as |
|---|---|---|
| Headline | "AI engineer. Data innovator. Sustainable-mobility expert." | *"AI engineer building data infrastructure for mobility, science, media, and energy."* |
| Subtitle | (mobility affiliations only) | *"Head of AI Solutions at Alien Intelligence. I connect AI agents to premium knowledge sources."* |
| Industries visible | Mobility only | Mobility + Science + Media/Culture + Energy (aspirational) |
| CV framing | *"transitioning into AI Engineering"* | Present-tense authority; remove "transitioning" |
| Alien | Absent | Featured prominently, linked to alien.club |

### 3.2 Recommended IA (does NOT add industry vertical pages)

Rationale: vertical pages × 2 languages = 8 thin pages to maintain. Use tags/categories within existing sections instead.

| Page | Current | Proposed |
|---|---|---|
| Home/About | Generic intro | New hero + 4 industry badges + Alien one-liner + CTA to case studies |
| Projects → **Case Studies** | 3 real + 7 template | Delete placeholders; add **OpenAIRE MCP**, **BnF/Gallica**, **LDS/Copyfair**, **Le Feral**. Categorize by vertical. |
| CV | "Transitioning" framing | Lead with current Alien role; remove apologetic language |
| Blog → **Writing** or **Insights** | 3 old FR posts + demo | Rename; publish 2–4 new thought-leadership posts; keep archive |
| Teaching | Template placeholder | **Becomes a real section** — flat list of teaching assignments with short descriptions (content coming from you). Optional: long descriptions auto-drafted from PPTs where quality allows. See §3.6. |
| AI & Mobilité | Orphan (not in nav) | Link from nav or from Teaching |
| Repositories | 3 accounts incl. colleague | Remove colleague's; remove self-deprecation; OR remove page from nav |
| Publications | Einstein placeholder | **Redefined as "Publications & Talks"** — catalog of reports, conference talks, webinars, with detail pages and (optionally) self-hosted video copies + polished transcripts for SEO. See §3.6. |

### 3.3 Site-worthy Alien case studies (ranked)

1. **OpenAIRE MCP** — 150M+ scientific publications exposed to AI agents via MCP. Technical depth + European open-science impact.
2. **BnF / Gallica** — France's national library as data partner. "Diffuseur" model, 3-yr contract. Prestige + concrete outcome.
3. **LDS / Copyfair Data Contracts** — AI-era copyright infrastructure. EU Data Reservation Layer consortium. Policy/standards angle.
4. **Le Feral / France 2030** — AI infrastructure for a 1000-year art/AI collective. Memorable, unusual, shows range.
   Secondary: bTV/CME, Techniques de l'Ingénieur, Renault.

### 3.4 Quick SEO wins (all in `_config.yml`)

- `serve_og_meta: true` (currently false)
- `serve_schema_org: true` (currently false) — adds JSON-LD Person schema
- Set `og_image` to a professional headshot/card
- Wire up `google_analytics` (GA4)
- Register with Google Search Console
- Fix typo in `contact_note`: "dedicatd" → "dedicated"

### 3.5 Scenarios — **branding & structure**

#### Scenario B1 — Minimal Polish (2–3 days)
Rewrite hero/tagline (EN+FR), delete 6 placeholder projects, populate OR remove Teaching, enable OG/Schema/GA, fix `contact_note` typo, rewrite CV summary (remove "transitioning").
- **Skips:** new case studies, new blog posts, visual changes, Alien content.
- **Risk:** still thin. Still mobility-only visible. Alien invisible.
- **Converts:** people who already know you.

#### Scenario B2 — Reframed Portfolio **(RECOMMENDED)** (2–3 weeks)
Everything in B1, plus:
- 4 new case studies (OpenAIRE, BnF, LDS, Le Feral) from a shared template (Problem / Approach / Stack / Impact / Lessons).
- Project categories changed to `ai-data-infrastructure`, `mobility`, `media-culture`, `science`.
- 2 blog posts: (a) *"What MCP means for enterprise data"* (b) *"From mobility data to AI infrastructure"*.
- "About Alien" section on home or dedicated page.
- Horizontal project cards with category color pills (uses existing `projects_horizontal.liquid`).
- Credentials section (AFNOR, ESTACA, Challenges Top 100, GFII, DSS26, Tech & Fest).
- Full SEO pass; social alignment (LinkedIn/GitHub/Twitter mirror site tagline).
- **Risk:** needs sustained writing + Alien sign-off on client references.
- **Converts:** prospects post-introduction; supports Alien bizdev directly.

#### Scenario B3 — AI Engineer's Playground (6–8 weeks)
Everything in B2, plus:
- Live data viz hero (e.g., real-time OpenAIRE query graph).
- Interactive case studies (embedded notebooks, live MCP demo calls).
- "Data Lab" section with try-it tools.
- Custom al-folio fork (bolder typography, gradient accents, tech-startup feel).
- Newsletter integration (`newsletter` config already present, disabled).
- Full EN+FR parity on every page.
- **Risk:** execution risk is substantial. Half-finished interactive site is worse than polished static. Maintenance competes with Alien bizdev.
- **Converts:** narrow but high-value audience (AI-native visitors, collaborators).

### 3.6 Teaching + Publications — content model

Two pages currently blank, but each has a well-defined model once real content is supplied.

#### Teaching
- **Collection-based, not a single page.** Mirror the existing `_projects/` pattern: create a `_teaching/` Jekyll collection with one file per assignment. `_pages/teaching.md` becomes the index that iterates `site.teaching`.
- **URL structure:** `/teaching/{slug}/` per assignment (with `/fr/teaching/{slug}/` via Polyglot for French versions). Every course gets its own URL, even when the long description isn't ready yet — it's the stable URL + metadata that matter most for discoverability.
- **Per-assignment fields:** `title`, `institution`, `year(s)`, `level` (undergrad / grad / pro), `hours`, `role` (lead / co-teaching / guest lecturer), `short_description`, `tags`, optional `external_url`, `slides_pdf`, `long_description` (body).
- **Index view:** grouped by institution, shows title + short description + link to detail page.
- **Detail page:** full long description, learning outcomes, slides link (when shareable), references, related case studies / publications. This is the page that humans deep-diving into one course land on, and the page AI crawlers (GPTBot, ClaudeBot, Perplexity) index as a standalone topic.
- **Why subpages over buried sections:** a prospect evaluating you for a workshop, a student looking at the ESTACA course, and an AI agent answering *"who teaches AI and mobility in France"* all need a dedicated URL they can land on, cite, or retrieve. Each subpage is a keyword-rich landing in its own right (e.g., *"formation IA mobilité ESTACA Ghislain Delabie"*) — same crawlability argument as for Publications transcripts.
- **Slides handling:** link PDF/slides from the detail page only when the material is good enough to share. No auto-embed of poor decks.
- **Long description generation (optional):** where PPTs exist and justify the effort, draft the long description via `python-pptx` (title + bullet extraction) → Claude agent → your review. The detail page can ship with just the short description if the long content isn't ready — add longs incrementally.
- **Schema.org:** add `Course` JSON-LD to detail pages (`name`, `provider`, `educationalLevel`, `timeRequired`, `teaches`, `inLanguage`). Free extra discoverability signal.
- **Cross-link:** tag each item with its vertical (mobility / data / AI), link to related case studies or publications.

#### Publications & Talks
A catalog of artifacts you produced or co-produced. Replaces the current academic-papers-flavored page.

**Types handled:**
- **Reports** — PDF, co-authored studies, whitepapers
- **Talks** — conference presentations with video available (DSS26 Madrid, Tech & Fest Grenoble, GFII, etc.)
- **Webinars** — recorded sessions
- **Interviews / podcasts** — audio or video appearances
- **Papers** — academic or industry, if any

**Per-item fields:**
- Core: `title`, `date`, `venue`, `co_authors`, `type`, `tags`
- External: `external_url` (YouTube, publisher, archive)
- Local artifacts (optional, any subset): `pdf`, `video`, `audio`, `transcript`
- Descriptions: `short_description` (for list), `long_description` / abstract (for detail page)
- Relations: `related_projects`, `related_teaching`, `related_posts`

**Detail page template (`publications/{slug}/`):**
1. Title, date, venue, co-authors, type badge
2. Primary artifact: YouTube embed (primary) + `<video>` fallback from self-hosted copy / PDF embed / audio player
3. Short description
4. Full polished transcript (for video/audio) with section anchors — below the fold
5. Related links: projects, case studies, blog posts

#### Self-hosting video — practical plan
GitHub Pages limits (100 MB/file, 1 GB soft total) make full-quality self-hosting infeasible at scale. Pragmatic approach:

| Library size | Approach |
|---|---|
| <10 items | YouTube embed primary + self-hosted 480p MP4 (~30 MB / 20 min) as `<video>` fallback in repo |
| 10+ items | Move fallbacks to a video CDN — **Cloudflare R2 (10 GB free)**, Bunny.net, or S3. Referenced by URL, stored outside repo. |

YouTube stays the primary playback source in both cases — you get their player UX and bandwidth. The self-hosted copy is insurance and an accessibility fallback.

#### Article-version pipeline (not verbatim transcription)

The published output is **an article version** of the talk — a written companion that extracts the main arguments, restructures them for reading, and omits what only worked live (slide callouts, live demos, Q&A tangents). Not a word-for-word transcript. This serves both humans (who want a readable piece, not a cleaned-up speech) and AI crawlers (which extract structured arguments better from tight prose than from verbose speech).

```
YouTube URL → yt-dlp (audio) → Whisper (raw transcript, working artifact)
                              → rewriter agent (talk → article, see below)
                              → your review (iterative, end-to-end)
                              → Jekyll detail page
```

- **Whisper** stays the starting point (OpenAI API ~$0.006/min = ~$7 for 20h, or local `whisper.cpp`, large-v3 for French). The raw transcript is a **working artifact**, never published as-is.
- **The rewriter agent is a sibling of the editor agent (§4.5), not a mode of it.** Opposite discipline:

| | Editor agent (§4.5) | Rewriter agent (this pipeline) |
|---|---|---|
| Input | Clean written prose (a blog post) | Raw oral transcript |
| Goal | Preserve content, polish prose | Transform speech into a written article |
| MAY restructure? | No | **Yes — required** |
| MAY reorder / merge points? | No | Yes |
| MAY omit content? | No | Yes (live-only asides, filler, repetition) |
| MAY add headings? | No | Yes |
| Output length vs input | ~100% | Often 30–50% (speech is ~3× denser as text) |

**Rewriter agent scope rules**

What it MAY do:
- Restructure: intro → arguments → conclusion, even if the talk meandered
- Merge related points scattered across the talk
- Cut filler, repetition, live-only asides ("as you can see on this slide…", "let me just…", Q&A digressions)
- Convert oral rhetoric (rhetorical build-ups, callbacks) into written equivalents
- Add section headings every ~500–800 words
- Smooth oral syntax into written syntax
- Expand acronyms on first use
- Fix proper-noun spelling from a pre-supplied list (projects, people, companies)

What it MUST NOT do:
- Invent facts, numbers, or citations not present in the talk
- Draw conclusions the speaker did not draw
- Change positions, stances, or examples
- Strip personal anecdotes or parenthetical remarks that carry voice
- Soften opinions (if you said something direct, keep it direct)
- Inflate length — a 30-min talk becomes ~1500–2500 words, not 8000

**Voice preservation — same discipline as §4.5:**
- Few-shot with 1–2 of your existing written pieces as voice examples
- Style fingerprint before writing: agent enumerates 5 markers from the talk (register, examples, rhetorical patterns) and commits to preserving them in the written version
- Change budget: total output length ≤ 50% of Whisper input token count (forces compression)
- Language routing: FR and EN configured separately

**Review workflow:**
Unlike the editor agent (diff-based, hunk-level accept/reject), rewrites are reviewed end-to-end. Iterate by prompt ("shorter", "add the part about X", "cut the section on Y", "less formal") rather than line-by-line. Figure on 2–3 iterations per talk.

**Optional: disclose the raw transcript too.** Below the article version, a collapsed `<details>` block with the light-cleanup version of the raw Whisper output (paragraph breaks only, no rewrite). This gives:
- Citation-grade accuracy for anyone wanting exact quotes
- Accessibility fallback
- Additional crawlable content for AI agents (they can cite the verbatim text even when displaying the article version)

Quality bar: the article version is the primary reading experience; the collapsed raw transcript is reference material. Only ship the raw if it has been through at least a paragraph-break pass — never raw Whisper output verbatim.

#### Principle: long-form content = its own URL

A principle worth stating explicitly, since it now applies to both sections:

**Anything worth a long description gets its own page.** Teaching assignments with long descriptions, publications with transcripts, case studies with deep-dives — each is a stable URL that humans can bookmark and share, LinkedIn/CV can link to, and AI crawlers can ingest as a standalone topic. Never bury long content on a parent list page. Exception: teaching items without a long description yet still get a URL; it ships with metadata + short description and grows later.

**Robots policy:** review `robots.txt` to explicitly allow AI crawlers (`GPTBot`, `ClaudeBot`, `PerplexityBot`, `Google-Extended`). Given your positioning as someone who connects AI agents to data sources, blocking AI crawlers from your own site would be a strange look. Also ensure `jekyll-sitemap` is enabled and the sitemap includes every detail page.

#### SEO angle — why this matters

Each article version is typically 1500–3000 words of focused French AI/mobility content. Modern SEO rewards **density of value per word**, not length — Google's "helpful content" signals and AI crawlers' retrieval chunking both favor tight, well-structured prose over verbose transcripts. An article version out-performs a raw transcript on almost every ranking signal: dwell time, scroll depth, readability, structured data, link-worthiness.

Very few French-language AI/mobility talks have article versions online. This is a **defensible SEO position**. Expect real long-tail traffic: *"retour d'expérience OpenAIRE MCP"*, *"standard covoiturage retour 2024"*, *"conférence IA mobilité Delabie"*. Each article also acts as an internal-link hub pulling visitors to related case studies and blog posts.

Bonus: one talk → multiple content assets. The article version is also publishable as a blog post, a LinkedIn newsletter item, and Medium cross-posts — content atomization without creating new material.

Caveat: still only works if the article version is good. A half-baked rewrite is worse than no rewrite. Same calibration discipline as §4.5 — hand-write 1–2 article versions yourself first to establish the voice bar, then tune the agent against those goldens.

#### Minimum viable scope

- **Inside Scenario B2 (recommended branding):** Teaching populated with your descriptions (detail page per course, short descriptions only). Publications with ~5 flagship items (DSS26, Tech & Fest, GFII, 1 flagship Fabmob report, 1 Alien piece). No article versions yet — just YouTube embeds + short descriptions.
- **Scenario B2.5 (extension):** add article versions for the top 3 talks. Requires calibrating the rewriter agent — hand-write 1 article version yourself first as the voice golden. Adds ~1 week. Optionally include collapsed raw transcripts as reference material.
- **Scenario B3:** article versions across the full publications library + PPT-derived long descriptions on Teaching detail pages. Adds ~2–3 weeks. Both agents (editor + rewriter) calibrated and in regular use.

---

### 3.7 Multilingual strategy & the trans-localiser agent

Your writing is natively French. EN / DE / ES / IT versions are **derivative** — produced by a third agent in the family, the **trans-localiser**. Its job: generate target-language (TL) content that reads as if a French professional with full TL fluency had written it directly. Not a translation. Not a market localisation. **Transcreation with authorial-signature preservation.**

#### What distinguishes trans-localisation from translation / localisation

| | Translation | Localisation | Trans-localisation |
|---|---|---|---|
| Voice | Neutral | Neutral | **Author's — French-writing-in-TL** |
| Idioms | Preserved literally | Replaced with TL equivalents | Replaced where unintelligible, kept where they carry voice |
| Examples | Kept as-is | Replaced (FR stats → UK stats) | **Kept as-is** — French origin is authorial signature |
| Proper nouns | Often translated | Often translated | Kept (*La Fabrique des Mobilités*, not *The Mobility Factory*) |
| French references | Left bare | Removed | Kept + brief parenthetical on first use |
| Sentence rhythm | Source-mirroring | TL-native, flat | TL-native with author's complexity level |
| Feels like | A translation | Anonymous local writer | A French professional, fluent in TL |

#### Target languages (priority order)

1. **EN** — flagship. Global professional audience. You self-review.
2. **DE** — German mobility + Industrie 4.0 sectors. Needs native reviewer.
3. **ES** — Spanish/LATAM research. Needs native reviewer.
4. **IT** — Italian research & mobility. Needs native reviewer.

Each TL needs its own calibration cycle — voice golden, prompt tuning, reviewer policy.

#### Trans-localiser scope rules

MAY:
- Restructure sentences for TL rhythm (split long FR sentences, de-nest subordinate clauses)
- Replace idioms that wouldn't land; keep those that carry voice
- Add brief parenthetical context for French-specific references on first use
- Adjust register to TL norms where needed, but stay within the author's register band
- Apply TL punctuation and typography (`¿?`, `„…"`, `»«`, smart quotes)

MUST NOT:
- **Localise examples away** — French companies, projects, regulations, statistics all stay. Reader knows this is a French author.
- Translate proper nouns
- Change arguments, conclusions, facts, numbers
- Fake-French-accent the TL ("I has written" — you're supposed to be fluent)
- Over-Americanise, over-corporatise, or over-colloquialise
- Shift register to market-pitch tone (the #1 failure mode — trans-localisers tend to "polish" into LinkedIn-speak)

#### Voice preservation — hardest part of this agent

1. **Few-shot with author's own TL writing.** Include 2–3 excerpts of your existing EN/DE/ES/IT writing (LinkedIn posts, conference papers, talk abstracts) as positive voice examples.
2. **If no TL samples exist yet:** commission a human transcreation of 1 flagship piece per TL as the voice golden. This is a one-time investment (~€50–150 per piece) that anchors the rest.
3. **Cross-language voice fingerprint.** Paragraph length, argument density, use of rhetorical questions, appetite for asides — these markers transfer across languages. Agent must enumerate them from the FR source and commit to preserving them.
4. **Anti-contamination self-check.** Before returning output, agent re-reads and flags any sentence that reads as machine-translated or voice-flattened. Flagged paragraphs get manual review.

#### Review policy per TL

- **EN:** self-review sufficient after calibration. Can ship with just the agent + your read.
- **DE / ES / IT:** you cannot reliably judge nativeness. Policy:
  - Flagship pieces (case studies, signature talks): native-speaker reviewer (~€30–80 per 1500-word piece)
  - Long-tail pieces: calibrated agent + LLM second-pass review (different model) + periodic native-speaker sampling (every 10th piece)

#### Pipeline integration

```
FR source → normalize → editor → published FR (canonical)
                           ↓
                   trans-localiser (EN | DE | ES | IT)
                           ↓
                    self-review (EN) or native reviewer (DE/ES/IT)
                           ↓
                    published /en/ /de/ /es/ /it/ (Polyglot variants)
```

Trans-localiser runs **after** the editor pass on canonical FR. Never on raw WordPress imports. Never on un-polished content — bad input in, bad output in N languages.

#### Site config implications

Current `_config.yml`: `default_lang: "en"`, `languages: ["en", "fr"]`. With FR as true canonical, you have a decision:

| Option | URL shape | Implication |
|---|---|---|
| **Keep EN default** | `/about/` = EN, `/fr/about/` = FR | Non-FR visitors land on EN. Doesn't match your actual writing reality, but no URL breakage. |
| **Flip to FR default** | `/about/` = FR, `/en/about/` = EN | Matches reality. **Breaks existing EN URLs** — needs 301 redirects, has short-term SEO cost. |
| **EN default + FR co-canonical** | Same as current | Editorial policy of bilingual parity. No URL changes. Most pragmatic. |

Regardless of default choice, extend `languages:` to `["fr", "en", "de", "es", "it"]` (or whichever order). Polyglot handles this without code changes.

#### The three-agent family

| Agent | Input → output | Scope | Detailed in |
|---|---|---|---|
| **Editor** | Clean FR/EN prose → lightly polished same-language prose | Preserve everything, fix typos/grammar/light style | §4.5 |
| **Rewriter** | Raw oral transcript → article version in same language | Restructure, compress, omit, add headings | §3.6 |
| **Trans-localiser** | Polished FR → fluent TL with French authorial signature | Restructure for TL rhythm, preserve voice + origin markers | This section |

All three share: style-fingerprint step, few-shot voice anchoring, language-specific configs, hand-edited goldens for calibration, human-review gates. Keep prompts in separate files (`_migration/agents/{editor,rewriter,translocaliser}_{fr,en,de,es,it}.md`) to prevent cross-contamination.

#### Cost envelope

Claude API (Sonnet-level): ~$0.10–0.30 per 1500-word piece trans-localised. For 50 pieces × 4 TLs = ~$40–60 in API. Dominant cost is human review: €30–80 × 50 × 3 non-EN languages = €4.5k–12k if reviewing every piece. Flagship-only review (say 10 pieces per TL): €900–2.4k.

#### Scope by scenario

- **B2 (recommended):** EN trans-localisations for the 4 flagship case studies + 2 blog posts + About. FR stays canonical. No DE/ES/IT.
- **B2.5:** add DE for flagship case studies (strong fit for German mobility/industry).
- **B3:** full EN + DE + selective ES/IT. All three agents (editor + rewriter + trans-localiser) calibrated and in rotation.

---

## 4. Blog consolidation process

### 4.1 State of play
- **WordPress:** 303 posts exported (FR, 2012–2021 archive), 3 normalized, 300 pending. Blog is archived, one-shot job.
- **Medium:** untouched. Use GDPR export (zip of HTML + metadata).
- **LinkedIn articles + newsletter:** untouched. Use GDPR export (HTML); no API; ongoing sync is manual.
- **blog.fabmob.io:** untouched. **Static site built from markdown files in a public GitHub repo** — you have access. Ingestion = `git clone` + filter by author + copy `.md` files directly (no HTML↔MD conversion needed). Much simpler than WP/Medium/LinkedIn. Posts are co-authored. **Canonical strategy inverted: delabie.tech will be the canonical destination, fabmob.io will point to delabie.tech.**
- **Existing tooling:** `normalize.py` + 7 utility modules, `copy_images.py`, `check_links.py` with Wayback fallback, lychee CI on built HTML. Solid foundation.

### 4.2 What to add on top of existing scripts
- `_migration/scripts/adapters/{medium,linkedin,fabmob}_adapter.py` — pre-processors
- `langdetect` integration in `utils/frontmatter.py` (hardcoded to `fr` today)
- `jekyll-redirect-from` gem (not in Gemfile) — for old WP slug redirects
- `detect_duplicates.py` — fuzzy title match + content simhash across sources
- `vale` with FR+EN styles for lint
- `llm_review.py` — Claude for auto-tagging, descriptions, translation-priority scoring
- `Makefile` or `bin/blog` CLI entry point (doesn't exist today)
- WebP conversion post-processing step (Pillow; plan lines 226–257)

### 4.3 Per-source ingestion (summary)

| Source | Extract | Canonical | Ongoing sync? |
|---|---|---|---|
| WordPress (done export) | `wp-import/` + `normalize.py` | delabie.tech; `redirect_from:` old slugs | No — archived |
| Medium | GDPR zip → pandoc | delabie.tech (Medium allows setting canonical on own stories after import) | Optional: RSS-to-PR GH Action |
| LinkedIn | GDPR HTML export (manual save-as fallback) | delabie.tech (LinkedIn has no canonical support) | Manual; or reverse flow (publish site-first) |
| **blog.fabmob.io** | **`git clone` public repo → filter `.md` by author frontmatter → copy directly** | **delabie.tech becomes canonical. Fabmob posts get `<link rel="canonical">` pointing back to delabie.tech** (needs fabmob editorial sign-off — see §4.4) | **Optional: `git pull` + diff on a schedule; trivial since source is already markdown** |

### 4.4 Making delabie.tech canonical for fabmob posts

Three implementation options on the fabmob side, roughly ordered from soft to hard:

| Option | What happens | SEO effect | User experience | Fabmob ask |
|---|---|---|---|---|
| **Canonical tag only** | fabmob post keeps its URL and content; adds `<link rel="canonical" href="https://www.delabie.tech/blog/{slug}/">` in the head | Search engines credit delabie.tech. Fabmob stops ranking for those queries. | Transparent — readers who land on fabmob stay on fabmob. | Low. One-line frontmatter addition per post. |
| **Canonical tag + visible notice** | Above, plus a banner at top: *"Article publié à l'origine sur delabie.tech — version canonique ici."* | Same SEO effect. Readers know where to find more of your work. | Visible attribution. Sends some click-throughs. | Medium. Requires editorial buy-in on the banner copy. |
| **301 redirect** | fabmob URL 301s to delabie.tech; content removed from fabmob | Full SEO transfer + no duplicate content risk | Readers land on delabie.tech directly. Fabmob loses the content. | High. Fabmob loses content from its own archive — may not be acceptable for a community blog. |

**Recommendation:** option 2 for solo-authored posts, option 1 for co-authored posts. Option 3 is aggressive and likely won't clear La Fabrique des Mobilités editorial line — they want the content on their platform for their community.

**Corresponding changes on delabie.tech:**
- In the fabmob adapter (§4.2): do NOT set `canonical_url:` in frontmatter (delabie.tech is canonical by default when omitted).
- Add an attribution block at the bottom: *"Co-écrit avec {coauthors} — première publication sur blog.fabmob.io, le {date}."*
- Tag these posts with a `source: fabmob` frontmatter field so the theme can style them differently if wanted (e.g., small fabmob logo in the post meta).

**Open question for you (§7.3):** is this agreed with La Fabrique des Mobilités, or does it need a conversation? The canonical-tag change needs a PR on their repo — if they own the repo and you're a contributor, you can open it; if they gate merges, you need approval.

---

### 4.5 Two-stage pipeline: migration scripts + editor agent

Your design splits the work into two stages with different engineering disciplines. The two stages **must not overlap**.

| Stage | Nature | How it iterates | Scope |
|---|---|---|---|
| **Migration + normalization** | Deterministic, mechanical | Golden-file regression tests (`_migration/ITERATION_METHODOLOGY.md`) | Frontmatter, headings, images, embeds, links, shortcodes — structure only |
| **Editor agent** (Claude as reviewer) | Probabilistic, opinionated | Prompt engineering against "editor-golden" articles | Prose only — typos, grammar, light style |

Normalization never edits prose. The editor never edits structure. This separation is what makes each stage testable.

**Editor agent scope rules**

What the agent MAY do:
- Fix typos, misspellings, agreement errors
- Correct punctuation (commas, apostrophes, accents)
- Fix tense and subject-verb agreement
- Apply French typography (non-breaking spaces before `:;!?`, `« »` quotes, proper em-dashes, `…` ellipses)
- Remove filler words ("vraiment", "en fait", "du coup", "actually", "basically" when redundant)
- Tighten flabby sentences — **max one rephrase per paragraph**
- Fix clearly awkward constructions

What the agent MUST NOT do:
- Change facts, arguments, or conclusions
- Add or remove information
- Reorder sentences or paragraphs
- Elevate informal tone to formal (or vice versa) — preserve the register
- Translate idioms or culturally-specific phrases
- Expand or compress paragraphs by more than ~20% length
- Rewrite section headings
- Remove rhetorical questions, asides, or parenthetical remarks — these are voice

**Voice-preservation techniques** (to bake into the prompt)

1. **Few-shot with your own best writing.** Include 2–3 excerpts from articles you're proud of as positive voice examples.
2. **Style fingerprint first.** Before editing, agent must enumerate 5 voice markers of the article (e.g., *"short paragraphs, rhetorical questions, personal asides"*) and commit to preserving them.
3. **Diff-constrained output.** Agent returns a unified diff, not a rewritten article. This structurally prevents paragraph-level rewrites.
4. **Change budget.** ~5% change ratio per paragraph. Above that, agent flags the paragraph for your manual attention instead of editing it.
5. **Language routing.** FR and EN articles go to separately-tuned agent configs. French editor knows French typography rules; English editor doesn't pretend to.

**Review ergonomics**

- Agent output = unified diff per article (`{slug}.edit.patch`).
- Every change tagged by class: `[typo]`, `[grammar]`, `[typography]`, `[style]`, `[rephrase]`.
- You review in a PR:
  - Batch-accept `[typo]`/`[grammar]`/`[typography]` in one click
  - Review each `[rephrase]` individually at hunk granularity
- Reject/accept per hunk via `git apply --index`.

**Calibrating the agent (parallel to the code methodology)**

1. Pick 3 articles. Do the editor pass yourself, save as `fixtures/editor_golden/{slug}.md`.
2. Run the agent on the corresponding normalized markdown.
3. Diff agent output vs. your editor-golden.
4. Failure-mode triage:
   - Typos the agent missed that you caught → add to prompt's checklist
   - Rephrases the agent made that you wouldn't have → tighten MUST-NOT list
   - Voice markers the agent flattened → strengthen style-fingerprint step
5. Iterate until agent's edits are a subset of (or closely match) your own editing.

**Pipeline integration**

```
wp-import/  →  normalize.py  →  _posts_draft/  →  editor_agent  →  PR  →  _posts/
                   ↑                                  ↑                ↑
         code iteration,                  prompt iteration,      manual
         golden MD files                  editor-golden files    review
```

Editor runs only on articles that have passed normalization. It never runs automatically — it produces a PR for your review. Per-article sign-off is mandatory before merging.

**Sibling agents — three-agent family.** The editor has two siblings: the **rewriter** (§3.6, raw transcript → article version) and the **trans-localiser** (§3.7, polished FR → fluent TL with French authorial signature). Different disciplines, shared DNA (style-fingerprint, few-shot voice, language routing, hand-edited goldens). Keep prompts in separate files (`_migration/agents/{editor,rewriter,translocaliser}_{fr,en,de,es,it}.md`) to prevent cross-contamination.

---

### 4.6 Scenarios — **blog consolidation**

#### Scenario BM-A — Finish the Plan **(START HERE)** (2–3 days + 1–2 weeks Phase 4/5 optional)
Execute `BLOG_MIGRATION_PLAN.md` Phases 2–6 on WordPress only. Run `normalize.py` on remaining 300 posts, `copy_images.py`, `check_links.py`. Merge `feature/blog-migration` → main. Add `jekyll-redirect-from`.
- **Skips:** Medium, LinkedIn, fabmob.
- **Risk:** new edge cases at 303 scale (~1 day of script fixes expected). Repo grows ~50–100 MB for images.
- **Maintenance:** near-zero — WP blog is archived.

#### Scenario BM-B — Multi-Source Hub (+1–2 weeks on top of A)
Add Medium, LinkedIn, fabmob.io adapters. Duplicate detection. RSS sync for Medium and fabmob via GH Actions cron.
- **Risk:** LinkedIn extraction is fragile (no API, image URLs expire). fabmob posts are co-authored — attribution matters.
- **Maintenance:** ~1h/month reviewing auto-PRs; LinkedIn stays manual unless flow reverses.

#### Scenario BM-C — Editor agent on top (+1–2 weeks on top of B)
**Primary feature: Claude "editor agent"** per §4.5 — a professional-reviewer pass on every imported article. Subtle polish: typos, grammar, light style, French typography. Voice-preserving and content-preserving by prompt design.

Secondary lower-risk features:
- Auto-tagging and auto-description generation for frontmatter (editor agent handles both in one pass)
- Broken-link self-healing (auto-Wayback PRs)
- FR↔EN translation for a priority subset (max 10 posts) — human review gate, manual accept/reject per paragraph

**Explicitly skip:**
- Content quality "scoring" (arbitrary)
- Cross-post scheduling (scope creep)
- Auto-merge of any LLM-generated change (always PR + human review)

**API cost:** ~$5–15 for full corpus one-shot (editor agent on 303+ posts); negligible ongoing.

**Risk:** editor agent voice drift is the #1 concern. Mitigated by the diff-constrained output + style-fingerprint + change-budget design in §4.5. Still needs honest calibration against 3 hand-edited reference articles before trusting it at scale. Translation risk is higher — keep translation tightly scoped.

**Maintenance:** ~2–3h/month reviewing editor-agent PRs. Less time than doing the editing yourself, but not zero.

---

## 5. Cleanup tasks (independent of scenarios)

These are cheap and should happen regardless of which scenario you pick.

### 5.1 Do this week
- [ ] Delete `_posts/*.NORMALIZED.md` and `*.NORMALIZED.NORMALIZED.md` artifacts (6 files)
- [ ] Add to `.gitignore`: `_site/`, `_site_clean/`, `lighthouse_results/`
- [ ] `git rm -r --cached _site _site_clean lighthouse_results` (remove from repo, 193 MB)
- [ ] Investigate & delete duplicate " 2" folders: `assets 2`, `bin 2`, `lighthouse_results 2`, `readme_preview 2` (check contents first — likely iCloud/Finder artifacts)
- [ ] Decide on `ai-mobilite` → `main` merge (3 commits: workshop guide + clean deploy workflow)
- [ ] Fix `/about/` 404 (likely a permalink or Polyglot config issue in `_pages/about.md`)
- [ ] Fix French nav → `/fr/publications/` (not `/publications/`)
- [ ] Delete Einstein publication from `/publications/`
- [ ] Remove 7 placeholder projects from `_projects/`
- [ ] Delete the `"a post with image galleries"` demo post OR unpublish it

### 5.2 Do this month
- [ ] Audit 35 drafts — delete template examples, promote real WIP
- [ ] Fix CV `rendercv` YAML (issue #3587)
- [ ] Remove `TTalex` from Repositories page; reconsider self-deprecating intro
- [ ] Translate CV body to French OR remove `/fr/cv/` from nav

### 5.3 Next quarter
- [ ] Plan upstream al-folio sync (50+ commits behind) — quarterly cadence
- [ ] Consolidate/close stale feature branches

---

## 6. Recommended sequencing (cross-topic)

If you want a single coherent path, this is the ordering I'd propose:

**Week 1 — Cleanup + P0 fixes (§5.1)**
Fix `/about/` 404, delete placeholders, strip build artifacts, decide the merge question. This unblocks everything else and stops the bleeding on credibility.

**Week 2 — Branding B1 (minimal polish)**
Rewrite hero/CV/tagline, enable OG/Schema/GA, fix French nav. Now the existing site doesn't actively hurt you.

**Weeks 3–5 — Branding B2 (reframed portfolio) + Blog BM-A in parallel**
Write the 4 Alien case studies (OpenAIRE first — highest leverage). Run full WP normalization batch (300 posts) in background — scripts are ready, it's mostly execution time. Write the 2 thought-leadership blog posts.

**Weeks 6+ — Selective BM-B/BM-C additions**
Add Medium ingest when you have a spare afternoon. Only add LinkedIn if you genuinely want that archive on the site (the extraction pain is real). LLM auto-tagging is the highest-value BM-C feature if you go that route.

**Defer / skip**
Branding B3 unless/until the Alien bizdev loop is solid — the playground is a reward, not a foundation. BM-C full translation automation — do it post-B2 when you know which posts actually matter.

---

## 7. Open questions for you

Before executing any scenario, these are worth answering:

1. **Alien client disclosure** — for OpenAIRE/BnF/LDS case studies, what's the confidentiality line? Can contract terms / architecture details be published? Needs Alien sign-off.
2. **Blog language strategy** — when importing FR WordPress posts, translate to EN or keep FR-only with `lang: fr` tag? Affects Phase 4/5 scope.
3. **LinkedIn flow** — are you willing to reverse the flow (publish on delabie.tech first, cross-post to LinkedIn)? That's the only way to avoid ongoing LinkedIn extraction pain.
4. **Teaching page** — populate with ESTACA/AI-Mobilité or remove from nav? Current state (placeholder) is the worst option.
5. **Energy vertical** — aspirational mention only, or real case study in the pipeline?
6. **`ai-mobilite` → `main` merge** — ready to deploy the Vibe Coding workshop content?
7. **Video hosting** — for Publications detail pages: YouTube-embed-only (simplest), YouTube + self-hosted 480p fallback in repo (recommended for small library), or move to Cloudflare R2 CDN now (future-proof for >10 items)?
8. **Teaching long descriptions** — ship with short descriptions only (fast), or also invest in PPT-derived long descriptions (slower, uneven quality)?
9. **Transcript scope** — no transcripts in v1 / polish the top 3 talks / full transcript library? Biggest effort driver on the Publications side.
10. **Canonical language** — keep EN default / flip to FR default (URL breakage + 301s) / keep EN default with FR co-canonical editorial policy? Affects every URL on the site.
11. **Trans-localisation scope** — EN only in v1 / EN + DE / EN + DE + ES + IT? And per-piece human review vs. agent-only for non-EN?
12. **Voice golden for non-EN languages** — commission a professional transcreation of 1 flagship piece per TL (~€50–150 each) as the calibration anchor? Or start agent-only and tune via your own iteration? The former is slower to start but higher final quality.

---

*Generated 2026-04-15 from 4 parallel audits. Source reports available in session transcript.*
