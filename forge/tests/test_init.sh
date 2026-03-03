#!/usr/bin/env bash
# Test forge init creates correct directory structure
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
FORGE_BIN="$TESTS_DIR/../bin/forge"
TMP=$(mktemp -d)
trap "rm -rf '$TMP'" EXIT

cd "$TMP"
bash "$FORGE_BIN" init 2>&1 >/dev/null

# Check directories
[[ -d ".forge" ]] || { echo "FAIL: .forge not created"; exit 1; }
[[ -d ".forge/work_orders" ]] || { echo "FAIL: work_orders not created"; exit 1; }
[[ -d ".forge/sessions/active" ]] || { echo "FAIL: sessions/active not created"; exit 1; }
[[ -d ".forge/sessions/logs" ]] || { echo "FAIL: sessions/logs not created"; exit 1; }
[[ -d ".forge/hashes" ]] || { echo "FAIL: hashes not created"; exit 1; }
[[ -d ".forge/signals" ]] || { echo "FAIL: signals not created"; exit 1; }
[[ -d ".forge/context" ]] || { echo "FAIL: context not created"; exit 1; }
[[ -f ".forge/config" ]] || { echo "FAIL: config not created"; exit 1; }

# Re-init with --force should not fail
bash "$FORGE_BIN" init --force 2>&1 >/dev/null || { echo "FAIL: re-init --force failed"; exit 1; }

echo "All init tests passed"
