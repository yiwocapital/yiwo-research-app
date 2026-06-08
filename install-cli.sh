#!/bin/bash
set -e

# YRA CLI - Install script
# Usage:
#   ./scripts/install-cli.sh                        # Install to ~/.local/bin
#   ./scripts/install-cli.sh --dir <path>           # Install to custom path
#   ./scripts/install-cli.sh --from <url>           # Install from custom URL
#   ./scripts/install-cli.sh --from <local-tarball> # Install from local tarball

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPO="yiwocapital/yiwo-research-app"
BINARY="yra"
VERSION="${VERSION:-latest}"

# Default options
INSTALL_DIR="${HOME}/.local/bin"
FROM_URL=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --from)
            FROM_URL="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--dir <path>] [--from <url|tarball>] [--version <tag>]"
            echo ""
            echo "Options:"
            echo "  --dir <path>           Install directory (default: ~/.local/bin)"
            echo "  --from <url|tarball>   Custom download URL or local tarball path"
            echo "  --version <tag>        Specific version tag (default: latest)"
            echo "  -h, --help             Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
    darwin)
        OS="Darwin"
        ;;
    linux)
        OS="Linux"
        ;;
    mingw*|cygwin*|msys*)
        OS="Windows"
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64|amd64)
        ARCH="x86_64"
        ;;
    arm64|aarch64)
        ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Determine download URL
if [ -z "$FROM_URL" ]; then
    if [ "$VERSION" = "latest" ]; then
        FROM_URL="https://github.com/${REPO}/releases/latest/download/yra_${OS}_${ARCH}.tar.gz"
    else
        FROM_URL="https://github.com/${REPO}/releases/download/${VERSION}/yra_${OS}_${ARCH}.tar.gz"
    fi
fi

echo "=== YRA CLI Install ==="
echo "Platform: ${OS}_${ARCH}"
echo "Install to: $INSTALL_DIR"
echo "Download: $FROM_URL"
echo ""

# Create install directory
mkdir -p "$INSTALL_DIR"

# Check if FROM_URL is a local file
if [ -f "$FROM_URL" ]; then
    echo "Using local tarball: $FROM_URL"
    TARBALL="$FROM_URL"
    CLEANUP_TARBALL=0
else
    TARBALL="/tmp/${BINARY}-install.tar.gz"
    CLEANUP_TARBALL=1

    # Download
    echo "Downloading..."
    if ! curl -L -f -o "$TARBALL" "$FROM_URL"; then
        echo "ERROR: Download failed"
        echo "URL: $FROM_URL"
        exit 1
    fi
fi

# Extract
echo "Extracting..."
if ! tar -xzf "$TARBALL" -C "$INSTALL_DIR"; then
    echo "ERROR: Extraction failed"
    [ "$CLEANUP_TARBALL" = "1" ] && rm -f "$TARBALL"
    exit 1
fi

# Make executable (in case archive didn't preserve)
chmod +x "$INSTALL_DIR/$BINARY" 2>/dev/null || true

# Cleanup
[ "$CLEANUP_TARBALL" = "1" ] && rm -f "$TARBALL"

# Verify installation
echo ""
if [ -x "$INSTALL_DIR/$BINARY" ]; then
    VERSION_OUTPUT=$("$INSTALL_DIR/$BINARY" version 2>&1 || echo "version command failed")
    echo "✓ Installed: $INSTALL_DIR/$BINARY"
    echo "  $VERSION_OUTPUT"
else
    echo "✗ Installation failed: $BINARY not found or not executable"
    exit 1
fi

# Check PATH
echo ""
if echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo "✓ $INSTALL_DIR is in PATH"
else
    echo "⚠ $INSTALL_DIR is NOT in your current PATH"
    echo ""
    echo "Why this matters: yra is installed to $INSTALL_DIR but your shell"
    echo "won't find it until this directory is in your PATH."
    echo ""

    # Detect current platform and give tailored instructions
    CURRENT_OS=$(uname -s)
    SHELL_NAME="${SHELL##*/}"  # basename of $SHELL

    # Pick the right rc file for the user's shell
    case "$SHELL_NAME" in
        zsh)
            RC_FILE="~/.zshrc"
            RC_FILE_MAC="~/.zshrc"
            ;;
        bash)
            RC_FILE="~/.bashrc"
            RC_FILE_MAC="~/.bash_profile"
            ;;
        fish)
            RC_FILE="~/.config/fish/config.fish"
            ;;
        *)
            RC_FILE="~/.profile"
            RC_FILE_MAC="~/.zshrc"
            ;;
    esac

    if [ "$CURRENT_OS" = "Darwin" ]; then
        # macOS specific: ~/.local/bin is NOT in default PATH at all
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  macOS 用户特别注意"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  macOS 默认 PATH 不包含 $INSTALL_DIR。"
        echo "  请将以下内容添加到 $RC_FILE_MAC："
        echo ""
        echo "      export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
        echo "  然后让配置生效（无需重启终端）："
        echo ""
        echo "      source $RC_FILE_MAC"
        echo ""
        echo "  验证："
        echo ""
        echo "      which yra"
        echo ""
        echo "  ────────────────────────────────────────────────"
        echo ""
        echo "  备选方案（如果你不想修改 PATH）："
        echo ""
        echo "    1. 使用绝对路径调用："
        echo "         $INSTALL_DIR/yra version"
        echo ""
        echo "    2. 创建一个符号链接到已有的 PATH 目录（如 ~/bin 或 /usr/local/bin）："
        echo "         ln -sf $INSTALL_DIR/yra /usr/local/bin/yra"
        echo "         （需要 sudo 写入 /usr/local/bin）"
        echo ""
    else
        # Linux / other
        echo "请将以下内容添加到 $RC_FILE："
        echo ""
        echo "    export PATH=\"$INSTALL_DIR:\$PATH\""
        echo ""
        echo "然后让配置生效（无需重启终端）："
        echo ""
        echo "    source $RC_FILE"
        echo ""
    fi
fi

echo ""
echo "Next steps:"
echo "  1. $BINARY auth login"
echo ""

exit 0
