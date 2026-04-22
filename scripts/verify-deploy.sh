#!/usr/bin/env bash
# Smoke test a deployed site. Used both locally and in CI after deploy.
#
# Usage: scripts/verify-deploy.sh <base_url>

set -euo pipefail

base="${1:-}"
if [[ -z "$base" ]]; then
  echo "usage: $0 <base_url>" >&2
  exit 2
fi

fail=0

check() {
  local path="$1"
  local expected_status="${2:-200}"
  local url="${base%/}${path}"
  local status
  status="$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "$url" || echo "000")"
  if [[ "$status" != "$expected_status" ]]; then
    echo "FAIL  $url  got $status, expected $expected_status" >&2
    fail=1
  else
    echo "OK    $url  $status"
  fi
}

echo "Verifying deployment at $base ..."
check "/" 200
check "/about/" 200

# Sitemap + robots should always exist
check "/sitemap.xml" 200
check "/robots.txt" 200

if [[ "$fail" -eq 0 ]]; then
  echo "Deployment smoke: OK"
  exit 0
else
  echo "Deployment smoke: FAILED"
  exit 1
fi
