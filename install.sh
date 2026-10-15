#!/usr/bin/env bash
# UltSQL Linux & macOS 1-Line Installer
# Automatically detects OS and Architecture, downloads standalone binary, sets executable permissions, and adds to PATH

set -e

echo "🚀 Installing UltSQL CLI..."

OS="$(uname -s)"
ARCH="$(uname -m)"
INSTALL_DIR="$HOME/.ultsql/bin"
mkdir -p "$INSTALL_DIR"

if [ "$OS" = "Linux" ]; then
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        BINARY_NAME="ultsql-linux-arm64"
    else
        BINARY_NAME="ultsql-linux-x64"
    fi
elif [ "$OS" = "Darwin" ]; then
    if [ "$ARCH" = "arm64" ]; then
        BINARY_NAME="ultsql-macos-arm64"
    else
        BINARY_NAME="ultsql-macos-x64"
    fi
else
    echo "❌ Unsupported OS: $OS"
    exit 1
fi

BINARY_URL="https://github.com/ompatel3158/ULTSQL/releases/latest/download/${BINARY_NAME}"
TARGET="$INSTALL_DIR/ultsql"

echo "⬇️ Downloading UltSQL binary (${BINARY_NAME}) from GitHub Releases..."
if ! curl -fsSL "$BINARY_URL" -o "$TARGET"; then
    echo "⚠️ Failed downloading ${BINARY_NAME}. Trying fallback..."
    if [ "$OS" = "Linux" ]; then
        FALLBACK_URL="https://github.com/ompatel3158/ULTSQL/releases/latest/download/ultsql-ubuntu-latest"
    else
        FALLBACK_URL="https://github.com/ompatel3158/ULTSQL/releases/latest/download/ultsql-macos-latest"
    fi
    if ! curl -fsSL "$FALLBACK_URL" -o "$TARGET"; then
        echo "❌ Failed to download UltSQL binary for $OS ($ARCH)."
        echo "Please visit https://github.com/ompatel3158/ULTSQL/releases/latest or compile with 'dart compile exe bin/ultsql_cli.dart'."
        exit 1
    fi
fi

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
