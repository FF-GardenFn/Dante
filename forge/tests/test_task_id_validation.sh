#!/usr/bin/env bash
# Test that validate_task_id rejects invalid IDs and accepts valid ones
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
FORGE_DIR="$TESTS_DIR/.."
source "$FORGE_DIR/lib/common.sh" 2>/dev/null || { echo "SKIP: cannot source common.sh"; exit 0; }

# --- Invalid: spaces ---
if validate_task_id "bad task" 2>/dev/null; then
  echo "FAIL: task ID with spaces was accepted"; exit 1
fi

# --- Invalid: semicolons ---
if validate_task_id "bad;id" 2>/dev/null; then
  echo "FAIL: task ID with semicolons was accepted"; exit 1
fi

# --- Invalid: path traversal ---
if validate_task_id "../escape" 2>/dev/null; then
  echo "FAIL: task ID with ../ was accepted"; exit 1
fi

# --- Invalid: empty string ---
if validate_task_id "" 2>/dev/null; then
  echo "FAIL: empty task ID was accepted"; exit 1
fi

# --- Invalid: shell metacharacters ---
if validate_task_id 'id$(whoami)' 2>/dev/null; then
  echo "FAIL: task ID with command substitution was accepted"; exit 1
fi

# --- Valid: simple alphanumeric ---
validate_task_id "C01" || { echo "FAIL: valid ID 'C01' rejected"; exit 1; }

# --- Valid: hyphens and underscores ---
validate_task_id "my-task_2" || { echo "FAIL: valid ID 'my-task_2' rejected"; exit 1; }

# --- Valid: all uppercase ---
validate_task_id "FIX_DB_LOCKS" || { echo "FAIL: valid ID 'FIX_DB_LOCKS' rejected"; exit 1; }

# --- Valid: single character ---
validate_task_id "A" || { echo "FAIL: valid ID 'A' rejected"; exit 1; }

echo "All task ID validation tests passed"
