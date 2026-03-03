#!/usr/bin/env bash
# Test work order creation and listing
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
FORGE_BIN="$TESTS_DIR/../bin/forge"
TMP=$(mktemp -d)
trap "rm -rf '$TMP'" EXIT

cd "$TMP"
bash "$FORGE_BIN" init 2>&1 >/dev/null

# Create a work order
bash "$FORGE_BIN" order create T01 --goal "Fix the bug" --test "pytest tests/" 2>&1 >/dev/null
[[ -f ".forge/work_orders/T01.md" ]] || { echo "FAIL: order file not created"; exit 1; }

# Verify fields
grep -q "goal: Fix the bug" ".forge/work_orders/T01.md" || { echo "FAIL: goal not in order"; exit 1; }
grep -q "test_cmd: pytest tests/" ".forge/work_orders/T01.md" || { echo "FAIL: test_cmd not in order"; exit 1; }
grep -q "status: open" ".forge/work_orders/T01.md" || { echo "FAIL: status not open"; exit 1; }

# Duplicate should fail
if bash "$FORGE_BIN" order create T01 --goal "Dup" 2>/dev/null; then
  echo "FAIL: duplicate creation should fail"; exit 1
fi

# List should show the order
list_output=$(bash "$FORGE_BIN" order list 2>&1)
echo "$list_output" | grep -q "T01" || { echo "FAIL: T01 not in list"; exit 1; }

# Create with all options
bash "$FORGE_BIN" order create T02 \
  --goal "Add feature" \
  --test "true" \
  --files-allowed "src/" \
  --files-forbidden "tests/" \
  --constraints "No external deps" \
  --agent claude \
  --priority 1 2>&1 >/dev/null

[[ -f ".forge/work_orders/T02.md" ]] || { echo "FAIL: T02 not created"; exit 1; }
grep -q "priority: 1" ".forge/work_orders/T02.md" || { echo "FAIL: priority not set"; exit 1; }
grep -q "agent: claude" ".forge/work_orders/T02.md" || { echo "FAIL: agent not set"; exit 1; }

echo "All order tests passed"
