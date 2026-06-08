#!/bin/bash
set -e

# YRA Skills - Install script
# Usage:
#   ./scripts/install-skills.sh                 # Global install (default)
#   ./scripts/install-skills.sh --global
#   ./scripts/install-skills.sh --project       # Install to current directory
#   ./scripts/install-skills.sh --dir <path>    # Install to specified directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# scripts/install-skills.sh → repo root → skills/
SKILLS_DIR="$(cd "$SCRIPT_DIR/../skills" && pwd)"

# Skills to install
SKILLS=(
    "yra-news-summarize-today"
    "yra-news-search-news"
    "yra-news-setup"
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
            echo "  --global              Install to ~/.claude/skills (default)"
            echo "  --project             Install to <current-dir>/.claude/skills"
            echo "  --dir <path>          Install to <path>/.claude/skills"
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

echo "=== YRA Skills Install ==="
echo "Mode: $MODE"
echo "Target: $SKILLS_TARGET"
echo "Source: $SKILLS_DIR"
echo ""

# Create target directory
mkdir -p "$SKILLS_TARGET"

# Check that source skills exist
for skill in "${SKILLS[@]}"; do
    if [ ! -d "$SKILLS_DIR/$skill" ]; then
        echo "ERROR: Skill directory not found: $SKILLS_DIR/$skill"
        exit 1
    fi
done

# Install each skill as a symlink
INSTALLED=0
SKIPPED=0
FAILED=0

for skill in "${SKILLS[@]}"; do
    SOURCE="$SKILLS_DIR/$skill"
    LINK="$SKILLS_TARGET/$skill"

    if [ -L "$LINK" ]; then
        # Symlink already exists
        TARGET=$(readlink "$LINK")
        if [ "$TARGET" = "$SOURCE" ]; then
            echo "  ✓ $skill (already installed)"
            SKIPPED=$((SKIPPED + 1))
            continue
        else
            # Symlink exists but points to different source
            echo "  ! $skill (existing symlink points to: $TARGET)"
            read -p "    Replace with $SOURCE? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm "$LINK"
            else
                echo "    Skipped"
                SKIPPED=$((SKIPPED + 1))
                continue
            fi
        fi
    elif [ -e "$LINK" ]; then
        # Path exists but is not a symlink (regular file or directory)
        echo "  ! $skill (existing file/directory, not a symlink)"
        echo "    Please remove manually: $LINK"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Create symlink
    if ln -s "$SOURCE" "$LINK"; then
        echo "  ✓ $skill → $SOURCE"
        INSTALLED=$((INSTALLED + 1))
    else
        echo "  ✗ $skill (failed to create symlink)"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "=== Summary ==="
echo "  Installed: $INSTALLED"
echo "  Skipped:   $SKIPPED"
echo "  Failed:    $FAILED"
echo ""

if [ $INSTALLED -gt 0 ]; then
    echo "✓ YRA skills installed successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Install the yra CLI: $SCRIPT_DIR/install-cli.sh"
    echo "  2. Authenticate: yra auth login"
    echo "  3. Restart Claude Code to load the new skills"
    echo ""
fi

exit $FAILED
