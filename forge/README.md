# Forge -- Multi-Agent Terminal Orchestration

Test-driven convergence loops for parallel AI coding agents.

Agents never see the tests. They only see structured failure output. This forces them to solve the actual problem rather than pattern-match to specific assertions.

## Install

```bash
cd forge && ./install.sh
export PATH="$HOME/.local/bin:$PATH"
```

## Usage

```bash
# 1. Initialize in your project
cd your-project
forge init

# 2. Create work orders
forge order create C01 \
  --goal "Fix the database connection pooling" \
  --test "pytest tests/test_db.py -x" \
  --files-allowed "src/database.py" \
  --agent claude \
  --priority 1

# 3. Run the convergence loop
forge loop C01 --agent claude --max-iter 10

# 4. Check status
forge status

# 5. Review results
forge review C01
```

## Commands

| Command | Description |
|---------|-------------|
| `forge init` | Initialize `.forge/` in current project |
| `forge order create` | Create a work order with goal, test, file scope |
| `forge order list` | List all work orders |
| `forge loop <id>` | Run test-driven convergence loop |
| `forge session launch` | Launch agent in tmux (detachable) |
| `forge session workspace` | Create tmux layout with status pane |
| `forge status` | Real-time dashboard |
| `forge review <id>` | Post-completion review (diff, tests, logs) |
| `forge done <id>` | Manually signal task completion |
| `forge log <id>` | View task logs |

## How the Loop Works

```
while iteration < max:
    prompt = build_prompt(goal, context, failures)
    agent.execute(prompt)       # Single-shot, blocking
    results = run_tests()       # External, masked from agent

    if tests_pass:    break     # CONVERGED
    if oscillation:   break     # Same diff seen twice
    if out_of_scope:  break     # File isolation violated

    failures = parse(results)   # Feed back into next iteration
```

## Exit Conditions

| Condition | Meaning |
|-----------|---------|
| Tests pass | Converged -- task complete |
| Max iterations | Safety valve hit |
| Oscillation | Agent producing same diff repeatedly |
| File isolation | Agent touched files outside its scope |
| Dependencies unmet | Prerequisite task not done |

## Agents

Forge is agent-agnostic. Currently supports Claude Code, Codex, and Gemini. Add new agents by editing `send_to_agent()` in `lib/common.sh`.

## Configuration

After `forge init`, edit `.forge/config`:

```
max_parallel_agents=3
default_max_iterations=30
default_agent=claude
default_test_framework=pytest
oscillation_window=3
```

Edit `.forge/context/architecture.md` with your project structure -- this gets injected into every agent prompt.

## Requirements

- bash 4+
- git
- tmux (for parallel sessions via `forge session`)
- One or more agent CLIs: `claude`, `codex`, `gemini`

## Cross-Platform

Forge runs on macOS and Linux. All shell helpers (sed, md5, date) are abstracted for portability. Install targets follow XDG conventions.

## Security

- Test commands are validated against shell metacharacters (`;|&$`). Wrap complex commands in a script file.
- Agents run in file-isolated scopes. Touching forbidden files stops the loop.
- Agents never see test source code, only structured failure output.

## Testing

```bash
bash forge/tests/run_all.sh
```
