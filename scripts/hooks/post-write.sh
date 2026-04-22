#!/usr/bin/env bash
# Claude Code PostToolUse hook — Edit|Write matcher.
# Warns (non-blocking) when protected files are modified, so Ghislain sees
# the modification even if Claude didn't flag it.

set -euo pipefail

payload="$(cat)"

file_path="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    path = data.get("input", {}).get("file_path", "")
    print(path, end="")
except Exception:
    pass
')"

[[ -z "$file_path" ]] && exit 0

protected_patterns=(
  ".github/workflows/"
  ".github/branch-protection.json"
  ".claude/settings.json"
  "CLAUDE.md"
  "scripts/hooks/"
)

for pattern in "${protected_patterns[@]}"; do
  if [[ "$file_path" == *"$pattern"* ]]; then
    echo "HOOK WARNING: modified protected path — $file_path" >&2
    echo "  Per CLAUDE.md this normally requires explicit Ghislain approval." >&2
    echo "  Continuing (non-blocking); ensure the PR description calls this out." >&2
    break
  fi
done

exit 0
