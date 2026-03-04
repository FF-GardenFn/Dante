---
description: Create a Goodhart-resistant test suite for a Forge work order
argument-hint: <work-order-id-or-goal>
allowed-tools: [Read, Write, Bash, Glob, Grep]
---

# Forge Test: Design Convergence-Target Test Suite

Create tests for: $ARGUMENTS

## Context

These tests will be the convergence target in a Forge loop. The implementing agent NEVER sees test source code. It only sees structured failure output (assertion errors, stack traces, test names). This prevents Goodhart's Law -- the agent solves the actual problem, not pattern-matches to assertions.

## Step 1: Understand the Target

If a work order ID was provided, read it:
```bash
forge order show <id>
```

Otherwise, analyze the goal to understand what needs testing. Read relevant source files for current codebase state.

## Step 2: Design Tests with Anti-Goodhart Principles

### Test behavior/contract (DO):
- Input-output contracts: given X, expect Y
- State transitions: after operation, system is in state S
- Error boundaries: invalid input produces specific error type
- Edge cases: empty, boundary, unicode, large input
- Integration points: component A correctly calls component B

### Avoid implementation details (DO NOT):
- Internal variable names or data structures
- Number of function calls or specific call order (unless it IS the contract)
- Specific algorithm choice (test the result, not the method)
- Log messages or debug output

### Anti-Goodhart patterns:
- **Property-based over exact-value.** Test `result > 0` or `len(result) == expected_len` over `result == 42` when exact value is not the contract.
- **Behavioral test names.** Name tests `test_rejects_negative_amounts` not `test_validate_input_line_47`. Agent sees test names in failure output.
- **Multiple independent assertions.** Do not test everything in one test. Fixing one should not break others.
- **Parameterized inputs.** Prevents hardcoding.
- **Public API only.** Import only the public interface. Internal restructuring must not break tests.

## Step 3: Write the Tests

Follow project conventions:
- Check existing tests for framework and style: `ls tests/`
- Match the test framework (default: pytest per `.forge/config`)
- Place tests where `test_cmd` will find them

Each test must be:
- **Self-contained**: No dependency on other tests or execution order
- **Deterministic**: Same result every run
- **Fast**: Under 5 seconds. Loops run tests 30+ times.
- **Descriptive on failure**: Assert messages should describe what went wrong

## Step 4: Write Test Runner (if needed)

If the test requires complex invocation (fixtures, env vars, multiple files):

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
pytest tests/test_<feature>.py -x --tb=short -q
```

Save to `.forge/tests/run_<id>.sh`, make executable.

## Step 5: Verify Pre-flight Failure

Run the tests to confirm they fail (implementation does not exist yet):
```bash
<test_cmd>
```

If tests pass, the implementation already exists or tests are vacuous. Investigate.

## Step 6: Update the Work Order

If the work order exists but lacks a `test_cmd`, update it:

```bash
# Edit the work order to add the test_cmd
forge order edit <id>
# Set test_cmd to the correct command, e.g.: bash .forge/tests/run_<id>.sh
```

Report what was created: test file paths, the `test_cmd` value, and pre-flight failure confirmation.
