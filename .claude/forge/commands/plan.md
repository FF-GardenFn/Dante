---
description: Decompose a goal into Forge work orders with dependency chains
argument-hint: <goal-description>
allowed-tools: [Read, Bash, Glob, Grep, Write]
---

# Forge Plan: Decompose Goal into Work Orders

The user wants to break down a goal into Forge work orders. Their goal: $ARGUMENTS

## Step 1: Learn From History

Before any analysis, read `.forge/context/lessons.md` for patterns from previous loops. If a similar task was attempted before, learn from what worked or failed. Do NOT repeat a strategy that already caused oscillation or max-iteration failures.

## Step 2: Analyze the Goal

Read the project structure to understand what exists:

- Use Glob to find relevant source files
- Read `.forge/context/architecture.md` for project context
- Read `.forge/context/rules.md` for constraints
- Run `forge order list` to see existing work orders and avoid ID conflicts

Identify the atomic units of work. Each unit must be independently testable and have a clear file scope.

## Step 3: Design the Decomposition

Break the goal into work orders following these principles:

1. **Test-first ordering.** For each implementation task, determine whether tests exist. If not, create a test-writing work order that PRECEDES the implementation work order via `depends_on`.
2. **Narrow file scopes.** Each work order should touch as few files as possible. Use `files_allowed` regex patterns. Use `files_forbidden` to protect shared infrastructure.
3. **Dependency chains.** If task B requires task A's output, set `depends_on: A`. Forge checks this before launching loops.
4. **One goal per order.** Each work order has exactly one `goal` line. If you need a conjunction ("X and Y"), split it.
5. **Testable contracts.** Every implementation work order MUST have a `test_cmd`. If the test does not exist yet, the test-creation order must come first.

## Step 4: Generate Work Order Commands

For each work order, produce a `forge order create` command:

```
forge order create <ID> \
  --goal "<one-line goal>" \
  --test "<test command -- no pipes or semicolons>" \
  --files-allowed "<regex pattern>" \
  --files-forbidden "<regex pattern>" \
  --constraints "<constraint1>, <constraint2>" \
  --depends-on "<prerequisite IDs>" \
  --agent claude \
  --priority <1-5>
```

ID naming: `T##` for test tasks, `C##` for code tasks, `R##` for refactors, `F##` for fixes.

**Critical rules for test_cmd:**
- NO pipes (`|`), semicolons (`;`), backticks, `$()`, or `&`
- If complex invocation needed, write a wrapper script at `.forge/tests/run_<id>.sh` first
- Valid: `pytest tests/test_foo.py -x`
- Invalid: `pytest tests/ | grep FAIL`

## Step 5: Present the Plan

Show the user:

1. A dependency graph (text-based, showing which tasks block which)
2. The ordered list of `forge order create` commands ready to execute
3. Which loops can run in parallel (no shared deps or files)
4. Recommended `--max-iter` values based on task complexity

Ask the user to confirm before executing any commands.

## Step 6: Execute (Only After Confirmation)

Run each `forge order create` command. Verify with `forge order list` that all orders were created correctly and the dependency chain is coherent.
