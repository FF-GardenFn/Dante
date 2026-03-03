#!/usr/bin/env bash
# Forge self-test runner
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
passed=0
failed=0
errors=""

for test_file in "$TESTS_DIR"/test_*.sh; do
  [[ -f "$test_file" ]] || continue
  name=$(basename "$test_file" .sh)
  printf "  %-30s " "$name"
  if output=$(bash "$test_file" 2>&1); then
    echo "PASS"
    passed=$((passed + 1))
  else
    echo "FAIL"
    errors="${errors}\n--- ${name} ---\n${output}\n"
    failed=$((failed + 1))
  fi
done

echo ""
echo "  Results: ${passed} passed, ${failed} failed"

if [[ -n "$errors" ]]; then
  echo ""
  echo "  Failures:"
  echo -e "$errors"
  exit 1
fi
