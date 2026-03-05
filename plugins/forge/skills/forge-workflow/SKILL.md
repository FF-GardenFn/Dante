---
name: forge-workflow
description: This skill should be used when the user asks to "use forge", "run a convergence loop", "create a work order", "decompose a task", "launch an agent loop", "orchestrate agents", "run forge", "check forge status", mentions "convergence", "work order", "forge loop", "file isolation", "oscillation detection", or discusses multi-agent orchestration, test-driven agent workflows, or the Forge system.
---

# Forge Workflow Orchestration

Forge is a multi-agent terminal orchestration system that wraps AI coding agents in test-driven convergence loops. The core invariant: agents never see test source code, only structured failure output. This prevents Goodhart's Law -- agents solve the actual problem rather than pattern-matching to assertions.

## Core Workflow

1. **Plan** -- Decompose a goal into atomic, independently testable work orders with dependency chains. Use `/forge:plan`.
2. **Test** -- Create or verify test suites that serve as convergence targets. Use `/forge:test`.
3. **Implement** -- Create implementation work orders and prepare handoff reports for the user to launch. Use `/forge:implement`.
4. **Monitor** -- Track progress with `forge status`. The user watches live via `forge session attach <id>` in their terminal.
5. **Review** -- Verify results with `/forge:review`.

## When to Use Which Command

| Situation | Action |
|-----------|--------|
| User describes a feature or goal | `/forge:plan` to decompose |
| Work order exists without tests | `/forge:test` to create tests |
| Tests exist, implementation needed | `/forge:implement` to prepare handoff |
| Loop completed, need to verify | `/forge:review` to assess |
| User launched loops, need to check | `forge status` or `forge log <id>` directly |
| Check running agents | `forge status` directly |

## Work Order Anatomy

Work orders live at `.forge/work_orders/<id>.md` with YAML frontmatter: `id`, `status`, `priority`, `created`, `agent`, `goal`, `test_cmd`, `files_allowed`, `files_forbidden`, `constraints`, `depends_on`.

**Critical constraints:**
- `test_cmd` must not contain shell metacharacters (`;|&$`). Wrap complex invocations in `.forge/tests/run_<id>.sh`.
- `files_allowed` and `files_forbidden` are comma-separated regex patterns checked by file isolation guard.
- `depends_on` lists task IDs that must complete before this task can launch.

## Convergence Loop Mechanics

The loop runs: prompt agent, run tests externally, parse failures, feed back. Four exit conditions:

1. **Converged** -- All tests pass. Task marked done, signal file created.
2. **Max iterations** -- Safety valve. Default 30, configurable via `--max-iter`.
3. **Oscillation** -- MD5 of git diff matches a previously seen hash. Agent going in circles.
4. **File isolation violation** -- Agent modified files outside allowed scope.

## Parallel Execution

Use `forge session launch <id> --detach` for tmux-based parallel loops. WIP limit (default 3) prevents overload. Use `forge session workspace` for a monitoring layout.

## Command Execution Boundary

You operate inside Claude Code, which cannot run long-lived subprocesses. This creates a strict boundary:

**You MAY run via Bash** (fast, metadata-only):
- `forge init`, `forge order create/edit/show/list`
- `forge status`, `forge log <id>`, `forge review <id>`, `forge done <id>`
- `git status`, `git diff`, `git diff --stat`, `git checkout -- .`
- Test commands for pre-flight verification (if expected to complete in under 60 seconds)

**You must PRESENT to the user** (long-running, require a terminal):
- `forge loop <id> ...`
- `forge session launch <id> ...`
- `forge session attach <id>`
- `forge session workspace`

Always present these in a consolidated **Handoff Report** (see `/forge:implement` for the format). Never attempt to run them via the Bash tool — they will fail due to nested session restrictions and timeouts.

## Diagnosing Failures

- **Oscillation**: Goal is ambiguous or tests have contradictory requirements. Rewrite goal or split task.
- **Max iterations**: Task too large or test failures not specific enough. Decompose further.
- **File isolation**: Scope too narrow or agent confused. Adjust `files_allowed`.

## Orchestrator Protocol

You are the architect. You plan, prepare, verify, and learn. Agents do the implementation in terminal sessions that the user launches. Your role is to set up everything for success, hand off cleanly, and help diagnose when things go wrong.

### Plan Before Acting
Read `.forge/context/lessons.md` for patterns from previous loops. Enter plan mode for any multi-step workflow. If a loop fails or oscillates, STOP and re-plan — do not blindly retry with the same parameters.

### Delegate, Don't Hoard
Use the task-decomposer agent for complex decomposition. Use the test-architect agent for test design. Keep the main context window clean for orchestration decisions. One task per agent, focused execution. You prepare the work; the user launches the execution in their terminal.

### Diagnose Failures, Present Fixes
When a loop fails, diagnose the root cause:

1. Run `forge log <id>` to read the session log
2. Run `forge status` to check overall state
3. Run `git diff --stat` to see what changed
4. Identify the failure pattern (oscillation, max-iter, file isolation)
5. Determine the fix:
   - **Oscillation** → Rewrite the goal or redesign tests via `/forge:test`
   - **Max iterations** → Decompose further via `/forge:plan`
   - **File isolation** → Adjust `files_allowed`, run `git checkout -- .` to clean up

Then **present the corrective action and updated launch commands** in a new Handoff Report. The user executes the retry in their terminal.

### Capture Lessons After Every Loop
After any loop completes (success or failure), append 2-3 sentences to `.forge/context/lessons.md`:

```
[YYYY-MM-DD] [TASK_ID] What happened and what to remember next time.
```

This compounds. Future agents receive this context in their prompts.

### Verify Before Done
Never accept convergence at face value. Run `/forge:review`, read the diff, check for hacky solutions. Ask: "Would a staff engineer approve this?" If no — create a cleanup work order.

## Additional Resources

For loop internals and prompt templates, consult `references/loop-mechanics.md`.
For work order field reference, consult `references/work-order-reference.md`.
