# Work Order Field Reference

## YAML Frontmatter Fields

| Field | Required | Format | Example |
|-------|----------|--------|---------|
| id | Yes | Short alphanumeric | `C14`, `T01`, `R03` |
| status | Auto | open, running, done, failed | `open` |
| priority | No | 1-5 (1 = highest) | `2` |
| created | Auto | YYYY-MM-DD HH:MM | `2025-03-15 14:30` |
| agent | No | claude, codex, gemini, unassigned | `claude` |
| goal | Yes | One-line description | `Fix database connection pooling` |
| test_cmd | Yes* | Shell command, no metacharacters | `pytest tests/test_db.py -x` |
| files_allowed | No | Comma-separated regex patterns | `src/database\\.py, src/pool\\.py` |
| files_forbidden | No | Comma-separated regex patterns | `tests/.*, config/.*` |
| constraints | No | Comma-separated text | `No new dependencies, Python 3.11+` |
| depends_on | No | Comma-separated task IDs | `T01, C13` |

*Required for convergence loops. Work orders without test_cmd cannot use `forge loop`.

## ID Naming Conventions

- `T##` -- Test creation tasks
- `C##` -- Code implementation tasks
- `R##` -- Refactoring tasks
- `D##` -- Documentation tasks
- `F##` -- Fix/bugfix tasks

## test_cmd Constraints

`validate_test_cmd()` uses an allowlist: only letters, digits, spaces, `_`, `.`, `/`, `:`, `=`, `@`, and `-` are permitted. All other characters are rejected. Wrap complex commands in a script.

**Valid:**
```
pytest tests/test_feature.py -x --tb=short
python -m pytest tests/test_feature.py -v
bash .forge/tests/run_C14.sh
node --test tests/test_feature.js
go test ./pkg/feature/...
```

**Invalid (wrap in a script):**
```
pytest tests/ | grep -v SKIP
cd src && python -m pytest
TEST_ENV=true pytest tests/
```

## File Scope Patterns

`files_allowed` and `files_forbidden` use regex matched against paths relative to project root.

**Examples:**
```yaml
files_allowed: src/api/.*\\.py, src/models/user\\.py
files_forbidden: tests/.*, migrations/.*, .*\\.lock
```

**Tips:**
- Escape dots in extensions: `\\.py` not `.py`
- Use `.*` for directory wildcards: `src/api/.*` matches all files under src/api/
- Multiple patterns are comma-separated
- Matched with grep -E (extended regex)

## Dependency Resolution

Tasks in `depends_on` must have `.forge/signals/<id>.done` file. Created by:
- `forge done <id>` (manual)
- Successful convergence in `forge loop` (automatic)

If dependencies unmet, `forge loop` refuses to start.
