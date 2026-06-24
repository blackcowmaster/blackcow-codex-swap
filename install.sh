#!/usr/bin/env bash
set -e

echo ""
echo "======================================"
echo "  blackcow-codex-swap installer"
echo "======================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/mac/codex-swap.sh"

if [ ! -f "$SRC" ]; then
    echo "[ERROR] mac/codex-swap.sh not found."
    echo "Make sure you run this from the blackcow-codex-swap folder."
    exit 1
fi

SOURCE_LINE="source \"$SRC\""

# Pick shell config file
if [ -n "$ZSH_VERSION" ] || [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
    RC="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ] || [ "$SHELL" = "/bin/bash" ] || [ "$SHELL" = "/usr/bin/bash" ]; then
    RC="$HOME/.bashrc"
else
    RC="$HOME/.zshrc"
fi

if grep -q "codex-swap.sh" "$RC" 2>/dev/null; then
    echo "Already installed in $RC"
else
    echo "" >> "$RC"
    echo "# blackcow-codex-swap" >> "$RC"
    echo "$SOURCE_LINE" >> "$RC"
    echo "Added to $RC"
fi

echo ""
echo "======================================"
echo "  Done!"
echo ""
echo "  Open a new terminal and run:"
echo ""
echo "    codex-pick"
echo ""
echo "  Or if this is your first setup:"
echo "    codex-add"
echo "======================================"
echo ""
