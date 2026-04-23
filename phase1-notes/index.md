---
layout: page
title: Phase 1 Notes
lang: en
ref: phase1-notes
permalink: /phase1-notes/
translated: false
sitemap: false
---

Milestone note for the Chirpy migration — Phase 1 (custom bilingual layer). Not linked from the main navigation; reachable by direct URL only.

Phase 1 replaced the previous i18n plugin with a plain-Jekyll pattern: content files ship as `name.md` (English) and `name.fr.md` (French), linked by a shared `ref` in the frontmatter. The site builds to identical URLs, with `hreflang` alternates and a discreet language switcher in the sidebar. Every change runs through CI that enforces the pair invariants, so future content additions can't drift out of sync.
