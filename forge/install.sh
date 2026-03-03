#!/usr/bin/env bash
set -euo pipefail
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
echo "Run: cd your-project && forge init"
