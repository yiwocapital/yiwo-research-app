#!/bin/bash
# YIWO Research App - Unified installer
#
# Installs the yra CLI binary and Claude Code skills to the local machine.
# All operations are self-contained: files are COPIED (not symlinked) so
# the install survives removal of the source repo.
#
# Usage:
#   ./install.sh                                      # Default: yra + skills
#   ./install.sh --cli-only                           # Install yra only
#   ./install.sh --skills-only                        # Install skills only
#   ./install.sh --bin-dir <path>                     # Custom binary dir (default ~/.local/bin)
#   ./install.sh --skills-dir <path>                  # Custom skills parent (default ~)
#   ./install.sh --version v0.1.0                     # Specific yra version (default latest)

set -e

REPO="yiwocapital/yiwo-research-app"
BINARY="yra"
BIN_DIR="$HOME/.local/bin"
SKILLS_PARENT="$HOME"
VERSION="latest"
INSTALL_CLI=1
INSTALL_SKILLS=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        --bin-dir)
            BIN_DIR="$2"
            shift 2
            ;;
        --skills-dir)
            SKILLS_PARENT="$2"
            shift 2
            ;;
        --cli-only|--no-skills)
            INSTALL_SKILLS=0
            shift
            ;;
        --skills-only|--no-cli)
            INSTALL_CLI=0
            shift
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        -h|--help)
            sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
SKILLS_TARGET="$SKILLS_PARENT/.claude/skills"

# ----- Detect platform -----

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
    darwin) OS="Darwin" ;;
    linux)  OS="Linux" ;;
    mingw*|cygwin*|msys*) OS="Windows" ;;
    *) echo "Unsupported OS: $OS" >&2; exit 1 ;;
esac

case "$ARCH" in
    x86_64|amd64) ARCH="x86_64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

# ----- Install yra CLI -----

install_cli() {
    if [ "$VERSION" = "latest" ]; then
        FROM_URL="https://github.com/${REPO}/releases/latest/download/${BINARY}_${OS}_${ARCH}.tar.gz"
    else
        FROM_URL="https://github.com/${REPO}/releases/download/${VERSION}/${BINARY}_${OS}_${ARCH}.tar.gz"
    fi

    TARBALL="/tmp/${BINARY}-install.tar.gz"
    EXTRACT_DIR=$(mktemp -d)
    trap "rm -rf '$TARBALL' '$EXTRACT_DIR'" EXIT

    echo "=== Install yra CLI ==="
    echo "  Platform: ${OS}_${ARCH}"
    echo "  Version:  $VERSION"
    echo "  Target:   $BIN_DIR/$BINARY"
    echo ""

    echo "Downloading $FROM_URL ..."
    if ! curl -L -f -o "$TARBALL" "$FROM_URL"; then
        echo "ERROR: Download failed" >&2
        echo "URL: $FROM_URL" >&2
        return 1
    fi

    echo "Extracting..."
    if ! tar -xzf "$TARBALL" -C "$EXTRACT_DIR"; then
        echo "ERROR: Extraction failed" >&2
        return 1
    fi

    # Tarball contains yra_<OS>_<ARCH> (or .exe). Rename to bare yra.
    shopt -s nullglob
    EXTRACTED_FILES=("$EXTRACT_DIR"/${BINARY}_*)
    shopt -u nullglob
    if [[ ${#EXTRACTED_FILES[@]} -ne 1 ]] || [[ ! -f "${EXTRACTED_FILES[0]}" ]]; then
        echo "ERROR: Expected exactly one extracted binary, found ${#EXTRACTED_FILES[@]}" >&2
        return 1
    fi
    mv "${EXTRACTED_FILES[0]}" "$EXTRACT_DIR/$BINARY"
    chmod +x "$EXTRACT_DIR/$BINARY"

    mkdir -p "$BIN_DIR"
    cp "$EXTRACT_DIR/$BINARY" "$BIN_DIR/$BINARY"
    chmod +x "$BIN_DIR/$BINARY"

    echo ""
    echo "✓ Installed: $BIN_DIR/$BINARY"
    "$BIN_DIR/$BINARY" version 2>&1 | sed 's/^/  /'
}

# ----- Install skills -----

install_skills() {
    echo ""
    echo "=== Install skills ==="
    echo "  Source: $SKILLS_SRC"
    echo "  Target: $SKILLS_TARGET"
    echo ""

    if [ ! -d "$SKILLS_SRC" ]; then
        echo "ERROR: skills source not found: $SKILLS_SRC" >&2
        return 1
    fi

    SKILLS=("yra-news-summarize-today" "yra-news-search-news" "yra-news-setup")

    INSTALLED=0
    SKIPPED=0
    FAILED=0

    mkdir -p "$SKILLS_TARGET"

    for skill in "${SKILLS[@]}"; do
        SOURCE="$SKILLS_SRC/$skill"
        TARGET="$SKILLS_TARGET/$skill"

        if [ ! -d "$SOURCE" ]; then
            echo "  ✗ $skill (source not found)"
            FAILED=$((FAILED + 1))
            continue
        fi

        # Remove any pre-existing file/symlink/dir at target
        if [ -L "$TARGET" ] || [ -e "$TARGET" ]; then
            rm -rf "$TARGET"
        fi

        if cp -R "$SOURCE" "$TARGET"; then
            echo "  ✓ $skill"
            INSTALLED=$((INSTALLED + 1))
        else
            echo "  ✗ $skill (copy failed)"
            FAILED=$((FAILED + 1))
        fi
    done

    echo ""
    echo "  Installed: $INSTALLED, Failed: $FAILED"
    [ $FAILED -gt 0 ] && return 1
    return 0
}

# ----- Run -----

FAILED=0

if [[ $INSTALL_CLI -eq 1 ]]; then
    install_cli || FAILED=1
fi

if [[ $INSTALL_SKILLS -eq 1 ]]; then
    install_skills || FAILED=1
fi

# ----- Summary -----

echo ""
echo "=== Done ==="
if [[ $INSTALL_CLI -eq 1 ]] && [[ $FAILED -eq 0 ]]; then
    echo "yra:    $BIN_DIR/$BINARY"
fi
if [[ $INSTALL_SKILLS -eq 1 ]] && [[ $FAILED -eq 0 ]]; then
    echo "skills: $SKILLS_TARGET"
fi

if [[ $FAILED -gt 0 ]]; then
    echo ""
    echo "Some installations failed. See errors above." >&2
    exit 1
fi

# ----- Next steps -----

echo ""
echo "=== Next steps ==="
if [[ $INSTALL_CLI -eq 1 ]]; then
    if ! echo "$PATH" | grep -q "$BIN_DIR"; then
        echo "  ⚠ $BIN_DIR is not in your PATH."
        echo "    Add this to your shell rc (~/.zshrc, ~/.bashrc, etc.):"
        echo ""
        echo "      export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
    fi
    echo "  • $BINARY auth login   # authenticate with Feishu"
fi
if [[ $INSTALL_SKILLS -eq 1 ]]; then
    echo "  • Restart Claude Code to load the new skills."
fi
echo "  • To uninstall later: $SCRIPT_DIR/uninstall.sh"
