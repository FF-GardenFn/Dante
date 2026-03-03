# Dante

Multi-agent terminal orchestration with test-driven convergence loops.

**Forge** is the CLI engine at the core of Dante. Agents never see the tests — only structured failure output. The only way to pass is to solve the actual problem.

## How It Works

```
Goal → Agent implements → External tests run → Parse failures → Feed back → Repeat
```

The agent receives a goal and file scope constraints. Tests execute externally after each iteration. The agent sees only test names, assertion errors, and stack traces — never the test source. This prevents [Goodhart's Law](https://en.wikipedia.org/wiki/Goodhart%27s_law): agents solve the problem rather than pattern-matching to assertions.

## Quick Start

```bash
# Install
cd forge && ./install.sh
export PATH="$HOME/.local/bin:$PATH"

# Initialize in your project
forge init

# Create a work order
forge order create C01 \
  --goal "Implement connection pooling" \
  --test "pytest tests/test_pool.py -x" \
  --files-allowed "src/pool\\.py" \
  --agent claude

# Run the convergence loop
forge loop C01 --agent claude --max-iter 20
```

## Exit Conditions

| Condition | Meaning |
|-----------|---------|
| **Converged** | All tests pass |
| **Oscillation** | Agent producing same diff repeatedly (MD5 match) |
| **File isolation** | Agent modified files outside allowed scope |
| **Max iterations** | Safety cap reached |

## Parallel Execution

```bash
forge session launch C01 --agent claude --detach
forge session launch C02 --agent codex --detach
forge session workspace   # tmux monitoring layout
forge status              # dashboard
```

## Claude Code Plugin

Install the Forge plugin from the Dante marketplace:

```bash
/plugin marketplace add FF-GardenFn/Dante
/plugin install forge@dante
```

Or use it directly — the `.claude/forge/` directory provides slash commands:

| Command | Purpose |
|---------|---------|
| `/forge:plan` | Decompose a goal into work orders with dependency chains |
| `/forge:test` | Design Goodhart-resistant convergence-target tests |
| `/forge:implement` | Validate readiness and launch a convergence loop |
| `/forge:review` | Post-completion analysis of results |

## Project Structure

```
forge/              CLI orchestration system (bash)
  bin/              forge, forge-loop, forge-order, forge-session, forge-review, forge-status
  lib/              common.sh — portable helpers, test parsing, isolation checks
  tests/            Self-test harness (6 tests)
.claude/forge/      Claude Code plugin (commands, agents, skills)
.forge/             Runtime state (initialized per project via forge init)
```

## Requirements

- Bash 4+, Git, jq
- tmux (for parallel sessions)
- One or more agent CLIs: `claude`, `codex`, or `gemini`

## License

MIT — see [LICENSE](LICENSE).

## Author

[Faycal Farhat](https://github.com/FF-GardenFn)
