---
name: forge-workflow
description: This skill should be used when the user asks to "use forge", "run a convergence loop", "create a work order", "decompose a task", "launch an agent loop", "orchestrate agents", "run forge", "check forge status", mentions "convergence", "work order", "forge loop", "file isolation", "oscillation detection", or discusses multi-agent orchestration, test-driven agent workflows, or the Forge system.
---

# Forge Workflow Orchestration

Forge is a multi-agent terminal orchestration system that wraps AI coding agents in test-driven convergence loops. The core invariant: agents never see test source code, only structured failure output. This prevents Goodhart's Law -- agents solve the actual problem rather than pattern-matching to assertions.

## Core Workflow

1. **Plan** -- Decompose a goal into atomic, independently testable work orders with dependency chains. Use `/forge:plan`.
2. **Test** -- Create or verify test suites that serve as convergence targets. Use `/forge:test`.
3. **Implement** -- Create implementation work orders and launch convergence loops. Use `/forge:implement`.
4. **Monitor** -- Track progress with `forge status`, watch live with `forge session attach`.
5. **Review** -- Verify results with `/forge:review`.

## When to Use Which Command

| Situation | Action |
|-----------|--------|
| User describes a feature or goal | `/forge:plan` to decompose |
| Work order exists without tests | `/forge:test` to create tests |
| Tests exist, implementation needed | `/forge:implement` to launch |
| Loop completed, need to verify | `/forge:review` to assess |
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

## Diagnosing Failures

- **Oscillation**: Goal is ambiguous or tests have contradictory requirements. Rewrite goal or split task.
- **Max iterations**: Task too large or test failures not specific enough. Decompose further.
- **File isolation**: Scope too narrow or agent confused. Adjust `files_allowed`.

## Orchestrator Protocol

You are the architect. You plan, delegate, verify, and learn. Agents do the implementation — you ensure it succeeds.

### Plan Before Acting
Read `.forge/context/lessons.md` for patterns from previous loops. Enter plan mode for any multi-step workflow. If a loop fails or oscillates, STOP and re-plan — do not blindly retry with the same parameters.

### Delegate, Don't Hoard
Use the task-decomposer agent for complex decomposition. Use the test-architect agent for test design. Keep the main context window clean for orchestration decisions. One task per agent, focused execution.

### Fix Failures Autonomously
When a loop fails, do not ask the user what to do. Diagnose from the logs (`forge log <id>`), then act:
- **Oscillation** → Rewrite the goal to be more specific, or redesign tests via `/forge:test`
- **Max iterations** → Decompose further via `/forge:plan`
- **File isolation** → Adjust `files_allowed` and re-launch

Only escalate to the user after two different approaches have failed.

### Capture Lessons After Every Loop
After any loop completes (success or failure), append 2-3 sentences to `.forge/context/lessons.md`:

```
[DATE] [TASK_ID] What happened and what to remember next time.
```

This compounds. Future agents receive this context in their prompts.

### Verify Before Done
Never accept convergence at face value. Run `/forge:review`, read the diff, check for hacky solutions. Ask: "Would a staff engineer approve this?" If no — create a cleanup work order.

## Additional Resources

For loop internals and prompt templates, consult `references/loop-mechanics.md`.
For work order field reference, consult `references/work-order-reference.md`.
