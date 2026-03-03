---
name: forge-test-design
description: This skill should be used when the user asks to "design tests for forge", "write convergence tests", "create Goodhart-resistant tests", "write tests for a work order", "test design for agent loops", "anti-Goodhart testing", mentions "Goodhart's Law" in context of testing, or discusses designing tests that AI agents must pass without seeing the test source code.
---

# Forge Test Design: Goodhart-Resistant Convergence Tests

## Purpose

Design test suites that serve as convergence targets for Forge loops. The fundamental constraint: the implementing agent never sees test source code. It only sees structured failure output -- test names, assertion errors, and stack traces. Tests must be designed so the only way to make them pass is to correctly implement the intended behavior.

## Goodhart's Law in Agent Testing

Goodhart's Law: "When a measure becomes a target, it ceases to be a good measure."

In Forge, tests ARE the target. An agent that can see test source can pattern-match to assertions rather than solving the problem. Forge prevents this by hiding the source. But even with hidden source, poorly designed tests leak implementation hints through failure output.

## Anti-Goodhart Principles

### 1. Test Behavior, Not Implementation

Test what the code DOES, not how it does it.

**Good:** `test_transfer_reduces_sender_balance` -- tests observable state change
**Bad:** `test_calls_debit_method` -- tests internal dispatch

The agent sees test names in failure output. Behavioral names guide toward correct implementation without prescribing the approach.

### 2. Minimize Information Leakage in Failure Output

Control what assertion messages reveal.

**Good:** `assert result.status == "completed", f"Expected completed, got {result.status}"`
**Bad:** `assert db.query("SELECT status FROM orders WHERE id=1").fetchone()[0] == "completed"`

The second tells the agent the exact database query to use.

### 3. Use Contract-Based Assertions

Test preconditions, postconditions, and invariants:

```python
def test_deposit_increases_balance():
    initial = account.balance
    account.deposit(100)
    assert account.balance == initial + 100

def test_deposit_rejects_negative():
    with pytest.raises(ValueError):
        account.deposit(-50)
```

### 4. Parameterize to Prevent Hardcoding

```python
@pytest.mark.parametrize("amount", [1, 50, 100, 999, 10000])
def test_deposit_accepts_valid_amounts(amount):
    account.deposit(amount)
    assert account.balance >= amount
```

### 5. Test Edge Cases and Error Boundaries

Edge cases force genuine implementation:
- Empty inputs, None, zero-length strings
- Boundary values (0, -1, MAX_INT, empty list)
- Unicode, special characters, very long strings
- Concurrent operations (if applicable)

### 6. Self-Contained and Deterministic

Each test runs independently. No shared mutable state. No dependency on execution order. Same result every run.

### 7. Keep Tests Fast

Forge loops run tests on every iteration (30+ times). Each test under 5 seconds. Mock I/O, databases, network.

## Common Mistakes

1. **Testing internal methods**: Import only public interfaces. Private imports leak structure.
2. **Exact string matching**: Test semantic content, not exact formatting.
3. **Order-dependent tests**: Shared state causes non-deterministic failures that confuse agents.
4. **Vacuous tests**: `assert True` tests nothing. Agent creates an empty stub.

## Additional Resources

For the complete anti-Goodhart pattern catalog, consult `references/goodhart-patterns.md`.
