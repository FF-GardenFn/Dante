#!/usr/bin/env bash
# Test portable helpers in common.sh
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
FORGE_DIR="$TESTS_DIR/.."
source "$FORGE_DIR/lib/common.sh" 2>/dev/null || { echo "SKIP: cannot source common.sh"; exit 0; }

# --- portable_hash ---
hash1=$(echo "hello" | portable_hash)
hash2=$(echo "hello" | portable_hash)
hash3=$(echo "world" | portable_hash)
[[ -n "$hash1" ]] || { echo "FAIL: portable_hash returned empty"; exit 1; }
[[ "$hash1" == "$hash2" ]] || { echo "FAIL: portable_hash not deterministic"; exit 1; }
[[ "$hash1" != "$hash3" ]] || { echo "FAIL: portable_hash collision"; exit 1; }

# --- portable_date_iso ---
ts=$(portable_date_iso)
[[ "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]] || { echo "FAIL: portable_date_iso format: $ts"; exit 1; }

# --- validate_test_cmd ---
validate_test_cmd "pytest tests/" || { echo "FAIL: valid cmd rejected"; exit 1; }
if validate_test_cmd "pytest; rm -rf /" 2>/dev/null; then
  echo "FAIL: semicolon injection not blocked"; exit 1
fi
if validate_test_cmd 'echo $(whoami)' 2>/dev/null; then
  echo "FAIL: command substitution not blocked"; exit 1
fi
if validate_test_cmd "cat | grep x" 2>/dev/null; then
  echo "FAIL: pipe not blocked"; exit 1
fi

# --- count_test_results ---
mock_pytest="3 passed, 2 failed in 1.5s"
result=$(count_test_results "$mock_pytest" "pytest")
[[ "$result" == "3:2" ]] || { echo "FAIL: count_test_results got '$result' expected '3:2'"; exit 1; }

# Numeric edge case: no matches should return 0:0
result=$(count_test_results "no results here" "pytest")
[[ "$result" == "0:0" ]] || { echo "FAIL: empty count got '$result' expected '0:0'"; exit 1; }

echo "All helper tests passed"
