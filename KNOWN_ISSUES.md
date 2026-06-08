# Known issues & deferred features

Current limitations and the workarounds / decisions behind them.

## Search is hidden (no index yet)

**Status:** intentionally hidden (2026-06-08).

Chirpy's bundled search (`simple-jekyll-search`) reads `assets/js/data/search.json`, whose gem template indexes **only `site.posts`**. This site has no `_posts` yet (the blog migration is post-cutover), so every query — including "AI" or "Data" — returns nothing.

The search UI is hidden via CSS in `_sass/addon/ux-polish.scss` (the DOM is kept so the theme's search JS still initialises cleanly). Re-enabling is just removing that rule **once a real index exists**.

**Decision:** ship a proper, "powerful enough" search or none — not a half-working one. A useful index must cover the custom collections (case studies, publications, teaching, archive) and the tab pages, **and** be language-aware (an EN-page search must not surface FR results, and vice versa). Chirpy's single global `search.json` doesn't do this out of the box.

**To revisit (future feature, not pre-cutover):**
- Fork `assets/js/data/search.json` to index the collections + tabs, not just posts.
- Scope results by `page.lang` (two indexes, or a `lang` field filtered client-side).
- Re-show the search affordance (remove the hide rule in `ux-polish.scss`).
- Consider whether the blog migration landing real posts changes the calculus (it makes the default index non-empty, but the bilingual + collections gaps remain).
