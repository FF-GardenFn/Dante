#!/usr/bin/env bash
set -euo pipefail

# --- Bash version check ---
if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
  echo "Error: Forge requires Bash 4+. Found: ${BASH_VERSION}" >&2
  echo "  macOS ships Bash 3.x. Install with: brew install bash" >&2
  exit 1
fi

# --- Dependency checks ---
for dep in git jq; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    echo "Error: '${dep}' is required but not found." >&2
    exit 1
  fi
done
# Optional: tmux (needed for parallel sessions)
if ! command -v tmux >/dev/null 2>&1; then
  echo "Warning: 'tmux' not found. Parallel sessions (forge session) will not work." >&2
fi

# --- Existing install detection ---
if command -v forge >/dev/null 2>&1; then
  existing=$(command -v forge)
  echo "Note: 'forge' already installed at: ${existing}"
  echo "  This installation will override it if ~/.local/bin is earlier in PATH."
fi

echo "Installing Forge"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/forge"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/lib" "$BIN_DIR"
cp "$SCRIPT_DIR"/bin/* "$INSTALL_DIR/bin/"
cp "$SCRIPT_DIR"/lib/* "$INSTALL_DIR/lib/"
chmod +x "$INSTALL_DIR"/bin/*
ln -sf "$INSTALL_DIR/bin/forge" "$BIN_DIR/forge"
echo "Forge installed to $INSTALL_DIR"
echo "Symlinked: $BIN_DIR/forge"

# --- PATH check ---
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo ""
     echo "Add to your shell profile:"
     echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
     ;;
esac

echo "Run: cd your-project && forge init"
