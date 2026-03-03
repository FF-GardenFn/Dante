#!/usr/bin/env bash
# Test file isolation detects untracked files in forbidden dirs
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
FORGE_BIN="$TESTS_DIR/../bin/forge"
TMP=$(mktemp -d)
trap "rm -rf '$TMP'" EXIT

cd "$TMP"
git init -q .
bash "$FORGE_BIN" init 2>&1 >/dev/null

# Source common.sh for check_file_isolation
source "$TESTS_DIR/../lib/common.sh" 2>/dev/null
FORGE_ROOT="$TMP"
FORGE_DIR="$TMP/.forge"

# Create work order with file scope
bash "$FORGE_BIN" order create ISO1 \
  --goal "Test isolation" \
  --test "true" \
  --files-allowed "src/" \
  --files-forbidden "secrets/" 2>&1 >/dev/null

order_file="$FORGE_DIR/work_orders/ISO1.md"

# No changes: should pass
violations=$(check_file_isolation "$order_file" "$TMP" 2>/dev/null) || true
[[ -z "$violations" ]] || { echo "FAIL: false violation on clean repo"; exit 1; }

# Create untracked file in forbidden dir
mkdir -p secrets
echo "leaked" > secrets/api_key.txt

violations=$(check_file_isolation "$order_file" "$TMP" 2>/dev/null) || true
[[ -n "$violations" ]] || { echo "FAIL: untracked file in forbidden dir not detected"; exit 1; }
echo "$violations" | grep -q "secrets" || { echo "FAIL: violation doesn't mention secrets dir"; exit 1; }

# Create untracked file in allowed dir: should pass
rm -rf secrets
mkdir -p src
echo "ok" > src/new_file.py

violations=$(check_file_isolation "$order_file" "$TMP" 2>/dev/null) || true
[[ -z "$violations" ]] || { echo "FAIL: allowed file flagged: $violations"; exit 1; }

echo "All file isolation tests passed"
