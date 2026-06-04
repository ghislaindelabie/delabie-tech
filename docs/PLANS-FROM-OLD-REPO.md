# Plans, audits and source material relevant to this repo

Map of where things live across the two repos and how they relate.

## In this repo (NEW — `ghislaindelabie/delabie-tech`)

| Doc | What | Phase |
|---|---|---|
| `CHIRPY_MIGRATION_PLAN.md` (root) | Master migration plan — al-folio → Chirpy + custom i18n | Active (Phases 0–5 shipped/in flight, cutover gate ahead) |
| `WEBSITE_AUDIT.md` (root) | Audit of the old site — drives the migration's content fixes | Active reference |
| `docs/phase-5-refinements.md` | Items pending Ghislain's manual input to close Phase 5 (GoatCounter, GSC, Schema.org details, OG banner) | Active |
| `docs/BLOG_MIGRATION_PLAN.md` | **Next-phase plan**: migrate 300-post WordPress archive + 3 normalized legacy posts. Out of scope for v1 per `CHIRPY_MIGRATION_PLAN.md` §0.2; restarts post-cutover. | Deferred — kept here so it's easy to pick up |
| `docs/NORMALIZATION_SCRIPT_DEV_PLAN.md` | Python script design for normalizing imported posts (frontmatter, images, links, EN/FR pairing) | Supports blog migration above |
| `docs/security/` | Per-PR security review summaries (local skill output) | Continuous |

## In the OLD repo only (`ghislaindelabie/ghislaindelabie.github.com`)

Stays there because it's **source material** for the blog migration, not planning docs:

| Path | What | Why it stays in OLD |
|---|---|---|
| `wp-import/` | Raw WordPress export (XML + ~800 MB images) | Heavy; staying in OLD keeps this repo's git history lean |
| `_posts/*.NORMALIZED.md` | First normalization test outputs | Drafts; will be regenerated when the blog migration restarts in this repo |
| `_migration/ITERATION_METHODOLOGY.md` | Golden-file iteration methodology — already referenced from `CHIRPY_MIGRATION_PLAN.md` §0.3 | Stays attached to the migration scripts in OLD; idea already absorbed in this repo's testing philosophy |
| (Whole al-folio site state) | Snapshot of the pre-cutover production site | Frozen as historical reference once cutover lands |

OLD repo checkout location on P710: `~/code/delabie-tech-old/`.

## When the blog migration restarts

1. Read `docs/BLOG_MIGRATION_PLAN.md` here, refresh assumptions (e.g., 300-post count, WordPress export age).
2. Cross-reference `docs/NORMALIZATION_SCRIPT_DEV_PLAN.md` for the script design.
3. Pull subsets of `wp-import/` from the OLD repo on-demand (don't dump the whole 800 MB into NEW).
4. Use `_posts/*.NORMALIZED.md` drafts in OLD as quality checkpoints — but don't trust them as final.
