#!/bin/bash
# YIWO Research App - Uninstaller
#
# Removes yra CLI and/or the yra skills installed by install.sh.
# Can target one or both runtimes (Claude Code, Codex).
#
# Usage:
#   ./uninstall.sh                            # Default: yra + skills from both runtimes, with prompt
#   ./uninstall.sh --cli-only                 # Remove yra only
#   ./uninstall.sh --skills-only              # Remove skills only
#   ./uninstall.sh --target claude|codex|both # Pick runtime (default: both)
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
TARGET="both"   # claude | codex | both

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
        --target)
            TARGET="$2"
            shift 2
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

case "$TARGET" in
    claude|codex|both) ;;
    *) echo "Invalid --target: $TARGET (expected: claude | codex | both)" >&2; exit 1 ;;
esac

claude_skills_dir() { echo "$SKILLS_PARENT/.claude/skills"; }
codex_skills_dir()  { echo "$SKILLS_PARENT/.codex/skills"; }

SKILLS=("yra-news-summarize-today" "yra-news-search" "yra-setup")

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

# ----- Remove skills from a single target directory -----

remove_skills_at() {
    local LABEL="$1"
    local SKILLS_TARGET="$2"

    echo "=== Remove skills (${LABEL}: ${SKILLS_TARGET}) ==="
    for skill in "${SKILLS[@]}"; do
        TARGET_PATH="$SKILLS_TARGET/$skill"
        if [ -e "$TARGET_PATH" ] || [ -L "$TARGET_PATH" ]; then
            rm -rf "$TARGET_PATH"
            echo "  ✓ Removed $TARGET_PATH"
        else
            echo "  - $skill (not installed)"
        fi
    done
    echo ""

    echo "=== Remove legacy skills (${LABEL}) ==="
    LEGACY=("yra-news-setup" "yra-news-search-news")
    for legacy in "${LEGACY[@]}"; do
        TARGET_PATH="$SKILLS_TARGET/$legacy"
        if [ -e "$TARGET_PATH" ] || [ -L "$TARGET_PATH" ]; then
            rm -rf "$TARGET_PATH"
            echo "  ✓ Removed $TARGET_PATH"
        else
            echo "  - $legacy (not installed)"
        fi
    done
    echo ""
}

# ----- Remove skills (multi-target) -----

if [[ $REMOVE_SKILLS -eq 1 ]]; then
    case "$TARGET" in
        claude)
            remove_skills_at "Claude Code" "$(claude_skills_dir)"
            ;;
        codex)
            remove_skills_at "Codex" "$(codex_skills_dir)"
            ;;
        both)
            remove_skills_at "Claude Code" "$(claude_skills_dir)"
            remove_skills_at "Codex" "$(codex_skills_dir)"
            ;;
    esac
fi

echo "=== Done ==="
