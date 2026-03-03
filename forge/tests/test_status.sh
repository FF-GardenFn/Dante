#!/usr/bin/env bash
# Test forge status runs without error
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
FORGE_BIN="$TESTS_DIR/../bin/forge"
TMP=$(mktemp -d)
trap "rm -rf '$TMP'" EXIT

cd "$TMP"
bash "$FORGE_BIN" init 2>&1 >/dev/null

# Status with no orders should not crash
output=$(bash "$FORGE_BIN" status 2>&1) || { echo "FAIL: status crashed with no orders"; exit 1; }
echo "$output" | grep -qi "FORGE STATUS\|STATUS" || { echo "FAIL: no status header"; exit 1; }

# Create an order and check status includes it
bash "$FORGE_BIN" order create S01 --goal "Status test" 2>&1 >/dev/null
output=$(bash "$FORGE_BIN" status 2>&1) || { echo "FAIL: status crashed with orders"; exit 1; }
echo "$output" | grep -q "S01" || { echo "FAIL: S01 not in status output"; exit 1; }

echo "All status tests passed"
