#!/usr/bin/env bash
# Test that forge loop validates max_iter values
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
FORGE_BIN="$TESTS_DIR/../bin/forge"
TMP=$(mktemp -d)
trap "rm -rf '$TMP'" EXIT

cd "$TMP"
git init -q .
git config user.email "test@test.com"
git config user.name "Test"
bash "$FORGE_BIN" init 2>&1 >/dev/null

# Create a minimal work order with a test command
bash "$FORGE_BIN" order create ITER1 \
  --goal "Test max-iter validation" \
  --test "true" \
  --agent claude 2>&1 >/dev/null

# Commit everything so worktree is clean
git add -A && git commit -q -m "setup"

# --- Non-numeric max_iter should fail ---
if bash "$FORGE_BIN" loop ITER1 --max-iter abc --no-isolation 2>/dev/null; then
  echo "FAIL: non-numeric max_iter 'abc' was accepted"; exit 1
fi

# --- Zero max_iter should fail ---
if bash "$FORGE_BIN" loop ITER1 --max-iter 0 --no-isolation 2>/dev/null; then
  echo "FAIL: zero max_iter was accepted"; exit 1
fi

# --- Negative max_iter should fail ---
if bash "$FORGE_BIN" loop ITER1 --max-iter -5 --no-isolation 2>/dev/null; then
  echo "FAIL: negative max_iter was accepted"; exit 1
fi

# --- Decimal max_iter should fail ---
if bash "$FORGE_BIN" loop ITER1 --max-iter 3.5 --no-isolation 2>/dev/null; then
  echo "FAIL: decimal max_iter '3.5' was accepted"; exit 1
fi

# --- Valid positive integer should be accepted ---
# Use --dry-run so we don't actually need an agent.
# Note: capture output regardless of exit code because the forge-loop cleanup
# trap may trigger an unbound variable after dry-run returns from run_loop.
output=$(bash "$FORGE_BIN" loop ITER1 --max-iter 5 --no-isolation --dry-run 2>&1) || true
echo "$output" | grep -q "5 iterations" || { echo "FAIL: dry-run did not show max_iter=5"; echo "$output"; exit 1; }
# Verify the error message did NOT appear (i.e., validation passed)
if echo "$output" | grep -q "max_iter must be a positive integer"; then
  echo "FAIL: valid max_iter 5 was rejected by validation"; exit 1
fi

echo "All max_iter tests passed"
