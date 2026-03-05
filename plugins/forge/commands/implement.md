---
description: Create an implementation work order and prepare a handoff report for the user to launch convergence loops
argument-hint: <work-order-id>
allowed-tools: [Read, Bash, Glob, Grep, Write]
---

# Forge Implement: Create Work Order and Prepare Handoff

Target: $ARGUMENTS

## Step 1: Determine Context

Parse the arguments. If a work order ID is provided, read it with `forge order show <id>`.

If no work order exists yet, gather information to create one.

## Step 2: Validate Work Order Readiness

An implementation work order MUST have:

1. **goal**: Clear, one-line implementation objective
2. **test_cmd**: Valid test command (no shell metacharacters). Verify with `forge order show`.
3. **files_allowed**: Regex patterns for files the agent should modify
4. **files_forbidden**: Protection for test files, config, shared infrastructure

If any are missing, fill them in. Do NOT launch without a test_cmd.

## Step 3: Pre-flight Checks

```bash
# Tests should currently FAIL (nothing to implement otherwise)
<test_cmd>

# Check dependencies are met
forge order show <id>

# Check no active session already running
forge status
```

## Step 4: Review What the Agent Will See

The Forge loop sends this prompt to the agent on iteration 1:

```
# TASK
<goal from work order>

# PROJECT CONTEXT
<.forge/context/architecture.md>

# RULES
<.forge/context/rules.md>

# FILE SCOPE
You may ONLY modify: <files_allowed>
You must NOT modify: <files_forbidden>

# CONSTRAINTS
<constraints>

# INSTRUCTIONS
Implement the task above. Make minimal, focused changes.
Do not add unnecessary files or dependencies.
When done, stop. Do not explain -- just make the changes.
```

On subsequent iterations (tests fail), the agent sees:

```
# ITERATION N -- TESTS STILL FAILING

## Original Task
<goal>

## Test Results
<failed> of <total> tests failing.

## Failure Details
<parsed failure lines from test output>

## Instructions
Fix the remaining failures. Make minimal changes.
Focus on the specific errors shown above.
Do not revert previous fixes that were working.
```

Ensure the goal and constraints are clear enough for these templates. If ambiguous, rewrite.

## Step 5: Create or Update Work Order

```bash
forge order create <ID> \
  --goal "<goal>" \
  --test "<test_cmd>" \
  --files-allowed "<patterns>" \
  --files-forbidden "<patterns>" \
  --constraints "<constraints>" \
  --depends-on "<deps>" \
  --agent claude \
  --priority <priority>
```

## Step 6: Present Handoff Report

**CRITICAL: Do NOT run `forge loop`, `forge session launch`, or any long-running forge commands via Bash. These spawn subprocesses that require a user terminal. Present them to the user instead.**

After creating or validating the work order, present a consolidated handoff report. If multiple work orders were prepared (e.g., from a prior `/forge:plan`), include all of them in a single report.

```
═══════════════════════════════════════════════════
  FORGE HANDOFF — Ready to Launch
═══════════════════════════════════════════════════

  PREPARED:
    Work Orders: <list all IDs and their one-line goals>
    Test Suites: <list all test file paths>
    Dependencies: <show which orders depend on which>

  LAUNCH COMMANDS (paste in your terminal):

    # --- Wave N (label: parallel / after Wave N-1) ---
    forge session launch <ID> --agent claude --max-iter <N> --detach

  MONITOR (you can run these anytime):
    forge status                 # overview dashboard
    forge session list           # all active sessions
    forge session attach <ID>    # watch a specific session live
    forge log <ID>               # read completed session logs

  AFTER COMPLETION:
    Ask me to run /forge:review <ID> for each completed task.

═══════════════════════════════════════════════════
```

Group work orders into waves based on `depends_on`:
- **Wave 1**: Orders with no dependencies (can all run in parallel)
- **Wave 2**: Orders whose dependencies are all in Wave 1
- Continue until all orders are assigned

Set `--max-iter` based on task complexity:
- Simple (1-2 files, clear goal): **15**
- Medium (3-5 files, some ambiguity): **30**
- Complex (5+ files or tricky logic): **50**

## Step 7: Post-Launch Support

After the user launches loops, you can help monitor and diagnose.

### What You CAN Do (via Bash)
- `forge status` — check dashboard
- `forge log <id>` — read session logs after completion
- `forge order show <id>` — inspect work order state
- `git status`, `git diff --stat` — check working directory

### What You Must NOT Do (terminal only)
- `forge loop`, `forge session launch`, `forge session attach`

### Diagnosing Failures

Four possible outcomes from a convergence loop:

1. **Converged** — all tests pass. Suggest `/forge:review <id>`.
2. **Max iterations** — task too large or failures too vague.
3. **Oscillation** — agent flip-flopping between approaches.
4. **File isolation violated** — agent touched forbidden files.

When the user reports a failure or you detect one via `forge status` / `forge log`:

1. Read the session log: `forge log <id>`
2. Check working directory: `git status`, `git diff --stat`
3. Diagnose the root cause
4. If files outside scope were touched, run `git checkout -- .` to clean up
5. Apply the fix: rewrite goal, adjust scope, decompose via `/forge:plan`, or redesign tests via `/forge:test`
6. **Present updated launch commands in a new Handoff Report**

### Capture Lessons

After any outcome, append 2-3 sentences to `.forge/context/lessons.md`:
```
[YYYY-MM-DD] [TASK_ID] What happened and what to remember next time.
```
