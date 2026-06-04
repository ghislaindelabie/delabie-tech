# Phase 5 — items pending refinement

Things that need Ghislain's manual input or external setup before Phase 5
fully closes. None of these block the framework / TDD work; they're values
to fill in later. Each item names the file + key the value lands in.

## 1. GoatCounter analytics

**File**: `_config.yml` → `analytics.goatcounter.code`

Steps for Ghislain:
1. Sign up at https://www.goatcounter.com (free for personal sites < 100k pageviews/mo).
2. Create a site for `delabie.tech` (the production domain — not `v2.delabie.tech`).
3. Copy the site code (the `data-goatcounter` URL value, e.g. `https://yoursite.goatcounter.com/count`).
4. Paste it into `_config.yml` under `analytics.goatcounter.code`.

Phase 5 wires the snippet behind that config so it only fires when the value
is set AND the request comes from the production domain (no analytics on
`v2.delabie.tech` or `localhost`).

If you change your mind and prefer Plausible later: 5-minute swap — different
`<script>` tag in the same conditional include.

## 2. Schema.org Organization — Alien Intelligence

**Status (2026-05-19): no longer needed — folded into §3.**

Earlier draft of Phase 5 declared a separate top-level `Organization` entity
for Alien Intelligence in `_data/schema_organization.yml`. That was wrong
subject — delabie.tech is a personal portfolio, the subject is the Person
(Ghislain). Declaring Alien as a top-level Organization here would imply
this site represents Alien, which it doesn't, and creates a competing
entity with Alien's own site (alien.club) that confuses Google's entity
resolution.

Files removed: `_data/schema_organization.yml`, `_includes/schema-organization.html`.

Alien is now declared inline on the Person as `worksFor` — name + URL
only (see `_data/schema_person.yml`). Same pattern applies to all other
organisations Ghislain is associated with — see §3.

## 3. Schema.org Person — Ghislain Delabie

**File**: `_data/schema_person.yml` (shipped). All organisations
Ghislain is associated with are declared inline on the Person —
`worksFor` for current employer, `memberOf` for voluntary affiliations.
No standalone Organization entities (see §2 for the rationale).

### `sameAs` URLs

Shipped defaults:
- https://www.linkedin.com/in/ghislaindelabie/
- https://github.com/ghislaindelabie
- https://medium.com/@ghislaindelabie
- https://www.youtube.com/channel/UCNRJeN9T__EEzoa0N_rgkKw
- https://fr.slideshare.net/ghislaindelabie

To confirm before merging:
- Canonical Alien Intelligence team page URL (`https://www.alien.club/about/#team-ghislain` once Alien ships team-anchor IDs — see `Vault/work/projects/seo-alien/`)
- Anything else worth listing?

**Not in `sameAs`** (verified 2026-05-19):
- France Culture / Radio France: there is **no personal profile page** for
  Ghislain on radiofrance.fr. The earlier `radiofrance.fr/personne/ghislain-delabie`
  URL was speculative. The actual surface is a podcast appearance —
  https://www.radiofrance.fr/franceculture/podcasts/les-nouvelles-vagues/covoiturage-auto-partage-libre-service-l-economie-des-nouvelles-mobilites-3358988 —
  which belongs in the `_publications` / `_archive` collection as a media
  appearance, not in identity-linking `sameAs`.

**Deferred — academic identity URLs.** Ghislain is building a research
profile (Vault/personal/projects/research-career/research-profile-strategy.md).
Once these exist, add them to `same_as` — high priority because they're
strong entity anchors for Google's Knowledge Graph:
- ORCID — `https://orcid.org/{id}` (one of the strongest academic-entity anchors)
- Google Scholar author page — `https://scholar.google.com/citations?user={id}`
- HAL or Zenodo author page (once first publication lands)
- ResearchGate (optional — Google weights it less)

Skip list (from review with Ghislain):
- SoundCloud `user-698026660` — anonymous handle, low signal
- BuzzSumo journalist profile — behind paywall

### `worksFor`

- **Alien Intelligence** — https://www.alien.club. Inline `worksFor` (name + url only).

**Current title** (confirmed 2026-05-19): "Head of AI projects and Partnerships" (EN) / "Responsable des projets IA et partenariats" (FR).

### `hasOccupation`

Multiple occupations Ghislain practices, beyond the singular employment
relationship in `worksFor`. Don't overload `worksFor` for parallel work
streams — `hasOccupation` is the schema.org-correct property.

Shipped 2026-05-19:
- **Head of AI projects and Partnerships** — the Alien role (described in detail).
- **AI engineering consultant** — independent advisory work (MCP, data infrastructure, mobility data). Selective alongside the Alien role.

Deferred (commented in YAML, ready to uncomment):
- **Independent researcher** — append once Ghislain's academic identity (ORCID + Google Scholar) is established. See `Vault/personal/projects/research-career/`.

### `alumniOf`

Shipped (3 institutions):
- **IMT Atlantique** (https://www.imt-atlantique.fr) — Diplôme d'ingénieur, majors in computer science, networks and mathematics. **`alternateName: "Télécom Bretagne"`** captures the institution's former name (renamed 2017 after merger with Mines Nantes). Including both names helps Google reconcile old references with the current entity.
- **University of Bristol** (https://www.bristol.ac.uk) — MSc Communication Systems & Signal Processing (programme since renamed "Communications Networks & Signal Processing" — same programme, no institution rename).
- **ESSEC Business School** (https://www.essec.edu) — Grande École / MBA programme.

All entries use institution name + URL only (program / degree detail lives on the CV page, not in the schema entity tie). The single exception is `alternateName` for IMT Atlantique, used specifically for institutional rename signal.

### `hasCredential`

Shipped 2026-05-19. Each credential is an `EducationalOccupationalCredential` cross-referencing the institution in `alumni_of`. Naming follows the diploma's historical title.

- **Diplôme d'ingénieur** (Master's degree) — IMT Atlantique. `competencyRequired: [computer science, networks, mathematics]` — ties to entries in `knows_about`.
- **MSc Communication Systems & Signal Processing** (Master's degree) — University of Bristol. Historical programme title preserved; the institution renamed the programme to "Communications Networks & Signal Processing" after Ghislain graduated.
- **MBA — ESSEC Grande École** (Master's degree) — ESSEC Business School. Both "Grande École" and "MBA" frame the same diploma per Ghislain.

Rationale for shipping `hasCredential`:
- Credentials become first-class entities in the schema rather than implicit in alumni ties.
- `competencyRequired` cross-references `knowsAbout` — Google reads this as evidence that the expertise claims have institutional grounding.
- Low maintenance — degrees don't change.

### `knowsAbout`

Tight expertise list (extending dilutes signal). Each entry is a topic
Ghislain has operated in deeply enough to be cited on.

Shipped 2026-05-19:
- AI
- MCP (Model Context Protocol)
- data infrastructure
- data sovereignty
- mobility
- low-carbon mobility — for the decarbonisation-of-transport expertise (kept distinct from generic "mobility")
- scientific publishing

### `affiliation`

Current institutional ties beyond employment (teaching posts, advisory
roles). **Rich form** (Schema.org `Role` wrapper) — `roleName` and
`startDate` (and `endDate` when applicable) emit as schema, not just YAML
comments. Don't put past teaching here.

Shipped 2026-05-19:
- **ESTACA** — Industry Lecturer ("vacataire extérieur"), 12 years
- **Télécom Paris** — Industry Lecturer. Two engagements consolidated under the parent (no separate web identity for exec ed): Mastère Smart Mobility (co-owned with Ponts) + Executive Education "Smart City & Mobility" programme (5 years).
- **École des Ponts ParisTech** — Industry Lecturer (Mastère Smart Mobility)
- **Ponts Formation Continue** — Lead Instructor & Program Designer; designed full "Déployer un système MaaS" programme, AI + mobility programme in development. Listed as its own entity (distinct URL + program-design depth) rather than folded into the École des Ponts parent.
- **INSA Lyon** — Industry Lecturer (new 2026)

Role-label note: "Industry Lecturer" used uniformly in YAML comments to describe the from-practice teaching style. Not emitted to JSON-LD (simple `affiliation` form keeps role detail in comments only). Per Ghislain's preference — easier for human readers than "Adjunct Lecturer".

**Pre-decided for the future option-B pass** (rich `Role` wrapper, when/if we upgrade to surface role detail in JSON-LD): use the composite **"Industry Lecturer (Adjunct)"** as `roleName`. Captures both the from-practice readability AND the standard academic-CV term that recruiters / academic directories expect when searching for adjunct ties. Decision recorded 2026-05-19 — no action until option B is on the table.

Past teaching engagements (institutions where Ghislain no longer
teaches) and past employers are intentionally **not** declared in
schema — they live on the CV / About page. Including them in `alumniOf`
would misuse the property (which means "where you studied"), and there
is no Schema.org property for "past employment" suitable for identity
JSON-LD.

### `memberOf`

Decided 2026-05-19. Voluntary affiliations Ghislain belongs to with
publicly verifiable presence:

- **La Fabrique des Mobilités** — https://lafabriquedesmobilites.fr. Volunteer / network member.
- **AFNOR — CN IA** (French AI standardisation committee) — https://www.afnor.org. Participant on the CN IA committee.

**Explicitly excluded:**

- **Aleph Studios** (sister company to Alien). Not an affiliation —
  declaring it would be advertising a commercial partner, not capturing
  a publicly verifiable membership. Skipped intentionally.

If a more specific URL becomes available for either entry (e.g., a
direct AFNOR CN IA committee page that names Ghislain), update the
`url` field in `_data/schema_person.yml` — more specific is better
for entity reconciliation.

## 4. Google Search Console verification

**File**: `_includes/head-custom.html` (HTML meta tag verification path)

Steps for Ghislain:
1. Add `delabie.tech` (and `v2.delabie.tech` for testing) as properties in
   Search Console.
2. Choose HTML meta tag verification.
3. Paste the verification meta-tag content into `_config.yml` under
   `seo.google_site_verification`.

Phase 5 ships the include scaffolding behind that config so it only renders
when set.

(Alternative: DNS TXT verification — entirely on Ghislain's side, doesn't need
any code change. If you go that route, just delete the placeholder.)

## 5. Contact-form provider (carryover from §3.8)

**Not strictly Phase 5** — but related, and the email-privacy invariant in
the structural rspec depends on it: the public site must never serve email
or phone in HTML.

Currently no contact route exists. If Phase 5 adds a "Contact" link in the
nav, it points at a hosted form (Formspree / Web3Forms / Formcarry — pick
when you're ready). Phase 5 ships the placeholder `/contact/` page with a
"contact form coming soon" message; the actual form wiring is a separate
task.

## 6. Open Graph banner image

**File**: `_config.yml` → `social_preview_image:` (currently commented out)

V1 ships without an `og:image` because the avatar (a 1:1 portrait) renders
badly in Twitter / LinkedIn / Facebook social-card previews (1.91:1 frame
crops to a square; text gets squeezed).

For V1.1: design a 1200×630 banner showing
- "Ghislain Delabie" or your stylised mark
- A short tagline matching the site description
- Legible at the small thumbnail size most clients use first

Drop the file at `/assets/img/og-banner-1200x630.jpg` and uncomment the
`social_preview_image:` line in `_config.yml`. No code change needed —
Chirpy's head.html picks it up automatically.

Verify after deploy by feeding the URL to https://www.opengraph.xyz/ or
the LinkedIn / Twitter card validators.

## 7. AI-friendly content delivery — `/llms.txt` + per-page `.md` alternates

**Decision (2026-04-29)**: ship after Phase 5 merges AND after content stabilizes (fewer churning items = stable `llms.txt` index). Path verified by research:

- **`assets/llms.txt`** at site root, generated from collections (mirrors `robots.txt` override pattern). H1 + blockquote summary + H2 sections per collection. ~50 lines of Liquid.
- **Per-page `.md` alternates** via a Jekyll generator plugin (`_plugins/markdown_alternates.rb`, ~50 lines). Every `/foo/` URL gets a `/foo.md` sibling returning raw markdown — the format AI agents actually fetch. Industry pattern (Anthropic docs, Stripe docs, Mintlify default).
- Sitemap gets `<xhtml:link rel="alternate" type="text/markdown">` annotations.

Ghislain's stance: welcomes AI crawlers (`robots.txt` is open). This adds a higher-fidelity feed for them. Skip: content negotiation (no backend), `.well-known/ai.txt` (opt-out signal, contradicts the open stance), MCP server (needs runtime).

Trigger to start: when Phase 4b.2 follow-up imports + bilingual content base is stable enough that the `llms.txt` index won't churn weekly. Not blocked by anything else.

Reference: full research report from the 2026-04-29 session (`general-purpose` subagent, ~25 min).

## 8. Content licensing — CC-BY now, CC Signals later

**Files**: `_includes/footer.html` (or `_includes/head-custom.html`), every
content layout's Schema.org JSON-LD, `_config.yml`.

**Current state**: licensing is implicit — robots.txt welcomes all crawlers
(search + AI training); no explicit license declaration on the site.

**Phase 5.1 follow-up** (small, post-merge):
- Add `<link rel="license" href="https://creativecommons.org/licenses/by/4.0/">`
  in `_includes/head-custom.html` so every page declares CC-BY 4.0
  uniformly.
- Add a footer line: "Content is licensed CC-BY 4.0 unless noted otherwise."
- Add `"license": "https://creativecommons.org/licenses/by/4.0/"` to the
  per-archive-item Schema.org JSON-LD (NewsArticle / VideoObject blocks
  in `_includes/archive-jsonld.html`).
- Per-page override mechanism: front-matter `license: <url>` for pages
  that need a non-CC-BY license (third-party reprints, restricted
  material). The default falls through to CC-BY when unset.

**Future (CC Signals)**:
The Creative Commons Signals framework — purpose-built for granular AI
training rights declarations — is in early-spec phase as of 2026-04. Once
it's stable enough to point at production URLs, swap the
`<link rel="license">` and Schema.org `license` fields to the chosen
CC Signal. Track the spec at https://creativecommons.org/ai-and-cc/.

## 9. Open follow-ups from PR #22 / #23 reviews

Carried over from the deferred review findings:
- **REVIEW-7 (PR #22)** — strict-bilingual rule could forbid the `translated:`
  field outright in `_archive/`. Hygiene; not blocking.
- **REVIEW-7 (PR #23)** — tag casing inconsistency in archive items. Chore
  PR after Phase 5 lands the SEO surface (since SEO + tag-page rendering
  may shift the priorities).
- **REVIEW-9 (PR #23)** — Cerema ATEC ITS 2025 date precision (used
  2025-01-29 as a plausible day; confirm against the actual page).
- **SUGGESTION-12 (PR #23)** — extract `slug_safe?` / `url_safe?` validators
  to a shared lib so the migration script and the structural rspec agree
  by construction.
