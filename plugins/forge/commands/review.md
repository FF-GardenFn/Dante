---
description: Review completed Forge task results (diff, tests, isolation, logs)
argument-hint: <work-order-id>
allowed-tools: [Read, Bash, Glob, Grep]
---

# Forge Review: Post-Completion Task Review

Review task: $ARGUMENTS

## Step 1: Gather Task State

Parse the work order ID from $ARGUMENTS. Then run:

```bash
forge review <id>
```

This runs the built-in review showing: work order, git diff summary, file isolation status, test results, session log tail. Read the output carefully.

## Step 2: Deep Dive

### Code Quality
Read each changed file. Assess:
- Does the implementation match the goal?
- Are there unnecessary changes beyond scope?
- Signs of loop thrashing (commented-out code, debug prints, redundant conditionals)?

### Test Verification
Extract the test_cmd from the work order and run it independently to confirm tests still pass.

### Convergence Quality
Read the session log:
```bash
forge log <id>
```

Analyze:
- Total iterations to convergence
- Whether the agent oscillated before converging
- File isolation warnings
- Failure trajectory: did failures decrease monotonically or bounce?

### Diff Review
```bash
git diff --stat
git diff
```

Check for:
- Files modified outside declared scope
- Unnecessary file additions
- Changes to unrelated code

## Step 3: Verdict

Provide a structured assessment:

### Task Review: <ID>

**Status:** converged | failed | needs-rework
**Iterations:** N
**Files Changed:** list

**Assessment:**
- Goal met: yes/no + explanation
- Code quality: acceptable / needs-cleanup
- Test coverage: adequate / gaps-found
- Scope compliance: clean / violations-found

**Recommended Actions:**
- [ ] Accept changes (commit)
- [ ] Request cleanup (create follow-up work order)
- [ ] Reject and retry with adjusted parameters

If recommending retry, suggest specific adjustments: rewrite goal, adjust file scope, redesign tests, or increase max iterations.

## Step 4: Capture Lessons

After every review — success or failure — append 2-3 sentences to `.forge/context/lessons.md`:

```
[DATE] [TASK_ID] What happened, what worked or failed, what to do differently next time.
```

Be specific. Bad: "Task was hard." Good: "T03 oscillated because tests checked internal method names; switching to behavioral assertions resolved it in 4 iterations."

This compounds — future agents and planning sessions receive this context.

## Step 5: Demand Elegance

Ask: "Would a staff engineer approve this?" If the code is hacky, over-engineered, or has leftover debug artifacts, do NOT accept it. Create a cleanup work order (`R##`) targeting the specific issues.
