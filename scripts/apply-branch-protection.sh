#!/usr/bin/env bash
# Apply the branch-protection rules from .github/branch-protection.json to
# the live GitHub repo. Addresses [REVIEW-1] + [REVIEW-14]: `gh api --input`
# with the committed JSON directly would 400 because the file has wrapper
# keys (`_comment`, `branch`, `applied_at`, `notes`) that the GitHub API
# rejects. We pipe through jq to extract the `rules` sub-object.
#
# Usage:
#   scripts/apply-branch-protection.sh                 # default repo
#   scripts/apply-branch-protection.sh owner/repo      # explicit repo
#
# Requires: gh CLI authenticated with admin rights on the target repo.
# Side effect: mutates branch-protection on `main`. Runs dry-run first.

set -euo pipefail

REPO="${1:-ghislaindelabie/delabie-tech}"
JSON="$(dirname "$0")/../.github/branch-protection.json"
BRANCH="$(jq -r '.branch // "main"' "$JSON")"

echo "Target:  $REPO @ $BRANCH"
echo "Source:  $JSON"
echo

# Extract the rules sub-object — that's the API-shaped payload.
PAYLOAD="$(jq '.rules' "$JSON")"

echo "--- Payload preview ---"
echo "$PAYLOAD" | jq '.'
echo "----------------------"
echo

read -r -p "Apply this to $REPO @ $BRANCH? [y/N] " yn
case "$yn" in
  [Yy]*)
    ;;
  *)
    echo "Aborted."
    exit 1
    ;;
esac

echo "$PAYLOAD" | gh api \
  --method PUT \
  "/repos/$REPO/branches/$BRANCH/protection" \
  --input -

echo
echo "Applied. Verifying…"
gh api "/repos/$REPO/branches/$BRANCH/protection" \
  --jq '{contexts: .required_status_checks.contexts, enforce_admins: .enforce_admins.enabled, allow_force_pushes: .allow_force_pushes.enabled}'

echo
echo "Remember to update .github/branch-protection.json's `applied_at` field"
echo "if this change landed today, and commit it as a follow-up."
