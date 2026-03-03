# Forge Loop Mechanics Reference

## Prompt Construction

### Initial Prompt (Iteration 1)

Built from these sources, concatenated in order:

1. **TASK section**: The `goal` field from the work order
2. **PROJECT CONTEXT**: Contents of `.forge/context/architecture.md` (if exists)
3. **RULES**: Contents of `.forge/context/rules.md` (if exists)
4. **FILE SCOPE**: `files_allowed` and `files_forbidden` from work order
5. **CONSTRAINTS**: `constraints` field from work order
6. **INSTRUCTIONS**: Fixed text -- minimal focused changes, no unnecessary files, stop when done

### Retry Prompt (Iteration 2+)

1. **Header**: "ITERATION N -- TESTS STILL FAILING"
2. **Original Task**: Goal repeated for context
3. **Test Results**: Pass/fail counts
4. **Failure Details**: Parsed failure lines (max 10) from test output
5. **Instructions**: Fix remaining failures, minimal changes, preserve working fixes

Failure details come from `parse_test_failures()` which extracts lines matching:
- pytest: FAILED, ERROR, AssertionError, Exception
- jest: FAIL, cross mark, bullet
- go: FAIL, dashes
- generic: fail, error, assert, exception, panic (case-insensitive)

## Agent Dispatch

`send_to_agent()` dispatches to the configured CLI:
- **claude**: `claude -p "$prompt" --output-format text --allowedTools Edit,Write,Read,Bash,Glob,Grep`
- **codex**: `codex "$prompt"`
- **gemini**: `gemini "$prompt"`

All agents run in the project root. Output captured and logged.

## Oscillation Detection

After each iteration, Forge computes MD5 of `git diff` plus untracked file contents. Hash compared against all previous hashes in `.forge/hashes/<id>.hashes`. Match found = loop breaks with "oscillation".

**Common causes:**
- Ambiguous goal causing agent to flip between approaches
- Contradictory test requirements
- File scope too restrictive
- Agent undoing its own fixes in response to different failure messages

## File Isolation

After each agent execution, changed files (from `git diff --name-only` + `git ls-files -o --exclude-standard`) are compared against `files_allowed` and `files_forbidden` regex patterns.

Violations cause immediate loop termination.

## Test Result Parsing

`count_test_results()` extracts pass/fail counts:
- pytest: "N passed" and "N failed" patterns
- jest: "Tests: N passed" and "N failed"
- Generic: Counts lines matching pass/ok vs fail/error

## State Management

Active sessions write state to `.forge/sessions/active/<id>.state` (task_id, agent, iteration, test results). Powers `forge status`.

Completed tasks create `.forge/signals/<id>.done` which unblocks dependent tasks.

Failed loops append to `.forge/context/lessons.md`.
