# CLAUDE.md — delabie-tech

Project-level rules for any Claude Code agent operating on this repo. See `CHIRPY_MIGRATION_PLAN.md` for the master migration plan.

## Project context

**Purpose:** parallel test site for the migration from `delabie.tech` (al-folio) to Chirpy + custom i18n. Served at `v2.delabie.tech`. Cuts over to `delabie.tech` when the plan's exit criteria are met.

**Stack:** Jekyll + Chirpy (gem) + custom bilingual Liquid + GitHub Actions + GitHub Pages.

## Git workflow (hard rules)

1. **NEVER commit directly to `main`.** Every change goes through a feature branch and a pull request.
2. **NEVER push to `main`.** Enforced by branch protection + `.claude/settings.json` hooks.
3. **NEVER force-push to `main`.** Force-push is allowed only on feature branches before PR review starts.
4. **NEVER run `git reset --hard` on `main` or on any branch with unpushed human review.**
5. **NEVER merge a PR yourself.** Ghislain clicks Merge in the GitHub UI. This applies pre- and post-cutover. `gh pr merge` is blocked by hooks.
6. **NEVER modify branch-protection rules.** `.github/branch-protection.json` is the committed snapshot; changes require explicit Ghislain approval.
7. **Wait for Ghislain's feedback on phase N before merging phase N+1.** The per-phase protocol lives in `CHIRPY_MIGRATION_PLAN.md` §5.0. Never have more than one unmerged feature branch awaiting review.

## Branch naming

- `feature/phase-N-<slug>` — phase work per the migration plan
- `fix/<slug>` — bug fix on the test site
- `docs/<slug>` — documentation-only changes
- `hotfix/<slug>` — urgent fixes, same gates as feature branches

## Commit guidelines

- Conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `perf:`, `security:`, `test:`, `refactor:`.
- **No AI/Claude mentions in commit messages or PR descriptions.** No `Co-Authored-By: Claude`.
- Keep commits atomic.
- Never commit secrets, `.env` files, or tokens.
- Never skip hooks (`--no-verify`, `--no-gpg-sign`).

## PR policy

- Every PR must have a description that references the phase it implements and the plan section it satisfies.
- Every PR must follow the **"Local review workflow"** section further down: run the `code-reviewer` subagent and the `security-review` skill locally, act on findings, commit `docs/security/PR-{n}.md`, include the Review-summary block in the PR description.
- CI required green on: `Build + structural + links + Playwright`. That's the only CI gate; code + security review are local (see the Local review workflow section for triggers that would reactivate them in CI).

## Testing

- Run the full suite locally before pushing: `npm run test` (or `make test`).
- Tests must be **template-based** (operate over layouts and components), not content-based. Adding a blog post or a case study must not require touching tests.
- Every new layout or content collection gets its own template-level test in `tests/playwright/e2e/layouts/`.
- Every new component gets a test in `tests/playwright/e2e/components/`.

## Local dev loop

- For UI / content iteration, start the livereload server with `scripts/dev`. Serves at `http://127.0.0.1:4000` (EN) and `/fr/`; rebuilds + reloads the browser tab on any file change.
- `scripts/dev --lan` binds to `0.0.0.0` for LAN preview on a phone (use the LAN IP from `ipconfig getifaddr en0`).
- CI runs full `jekyll build` + RSpec + Playwright + lychee on every push — trust it as the final gate, use `scripts/dev` as the feedback loop for iteration.

## Allowed operations

- All `git` operations except `git push origin main`, `git push --force*`, and resets on protected branches.
- `gh pr create`, `gh pr view`, `gh pr list`, `gh pr checks`, `gh pr comment`, `gh api` for read operations.
- `bundle`, `npm`, `jekyll`, `rspec`, `playwright`, `lychee`, `html-proofer`.
- Reading files anywhere in the repo; writing files within the phase scope.

## Restricted operations

- Never push to `main` (blocked by hooks AND branch protection).
- Never run `gh pr merge` (blocked by hooks; Ghislain merges).
- Never modify `.github/branch-protection.json`, `.github/workflows/*`, or `.claude/settings.json` without explicit Ghislain approval.
- Never commit build artifacts (`_site/`, `node_modules/`, `playwright-report/`).
- Never add an analytics or comments provider without the plan section calling for it.

## Communication

- After merging a phase (via Ghislain), the next message to Ghislain is concise: **"Phase N merged. Live at v2.delabie.tech/<urls>. Review when you can. I'm starting phase N+1 on `feature/phase-(N+1)-...`; won't merge it until I have your feedback on N."**
- Findings that don't warrant a code change go in `tests/findings/YYYY-MM-DD-slug.md`.

## Local review workflow (replaces CI Claude Review / Security Review)

Solo-mode simplification: the `claude-review` and `claude-security-review` CI jobs were removed. I run them **locally, as subagents**, before opening any PR. The CI gate is now `Build + structural + links + Playwright` only.

### Enforcement model — honor system

No automated gate blocks a PR lacking the local-review steps. The old CI review-gate is gone. This works because I am the only committer on this repo; compliance is my responsibility. If you (a future agent or Ghislain) are reading this and tempted to skip: don't — the security review has caught real issues on every substantive PR so far, and the cost (~2–3 min local time) is negligible compared to the cost of merging a regression.

### Mandatory before opening any PR

1. **Run the `code-reviewer` subagent** via the `Agent` tool with `subagent_type: code-reviewer`. Brief it with:
   - The branch-vs-main diff summary (`git diff origin/main --stat`).
   - The phase context from `CHIRPY_MIGRATION_PLAN.md`.
   - What you want from the review (typical: bugs, regressions, template-level-vs-content-level test quality, plan/CLAUDE.md conformance, anything that would embarrass if merged unreviewed).
   - Explicit reminder that findings return to you as tool output — the subagent has no PR-posting capability in this context.

2. **Run the `security-review` skill** via the `Skill` tool with `skill: security-review`. Act on every CRITICAL / HIGH immediately. Commit the summary to `docs/security/PR-{number}.md` using the format in `docs/security/README.md`.

3. **Definition of "clean enough to open the PR":**
   - Zero CRITICAL findings unresolved.
   - Zero HIGH findings unresolved, unless each has an explicit deferral rationale IN the PR description AND a tracking issue filed (link from the PR description).
   - MEDIUM findings either resolved or noted in the PR description with one-line rationale. A tracking issue is optional but recommended for any MEDIUM deferred past two PRs.
   - LOW findings noted in the PR description or `docs/security/PR-{n}.md`.

4. **Only after both passes are clean** per step 3, open the PR.

### Mandatory in every PR description

A "Review summary" block with:

```markdown
## Review summary

**Code review** (local `code-reviewer` subagent, Opus 4.7)
- Severity roll-up: CRITICAL 0 · HIGH 0 · MEDIUM X · LOW Y · SUGGESTION Z
- Addressed: [REVIEW-N], [REVIEW-M] — see commits <sha>, <sha>
- Deferred with rationale: [REVIEW-N] "too broad for this PR; opened issue #xx"; [REVIEW-K] "cost > benefit at current scale"
- Not applicable: [REVIEW-L] "false positive — ..."

**Security review** (local `security-review` skill, Opus 4.7)
- See `docs/security/PR-{number}.md`
- Severity: CRITICAL 0 · HIGH 0 · MEDIUM 0 · LOW N
- Risks accepted: [SEC-N] "..." rationale
```

A deferred finding without a one-line rationale is the same as an unanswered finding — add the rationale or file an issue before opening the PR.

### Tool vs skill distinction

- **`code-reviewer`** is a subagent invoked via the `Agent` tool (`subagent_type: code-reviewer`). It explores the diff with Read/Grep/Glob and returns a structured review. Output stays in my conversation context.
- **`security-review`** is a skill invoked via the `Skill` tool (`skill: security-review`). It produces a structured security summary you commit to `docs/security/PR-{n}.md`.

Both run in the current Claude Code session with Opus. No external API calls, no CI job, no GitHub bot comments.

### When to reactivate CI review jobs

Revert [the commit that removed them] when any of these hit:
- A second human contributor joins the project.
- The project goes public / open-source (broader attack surface for PR content).
- Pre-cutover safety pass (plan §5.9) — optional extra gate before flipping production DNS.

Reactivation = revert that commit + run `scripts/apply-branch-protection.sh` after updating `.github/branch-protection.json` to re-add the three required status checks (`Claude Review (Opus 4.7)`, `Claude Security Review (Opus 4.7)`, `Review gate (findings answered)`). The helper `scripts/ci/review-gate.sh` is preserved in-tree for this purpose.
