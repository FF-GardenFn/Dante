---
description: Create an implementation work order and optionally launch the convergence loop
argument-hint: <work-order-id> [--launch]
allowed-tools: [Read, Bash, Glob, Grep, Write]
---

# Forge Implement: Create Work Order and Launch Loop

Target: $ARGUMENTS

## Step 1: Determine Context

Parse the arguments. If a work order ID is provided, read it with `forge order show <id>`. If `--launch` is present, immediately start the convergence loop after validation.

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

## Step 6: Launch (if requested)

For foreground execution:
```bash
forge loop <ID> --agent claude --max-iter 20
```

For background tmux:
```bash
forge session launch <ID> --agent claude --max-iter 20 --detach
```

Report monitoring options:
- `forge status` -- dashboard
- `forge session attach <ID>` -- watch live
- `forge log <ID>` -- logs after completion

## Step 7: Exit Conditions and Autonomous Recovery

Four possible outcomes:

1. **Converged** -- all tests pass. Run `/forge:review <id>` to verify quality.
2. **Max iterations** -- task too large or test failures too vague. Decompose further via `/forge:plan`.
3. **Oscillation** -- agent producing same diff repeatedly. Rewrite goal to be more specific, or redesign tests via `/forge:test`.
4. **File isolation violated** -- agent touched forbidden files. Adjust `files_allowed` and re-launch.

**On failure, do NOT ask the user what to do.** Diagnose from the logs (`forge log <id>`), then act:

- Read the session log to identify the failure pattern
- Apply the appropriate fix from above
- Re-launch the loop with adjusted parameters

Only escalate to the user after **two different approaches** have failed.

After any outcome (success or failure), append 2-3 sentences to `.forge/context/lessons.md`:
```
[DATE] [TASK_ID] What happened and what to remember next time.
```
