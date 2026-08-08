#!/usr/bin/env bash
# UltSQL Linux & macOS 1-Line Installer
# Automatically downloads ultsql binary, sets executable permissions, and adds to PATH

set -e

echo "🚀 Installing UltSQL CLI..."

# Detect OS
OS="$(uname -s)"
INSTALL_DIR="$HOME/.ultsql/bin"
mkdir -p "$INSTALL_DIR"

if [ "$OS" = "Linux" ]; then
    BINARY_URL="https://github.com/ompatel3158/ULTSQL/releases/latest/download/ultsql-ubuntu-latest"
elif [ "$OS" = "Darwin" ]; then
    BINARY_URL="https://github.com/ompatel3158/ULTSQL/releases/latest/download/ultsql-macos-latest"
else
    echo "Unsupported OS: $OS"
    exit 1
fi

TARGET="$INSTALL_DIR/ultsql"

echo "⬇️ Downloading UltSQL binary..."
curl -fsSL "$BINARY_URL" -o "$TARGET" || curl -fsSL "https://raw.githubusercontent.com/ompatel3158/ULTSQL/main/bin/ultsql.exe" -o "$TARGET"

chmod +x "$TARGET"

# Configure PATH in bashrc / zshrc
SHELL_RC=""
if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
    if ! grep -q "$INSTALL_DIR" "$SHELL_RC"; then
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_RC"
        echo "✅ Added $INSTALL_DIR to $SHELL_RC"
    fi
fi

export PATH="$INSTALL_DIR:$PATH"

echo ""
echo "🎉 UltSQL CLI installed successfully!"
echo "Type 'ultsql serve' or 'ultsql --help' in any terminal window to begin."
