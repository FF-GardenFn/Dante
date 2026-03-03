#!/usr/bin/env bash
# Test convergence loop with a mock agent
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
FORGE_BIN="$TESTS_DIR/../bin/forge"
TMP=$(mktemp -d)
trap "rm -rf '$TMP'" EXIT

cd "$TMP"
git init -q .
bash "$FORGE_BIN" init 2>&1 >/dev/null

# Create a file the agent needs to fix
echo 'WRONG' > target.txt

# Create a test script that checks for correct content
cat > check_target.sh << 'SCRIPT'
#!/usr/bin/env bash
content=$(cat target.txt)
if [[ "$content" == "CORRECT" ]]; then
  echo "1 passed, 0 failed"
  exit 0
else
  echo "FAILED: expected CORRECT got $content"
  echo "0 passed, 1 failed"
  exit 1
fi
SCRIPT
chmod +x check_target.sh

# Create a mock claude binary that writes the fix
mkdir -p mock_bin
cat > mock_bin/claude << 'MOCK'
#!/usr/bin/env bash
# Mock agent: just write the correct answer
echo "CORRECT" > target.txt
echo "Fixed target.txt"
MOCK
chmod +x mock_bin/claude

# Create work order
bash "$FORGE_BIN" order create L01 \
  --goal "Fix target.txt to contain CORRECT" \
  --test "bash check_target.sh" \
  --agent claude 2>&1 >/dev/null

# Run loop with mock agent on PATH
export PATH="$TMP/mock_bin:$PATH"
output=$(bash "$FORGE_BIN" loop L01 --agent claude --max-iter 3 --no-isolation 2>&1) || true

# Check convergence
echo "$output" | grep -q "Converged\|ALL TESTS PASS" || { echo "FAIL: loop did not converge"; echo "$output"; exit 1; }

# Verify the file was actually fixed
[[ "$(cat target.txt)" == "CORRECT" ]] || { echo "FAIL: target.txt not fixed"; exit 1; }

# Verify work order status updated
grep -q "status: done" ".forge/work_orders/L01.md" || { echo "FAIL: status not done"; exit 1; }

echo "All loop convergence tests passed"
