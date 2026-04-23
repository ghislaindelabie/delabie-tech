# Security review records

Per `CLAUDE.md` → "Local review workflow", each substantive PR lands a
`PR-{number}.md` file in this directory summarising the security-review
subagent's findings for that change.

Format convention:

```markdown
# Security review — PR #{n}: {PR title}

**Date:** YYYY-MM-DD
**Reviewer:** local `security-review` skill (Opus 4.7)
**Scope:** {diff summary — files, line counts}

## (1) What was reviewed

...

## (2) Security-relevant decisions

...

## (3) Risks accepted with rationale

| Tag | Severity | Risk | Rationale |
|---|---|---|---|

## (4) Recommended follow-ups

...

## Severity roll-up

| CRITICAL | HIGH | MEDIUM | LOW | NONE |
| -------- | ---- | ------ | --- | ---- |
| 0        | 0    | 0      | N   | —    |
```

## Why committed in-tree rather than posted as PR comments

- **Version-controlled audit trail** — searchable, survives repo history, doesn't depend on GitHub's comment persistence.
- **Reviewable in the PR diff** — the security summary is part of the PR itself, not a separate artifact.
- **Self-contained** — anyone reading the repo later can reconstruct the security posture at any point in git history.
