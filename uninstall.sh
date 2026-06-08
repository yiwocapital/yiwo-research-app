#!/bin/bash
# YIWO Research App - Uninstaller
#
# Removes yra CLI and/or Claude Code skills installed by install.sh.
#
# Usage:
#   ./uninstall.sh                            # Default: yra + skills, with prompt
#   ./uninstall.sh --cli-only                 # Remove yra only
#   ./uninstall.sh --skills-only              # Remove skills only
#   ./uninstall.sh --bin-dir <path>           # Custom binary dir (default ~/.local/bin)
#   ./uninstall.sh --skills-dir <path>        # Custom skills parent (default ~)
#   ./uninstall.sh --yes                      # Skip confirmation prompt

set -e

BINARY="yra"
BIN_DIR="$HOME/.local/bin"
SKILLS_PARENT="$HOME"
REMOVE_CLI=1
REMOVE_SKILLS=1
ASSUME_YES=0

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
        --cli-only)
            REMOVE_SKILLS=0
            shift
            ;;
        --skills-only)
            REMOVE_CLI=0
            shift
            ;;
        --yes|-y)
            ASSUME_YES=1
            shift
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

SKILLS=("yra-news-summarize-today" "yra-news-search-news" "yra-setup")
SKILLS_TARGET="$SKILLS_PARENT/.claude/skills"

confirm() {
    local prompt="$1"
    if [[ $ASSUME_YES -eq 1 ]]; then
        return 0
    fi
    read -p "$prompt [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# ----- Remove yra CLI -----

if [[ $REMOVE_CLI -eq 1 ]]; then
    echo "=== Remove yra CLI ==="
    if [ -f "$BIN_DIR/$BINARY" ]; then
        if confirm "Remove $BIN_DIR/$BINARY?"; then
            rm -f "$BIN_DIR/$BINARY"
            echo "  ✓ Removed $BIN_DIR/$BINARY"
        else
            echo "  Skipped"
        fi
    else
        echo "  Not installed at $BIN_DIR/$BINARY"
    fi
    echo ""
fi

# ----- Remove skills -----

if [[ $REMOVE_SKILLS -eq 1 ]]; then
    echo "=== Remove skills ==="
    for skill in "${SKILLS[@]}"; do
        TARGET="$SKILLS_TARGET/$skill"
        if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
            rm -rf "$TARGET"
            echo "  ✓ Removed $TARGET"
        else
            echo "  - $skill (not installed)"
        fi
    done
    echo ""

    echo "=== Remove legacy skills ==="
    LEGACY=("yra-news-setup")
    for legacy in "${LEGACY[@]}"; do
        TARGET="$SKILLS_TARGET/$legacy"
        if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
            rm -rf "$TARGET"
            echo "  ✓ Removed $TARGET"
        else
            echo "  - $legacy (not installed)"
        fi
    done
    echo ""
fi

echo "=== Done ==="
