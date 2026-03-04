#!/usr/bin/env bash
# Test validate_test_cmd allowlist-based command validation
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
FORGE_DIR="$TESTS_DIR/.."
source "$FORGE_DIR/lib/common.sh" 2>/dev/null || { echo "SKIP: cannot source common.sh"; exit 0; }

# --- Valid commands ---

validate_test_cmd "pytest tests/test_foo.py -x" || { echo "FAIL: 'pytest tests/test_foo.py -x' rejected"; exit 1; }

validate_test_cmd "bash check.sh" || { echo "FAIL: 'bash check.sh' rejected"; exit 1; }

validate_test_cmd "go test ./..." || { echo "FAIL: 'go test ./...' rejected"; exit 1; }

validate_test_cmd "python -m pytest" || { echo "FAIL: 'python -m pytest' rejected"; exit 1; }

validate_test_cmd "true" || { echo "FAIL: 'true' rejected"; exit 1; }

# --- Reject: backticks ---
if validate_test_cmd 'echo `whoami`' 2>/dev/null; then
  echo "FAIL: backticks not blocked"; exit 1
fi

# --- Reject: command substitution $(...) ---
if validate_test_cmd 'echo $(whoami)' 2>/dev/null; then
  echo "FAIL: command substitution \$(…) not blocked"; exit 1
fi

# --- Reject: && chaining ---
if validate_test_cmd "pytest && rm -rf /" 2>/dev/null; then
  echo "FAIL: && chaining not blocked"; exit 1
fi

# --- Reject: || chaining ---
if validate_test_cmd "pytest || echo pwned" 2>/dev/null; then
  echo "FAIL: || chaining not blocked"; exit 1
fi

# --- Reject: redirect > ---
if validate_test_cmd "pytest > /tmp/out" 2>/dev/null; then
  echo "FAIL: redirect > not blocked"; exit 1
fi

# --- Reject: newlines in command ---
cmd_with_newline=$'pytest\nrm -rf /'
if validate_test_cmd "$cmd_with_newline" 2>/dev/null; then
  echo "FAIL: newline in command not blocked"; exit 1
fi

# --- Reject: semicolon injection ---
if validate_test_cmd "pytest; rm -rf /" 2>/dev/null; then
  echo "FAIL: semicolon injection not blocked"; exit 1
fi

# --- Reject: pipe ---
if validate_test_cmd "cat file | grep x" 2>/dev/null; then
  echo "FAIL: pipe not blocked"; exit 1
fi

# --- Reject: empty command ---
if validate_test_cmd "" 2>/dev/null; then
  echo "FAIL: empty command not blocked"; exit 1
fi

echo "All validate_cmd tests passed"
