#!/bin/bash
set -e

# YRA Skills - Uninstall script
# Usage:
#   ./scripts/uninstall-skills.sh               # Global uninstall (default)
#   ./scripts/uninstall-skills.sh --global
#   ./scripts/uninstall-skills.sh --project     # Uninstall from current directory
#   ./scripts/uninstall-skills.sh --dir <path>  # Uninstall from specified directory

# Skills to remove
SKILLS=(
    "yra-summarize-today"
    "yra-search-news"
    "yra-setup"
)

# Default mode: global
MODE="global"
TARGET_DIR=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --global)
            MODE="global"
            TARGET_DIR="$HOME/.claude"
            shift
            ;;
        --project)
            MODE="project"
            TARGET_DIR="$(pwd)"
            shift
            ;;
        --dir)
            MODE="custom"
            TARGET_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--global|--project|--dir <path>]"
            echo ""
            echo "Options:"
            echo "  --global              Uninstall from ~/.claude/skills (default)"
            echo "  --project             Uninstall from <current-dir>/.claude/skills"
            echo "  --dir <path>          Uninstall from <path>/.claude/skills"
            echo "  -h, --help            Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

# Set default target if not provided
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="$HOME/.claude"
fi

SKILLS_TARGET="$TARGET_DIR/.claude/skills"

echo "=== YRA Skills Uninstall ==="
echo "Mode: $MODE"
echo "Target: $SKILLS_TARGET"
echo ""

# Check that target directory exists
if [ ! -d "$SKILLS_TARGET" ]; then
    echo "Target directory does not exist: $SKILLS_TARGET"
    echo "Nothing to uninstall."
    exit 0
fi

# Remove each skill symlink
REMOVED=0
NOT_FOUND=0
FAILED=0

for skill in "${SKILLS[@]}"; do
    LINK="$SKILLS_TARGET/$skill"

    if [ ! -e "$LINK" ]; then
        echo "  - $skill (not installed)"
        NOT_FOUND=$((NOT_FOUND + 1))
        continue
    fi

    if [ ! -L "$LINK" ]; then
        # Not a symlink — refuse to remove to avoid data loss
        echo "  ! $skill (not a symlink, refusing to remove)"
        echo "    Please remove manually if intended: $LINK"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Confirm before removing
    if [ "${YES:-0}" != "1" ]; then
        read -p "  Remove $LINK? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "    Skipped"
            continue
        fi
    fi

    # Remove symlink
    if rm "$LINK"; then
        echo "  ✓ $skill (removed)"
        REMOVED=$((REMOVED + 1))
    else
        echo "  ✗ $skill (failed to remove)"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "=== Summary ==="
echo "  Removed:    $REMOVED"
echo "  Not found:  $NOT_FOUND"
echo "  Failed:     $FAILED"
echo ""

if [ $REMOVED -gt 0 ]; then
    echo "✓ YRA skills uninstalled."
    echo "  Restart Claude Code to unload the skills."
    echo ""
fi

exit $FAILED
