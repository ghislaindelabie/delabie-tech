# `_migration/` — one-shot import scripts

Scripts for bulk-importing content into the Jekyll collections. Each script is self-contained, idempotent, and reads a curated seed file.

## Phase 4b.2 — `archive_import.rb`

Imports `_archive/` items from `archive_seed.yml`.

```sh
# Dry-run (default) — validates the seed and prints what would happen.
bundle exec ruby _migration/archive_import.rb

# Real run — writes paired EN/FR .md files and fetches PDFs.
bundle exec ruby _migration/archive_import.rb --commit

# Skip the PDF fetch step (network-free).
bundle exec ruby _migration/archive_import.rb --commit --no-fetch-pdf

# Process a single item (debugging).
bundle exec ruby _migration/archive_import.rb --commit --only florence-intermodal-2022
```

### What it does, per item

1. **Validate** — schema gates mirror `tests/structural/archive_collection_spec.rb` (slug shape, allowed types/roles, URL safety, tags non-empty, EN+FR title+excerpt present).
2. **Skip if existing** — if `_archive/<slug>.md` is already on disk, no overwrite. To force a re-import, delete the file first.
3. **Fetch PDF (optional)** — `GET original_url`. If `Content-Type: application/pdf` and < 30 MB, save to `/assets/pdf/archive/<slug>.pdf` and set the `pdf:` field. Otherwise log `warn_link_only` (still writes the .md, just no local copy).
4. **Write paired .md** — `_archive/<slug>.md` (EN) + `_archive/<slug>.fr.md` (FR), with frontmatter authored from the seed and the FR file carrying the explicit `/fr/archive/<year>/<slug>/` permalink (mirrors the `_case_studies/*.fr.md` convention).
5. **Append to report** — `_migration/archive_import.report.md` is rewritten each run with three sections: summary table, per-status grouping, per-item log.

### Why no LLM call

V1 ships ~30 items; bilingual content is authored directly in the seed YAML. Faster to review, no API key, no flaky external dep. If a later phase scales to hundreds of items or new languages, wire an Anthropic call into `front_matter`/`validate` then.

### Why Ruby (not Python)

Matches the existing toolchain (`Gemfile`, `bundle exec ...` already in `package.json` `scripts`). No new requirements.txt, venv, or `pip install` step. Standard library covers HTTP, YAML, file I/O.

### Statuses logged in the report

| Status | Meaning |
|---|---|
| `invalid` | Seed entry failed schema validation; not imported. |
| `skip_existing` | `_archive/<slug>.md` already on disk; no-op. |
| `pdf_fetched` | PDF saved to `/assets/pdf/archive/<slug>.pdf`. |
| `pdf_already` | PDF was already at the destination; skipped fetch. |
| `warn_link_only` | `original_url` returned non-PDF content; the .md is still written without a local PDF. |
| `warn_redirect` | `original_url` redirected; not followed automatically. Update the seed with the resolved URL. |
| `warn_too_large` | PDF exceeded the 30 MB limit; download manually if you want a local copy. |
| `fail_fetch` | Network/HTTP error. Item is still .md-importable on a re-run with `--no-fetch-pdf`. |
| `written` | EN + FR .md pair created. |
| `dry_would_write` / `dry_pdf_skipped` | Dry-run only — no side effects. |
