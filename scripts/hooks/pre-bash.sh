#!/usr/bin/env bash
# Claude Code PreToolUse hook — Bash matcher.
# Blocks high-risk git / gh operations at the client layer. Server-side
# GitHub branch-protection rules remain the authoritative gate.
#
# Claude Code passes the intended command via stdin as JSON:
#   { "tool": "Bash", "input": { "command": "git push origin main" } }
# This script exits non-zero to deny; zero to allow.

set -euo pipefail

payload="$(cat)"

# Extract the command (portable jq-free reading)
command_str="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get("input", {}).get("command", ""), end="")
except Exception:
    pass
')"

if [[ -z "$command_str" ]]; then
  exit 0  # nothing to inspect
fi

block() {
  echo "HOOK BLOCK: $1" >&2
  echo "Command: $command_str" >&2
  echo "Reason: see CLAUDE.md — per-repo rules forbid this operation." >&2
  exit 2
}

# Direct push to main
if echo "$command_str" | grep -qE '^[[:space:]]*git[[:space:]]+push[[:space:]]+(-u[[:space:]]+)?origin[[:space:]]+main(\b|$)'; then
  block "direct push to main is forbidden. Use a feature branch + PR."
fi

# Force-push anywhere
if echo "$command_str" | grep -qE '^[[:space:]]*git[[:space:]]+push.*(-f\b|--force\b)'; then
  block "force-push is forbidden (including on feature branches) without explicit approval."
fi

# Skip commit hooks
if echo "$command_str" | grep -qE 'git[[:space:]]+commit.*--no-verify'; then
  block "committing with --no-verify bypasses local checks."
fi

# Hard reset
if echo "$command_str" | grep -qE '^[[:space:]]*git[[:space:]]+reset[[:space:]]+--hard'; then
  block "git reset --hard is destructive; get explicit approval first."
fi

# PR merge — Ghislain merges, not the agent
if echo "$command_str" | grep -qE '^[[:space:]]*gh[[:space:]]+pr[[:space:]]+merge'; then
  block "PR merge is reserved to Ghislain. Ping him with the PR URL instead."
fi

# Branch-protection changes
if echo "$command_str" | grep -qE 'gh[[:space:]]+api.*-(X|-method)[[:space:]]+(PATCH|PUT|DELETE).*branches/main/protection'; then
  block "branch-protection changes require explicit approval."
fi

# Destructive gh api on the repo
if echo "$command_str" | grep -qE 'gh[[:space:]]+api[[:space:]]+.*-(X|-method)[[:space:]]+DELETE[[:space:]]+/repos/'; then
  block "destructive gh api DELETE on a repo is forbidden."
fi

exit 0
