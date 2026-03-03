#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# forge/lib/common.sh — Shared utilities for the Forge system
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

# ─── Colors ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ─── Cross-Platform Helpers ──────────────────────────────────
# Abstract macOS vs Linux differences.

sed_inplace() {
  if sed --version 2>/dev/null | grep -q 'GNU'; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}

portable_md5() {
  if command -v md5sum >/dev/null 2>&1; then
    md5sum | cut -d' ' -f1
  elif command -v md5 >/dev/null 2>&1; then
    md5 -r | cut -d' ' -f1
  elif command -v shasum >/dev/null 2>&1; then
    shasum | cut -d' ' -f1
  else
    cksum | cut -d' ' -f1
  fi
}

portable_date_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# ─── Forge Root Detection ─────────────────────────────────────
find_forge_root() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/.forge" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

FORGE_ROOT=""
init_forge_root() {
  FORGE_ROOT=$(find_forge_root) || {
    echo -e "${RED}Error: Not inside a Forge project.${RESET}" >&2
    echo -e "  Run ${CYAN}forge init${RESET} to initialize." >&2
    exit 1
  }
  export FORGE_ROOT
  export FORGE_DIR="$FORGE_ROOT/.forge"
}

# ─── Config Loading ───────────────────────────────────────────
get_config() {
  local key="$1"
  local default="${2:-}"
  local config_file="$FORGE_DIR/config"
  if [[ -f "$config_file" ]]; then
    local val
    val=$(grep "^${key}=" "$config_file" 2>/dev/null | head -1 | cut -d'=' -f2-)
    if [[ -n "$val" ]]; then
      echo "$val"
      return
    fi
  fi
  echo "$default"
}

set_config() {
  local key="$1"
  local value="$2"
  local config_file="$FORGE_DIR/config"
  if grep -q "^${key}=" "$config_file" 2>/dev/null; then
    sed_inplace "s|^${key}=.*|${key}=${value}|" "$config_file"
  else
    echo "${key}=${value}" >> "$config_file"
  fi
}

# ─── Work Order Parsing ──────────────────────────────────────
parse_order_field() {
  local order_file="$1"
  local field="$2"
  sed -n '/^---$/,/^---$/p' "$order_file" | grep "^${field}:" | head -1 | sed "s/^${field}:[[:space:]]*//"
}

parse_order_list_field() {
  local order_file="$1"
  local field="$2"
  parse_order_field "$order_file" "$field" | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//'
}

get_order_file() {
  local task_id="$1"
  local order_file="$FORGE_DIR/work_orders/${task_id}.md"
  if [[ ! -f "$order_file" ]]; then
    echo -e "${RED}Error: Work order '${task_id}' not found.${RESET}" >&2
    echo -e "  Expected: ${order_file}" >&2
    return 1
  fi
  echo "$order_file"
}

# ─── Agent Adapters ───────────────────────────────────────────
send_to_agent() {
  local agent_type="$1"
  local prompt="$2"
  local project_dir="$3"
  local log_file="${4:-/dev/null}"

  case "$agent_type" in
    claude)
      cd "$project_dir"
      claude -p "$prompt" --output-format text --allowedTools Edit,Write,Read,Bash,Glob,Grep 2>&1 | tee -a "$log_file"
      ;;
    codex)
      cd "$project_dir"
      codex "$prompt" 2>&1 | tee -a "$log_file"
      ;;
    gemini)
      cd "$project_dir"
      gemini "$prompt" 2>&1 | tee -a "$log_file"
      ;;
    *)
      echo -e "${RED}Unknown agent type: ${agent_type}${RESET}" >&2
      return 1
      ;;
  esac
}

# ─── Test Runner ──────────────────────────────────────────────

validate_test_cmd() {
  local cmd="$1"
  local unsafe_re='[;`$|&<>]'
  if [[ "$cmd" =~ $unsafe_re ]] || [[ "$cmd" =~ \$\( ]]; then
    echo -e "${RED}Error: test_cmd contains unsafe characters: ${cmd}${RESET}" >&2
    echo "  Test commands must not contain shell metacharacters." >&2
    echo "  Wrap complex commands in a script and reference the script path." >&2
    return 1
  fi
  return 0
}

run_test_suite() {
  local test_cmd="$1"
  local project_dir="$2"
  local raw_output
  local exit_code

  validate_test_cmd "$test_cmd" || return 1

  cd "$project_dir"
  raw_output=$(eval "$test_cmd" 2>&1) || exit_code=$?
  exit_code=${exit_code:-0}

  echo "$raw_output"
  return "$exit_code"
}

parse_test_failures() {
  local raw_output="$1"
  local test_framework="${2:-pytest}"

  case "$test_framework" in
    pytest)
      echo "$raw_output" | grep -E "(FAILED|ERROR|AssertionError|Exception)" | head -10
      ;;
    jest)
      echo "$raw_output" | grep -E "(FAIL|✕|●)" | head -10
      ;;
    go)
      echo "$raw_output" | grep -E "(FAIL|---)" | head -10
      ;;
    *)
      echo "$raw_output" | grep -iE "(fail|error|assert|exception|panic)" | head -10
      ;;
  esac
}

count_test_results() {
  local raw_output="$1"
  local test_framework="${2:-pytest}"
  local passed=0
  local failed=0

  case "$test_framework" in
    pytest)
      passed=$(echo "$raw_output" | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+' || echo "0")
      failed=$(echo "$raw_output" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' || echo "0")
      ;;
    jest)
      passed=$(echo "$raw_output" | grep -oE 'Tests:[[:space:]]+[0-9]+ passed' | grep -oE '[0-9]+' || echo "0")
      failed=$(echo "$raw_output" | grep -oE '[0-9]+ failed' | grep -oE '[0-9]+' || echo "0")
      ;;
    *)
      passed=$(echo "$raw_output" | grep -ciE 'pass|ok' || echo "0")
      failed=$(echo "$raw_output" | grep -ciE 'fail|error' || echo "0")
      ;;
  esac

  # Ensure numeric output (strip whitespace, default to 0)
  passed="${passed//[^0-9]/}"
  failed="${failed//[^0-9]/}"
  echo "${passed:-0}:${failed:-0}"
}

# ─── Cycle Detection ─────────────────────────────────────────

hash_current_diff() {
  local project_dir="$1"
  cd "$project_dir"
  {
    git diff 2>/dev/null
    git ls-files -o --exclude-standard -z 2>/dev/null | xargs -0 cat 2>/dev/null
  } | portable_md5
}

check_oscillation() {
  local current_hash="$1"
  local hash_file="$2"
  local lock_file="${hash_file}.lock"

  # Atomic file lock using noclobber (POSIX-portable, no flock needed)
  local attempts=0
  while ! (set -C; echo $$ > "$lock_file") 2>/dev/null; do
    attempts=$((attempts + 1))
    if [[ $attempts -gt 50 ]]; then
      rm -f "$lock_file"
      break
    fi
    sleep 0.1
  done

  local result=1  # Default: no oscillation
  if [[ -f "$hash_file" ]] && grep -qF "$current_hash" "$hash_file"; then
    result=0  # Oscillation detected
  else
    echo "$current_hash" >> "$hash_file"
  fi

  rm -f "$lock_file"
  return "$result"
}

# ─── Logging ──────────────────────────────────────────────────

log_info() {
  echo -e "${DIM}$(date '+%H:%M:%S')${RESET} ${BLUE}INFO${RESET}  $*"
}

log_ok() {
  echo -e "${DIM}$(date '+%H:%M:%S')${RESET} ${GREEN}OK${RESET}    $*"
}

log_warn() {
  echo -e "${DIM}$(date '+%H:%M:%S')${RESET} ${YELLOW}WARN${RESET}  $*"
}

log_error() {
  echo -e "${DIM}$(date '+%H:%M:%S')${RESET} ${RED}ERROR${RESET} $*"
}

log_fire() {
  echo -e "${DIM}$(date '+%H:%M:%S')${RESET} ${RED}🔥${RESET}     $*"
}

# ─── Session Helpers ──────────────────────────────────────────

get_session_name() {
  local task_id="$1"
  local agent="$2"
  echo "forge-${task_id}-${agent}"
}

is_session_active() {
  local session_name="$1"
  tmux has-session -t "$session_name" 2>/dev/null
}

# ─── Dependency Resolution ────────────────────────────────────

signal_done() {
  local task_id="$1"
  local timestamp
  timestamp=$(portable_date_iso)
  echo "$timestamp" > "$FORGE_DIR/signals/${task_id}.done"
  log_ok "Task ${task_id} signaled DONE"
}

is_task_done() {
  local task_id="$1"
  [[ -f "$FORGE_DIR/signals/${task_id}.done" ]]
}

check_dependencies() {
  local order_file="$1"
  local deps
  deps=$(parse_order_field "$order_file" "depends_on")
  if [[ -z "$deps" ]]; then
    return 0
  fi

  local all_met=true
  for dep in $(echo "$deps" | tr ',' ' '); do
    dep=$(echo "$dep" | xargs)
    if ! is_task_done "$dep"; then
      echo "$dep"
      all_met=false
    fi
  done

  if $all_met; then
    return 0
  else
    return 1
  fi
}

# ─── File Isolation Guard ────────────────────────────────────

check_file_isolation() {
  local order_file="$1"
  local project_dir="$2"

  local allowed
  allowed=$(parse_order_field "$order_file" "files_allowed")
  local forbidden
  forbidden=$(parse_order_field "$order_file" "files_forbidden")

  if [[ -z "$allowed" && -z "$forbidden" ]]; then
    return 0
  fi

  cd "$project_dir"
  local changed_files
  changed_files=$(
    {
      git diff --name-only 2>/dev/null
      git ls-files -o --exclude-standard 2>/dev/null
    } | grep -v '^\.forge/' | sort -u
  )

  if [[ -z "$changed_files" ]]; then
    return 0
  fi

  local violations=""

  if [[ -n "$forbidden" ]]; then
    for pattern in $(echo "$forbidden" | tr ',' ' '); do
      pattern=$(echo "$pattern" | xargs)
      local matches
      matches=$(echo "$changed_files" | grep -E "$pattern" || true)
      if [[ -n "$matches" ]]; then
        violations="${violations}FORBIDDEN: ${matches}\n"
      fi
    done
  fi

  if [[ -n "$allowed" ]]; then
    while IFS= read -r file; do
      local is_allowed=false
      for pattern in $(echo "$allowed" | tr ',' ' '); do
        pattern=$(echo "$pattern" | xargs)
        if echo "$file" | grep -qE "$pattern"; then
          is_allowed=true
          break
        fi
      done
      if ! $is_allowed; then
        violations="${violations}NOT_ALLOWED: ${file}\n"
      fi
    done <<< "$changed_files"
  fi

  if [[ -n "$violations" ]]; then
    echo -e "$violations"
    return 1
  fi
  return 0
}
