import { readdirSync, readFileSync, statSync } from "fs";
import { join, resolve } from "path";

// Repo root, relative to this file (tests/playwright/e2e/helpers/).
const REPO_ROOT = resolve(__dirname, "../../../..");

// Content roots Jekyll actually serves. Deliberately excludes `docs/`
// (build-excluded in _config.yml), `_site/`, vendor, and the root *_PLAN.md
// strategy files — none of those are served, so a `translated: false` flag
// in them is irrelevant to the language switcher.
const CONTENT_ROOTS = [
  "_tabs",
  "_case_studies",
  "_publications",
  "_teaching",
  "_archive",
  "_activity",
  "_migration",
  "phase1-notes",
  "ia-mobilite",
];

const FRONT_MATTER = /^---\r?\n([\s\S]*?)\r?\n---/;

function walk(dir: string): string[] {
  let out: string[] = [];
  let entries: string[];
  try {
    entries = readdirSync(dir);
  } catch {
    return out;
  }
  for (const name of entries) {
    const full = join(dir, name);
    const st = statSync(full);
    if (st.isDirectory()) {
      out = out.concat(walk(full));
    } else if (/\.(md|markdown|html)$/.test(name)) {
      out.push(full);
    }
  }
  return out;
}

function parseFrontMatter(file: string): Record<string, string> | null {
  const raw = readFileSync(file, "utf8");
  const m = raw.match(FRONT_MATTER);
  if (!m) return null;
  const fields: Record<string, string> = {};
  for (const line of m[1].split(/\r?\n/)) {
    const kv = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (!kv) continue;
    let value = kv[2].trim();
    value = value.replace(/^['"]|['"]$/g, "");
    fields[kv[1]] = value;
  }
  return fields;
}

// Finds a served content document flagged `translated: false` that carries
// an explicit `permalink`, so the spec doesn't hardcode `/phase1-notes/`.
// Returns the EN-side permalink (the page on which the OTHER language must
// render the unavailable state). Returns null if no such doc exists — in
// which case the caller skips, since there's no unavailable branch to test.
export function findUntranslatedPermalink(): { url: string; lang: string } | null {
  for (const root of CONTENT_ROOTS) {
    for (const file of walk(join(REPO_ROOT, root))) {
      const fm = parseFrontMatter(file);
      if (!fm) continue;
      if (fm.translated !== "false") continue;
      if (!fm.permalink) continue;
      return { url: fm.permalink, lang: fm.lang || "en" };
    }
  }
  return null;
}
