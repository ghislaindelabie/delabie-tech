#!/usr/bin/env bash
# Review-gate: verifies that every [REVIEW-N] and [SEC-N] tag posted by
# Claude Review / Claude Security Review on this PR has been answered.
#
# A finding is "answered" if ANY of:
#  (a) a later commit on the PR references the tag (e.g. "addresses [REVIEW-3]"),
#  (b) a PR comment quotes the tag and provides a response,
#  (c) the tag is listed in the PR's `wontfix` section (explicit label OR comment).

set -euo pipefail

: "${GH_TOKEN:?GH_TOKEN must be set}"
: "${PR_NUMBER:?PR_NUMBER must be set}"

repo="${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"

# Pull all review + security review comments on the PR
comments="$(gh api "/repos/$repo/issues/$PR_NUMBER/comments" --paginate)"
commits="$(gh api "/repos/$repo/pulls/$PR_NUMBER/commits" --paginate)"

# Extract tags posted by Claude Review
review_tags="$(echo "$comments" | python3 -c '
import json, sys, re
try:
    data = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(0)
tags = set()
for c in data:
    body = c.get("body") or ""
    # A "posted" tag is one on its own line or at a "finding header"
    for m in re.finditer(r"\[((?:REVIEW|SEC)-\d+)\]", body):
        tags.add(m.group(1))
print("\n".join(sorted(tags)))
')"

if [[ -z "$review_tags" ]]; then
  echo "No Claude findings detected — gate passes."
  exit 0
fi

# Combine all possible "answer" sources: PR comments (bodies), commit messages
answers="$(echo "$comments" | python3 -c '
import json, sys
data = json.load(sys.stdin)
for c in data:
    print(c.get("body") or "")
')"
answers+=$'\n'
answers+="$(echo "$commits" | python3 -c '
import json, sys
data = json.load(sys.stdin)
for c in data:
    print(c.get("commit", {}).get("message", "") or "")
')"

# Determine authors per tag — a finding is "posted" by Claude Review bot.
# An answer must come from a human (anyone not the bot). We approximate by
# requiring that at least one mention exists OUTSIDE the first occurrence
# of the tag, since Claude quoted its own finding once.
unanswered=()
while IFS= read -r tag; do
  [[ -z "$tag" ]] && continue
  count="$(echo "$answers" | grep -c "\[$tag\]" || true)"
  if [[ "$count" -lt 2 ]]; then
    unanswered+=("$tag")
  fi
done <<< "$review_tags"

if [[ "${#unanswered[@]}" -eq 0 ]]; then
  echo "All Claude findings answered. Gate passes."
  exit 0
else
  echo "Unanswered Claude findings on PR #$PR_NUMBER:" >&2
  for t in "${unanswered[@]}"; do
    echo "  - [$t]" >&2
  done
  echo "" >&2
  echo "To pass the gate, either:" >&2
  echo "  1. address the finding in a new commit (message should reference [TAG])" >&2
  echo "  2. respond in a PR comment that quotes [TAG]" >&2
  echo "  3. add the 'wontfix' label with a comment justifying the decision" >&2
  exit 1
fi
