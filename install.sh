#!/bin/bash
# Legacy installer for putting Agentic Config into a target repository.
#
#   ./install.sh [target-repo-dir]   (default: current directory)
#
# Prefer the global CLI when available:
#
#   agentic init [target-repo-dir]
#
# This fallback copies the canonical .ai/ master + ./sync-agentic.sh into the
# target repo, runs an initial sync, and offers to install the pre-commit
# staleness guard. Non-destructive: refuses to overwrite an existing .ai/ folder.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-.}"
TARGET="$(cd "$TARGET" && pwd)"

echo "Agentic Config → installing into: $TARGET"

# --- preconditions ---
command -v python3 >/dev/null 2>&1 || { echo "❌ python3 is required (3.6+)."; exit 1; }

if [ -e "$TARGET/.ai" ]; then
    echo "❌ $TARGET/.ai already exists. Refusing to overwrite."
    echo "   To upgrade just the generator, copy .ai/sync.py manually."
    exit 1
fi

# --- copy master + wrapper ---
cp -R "$KIT_DIR/.ai" "$TARGET/.ai"
cp "$KIT_DIR/sync-agentic.sh" "$TARGET/sync-agentic.sh"
chmod +x "$TARGET/sync-agentic.sh"
echo "✅ Copied .ai/ and sync-agentic.sh"

# --- source-only ignore block ---
IGNORE_BLOCK_START="# BEGIN agentic-config-kit generated projections"
IGNORE_BLOCK_END="# END agentic-config-kit generated projections"
if [ -f "$TARGET/.gitignore" ]; then
    if ! grep -q "$IGNORE_BLOCK_START" "$TARGET/.gitignore"; then
        {
            echo ""
            echo "$IGNORE_BLOCK_START"
            echo ".agentic-config/"
            echo ".claude/"
            echo ".cursor/"
            echo ".devin/"
            echo ".windsurf/"
            echo ".agents/"
            echo ".codex/agents/"
            echo ".continue/"
            echo "!.codex/"
            echo "!.codex/config.toml"
            echo "!.codex/rules/"
            echo "!.codex/rules/**"
            echo "$IGNORE_BLOCK_END"
        } >> "$TARGET/.gitignore"
        echo "✅ Added source-only generated-folder rules to .gitignore"
    fi
else
    cp "$KIT_DIR/.gitignore" "$TARGET/.gitignore"
    echo "✅ Added .gitignore for source-only generated folders"
fi

# --- initial generation ---
if ! ( cd "$TARGET" && ./sync-agentic.sh ); then
    echo "❌ Initial sync stopped before overwriting existing native IDE config."
    echo "   Run ./sync-agentic.sh doctor in $TARGET, then adopt or reconcile the reported files."
    exit 1
fi

# --- optional: git hook ---
if [ -d "$TARGET/.git" ]; then
    printf "Install the pre-commit staleness guard? [y/N] "
    read -r ans || ans=""
    case "$ans" in
        y|Y)
            HOOK="$TARGET/.git/hooks/pre-commit"
            if [ -e "$HOOK" ]; then
                echo "⚠️  $HOOK already exists — not overwriting."
                echo "    Merge the guard block from hooks/pre-commit into it manually."
            else
                cp "$KIT_DIR/hooks/pre-commit" "$HOOK"
                chmod +x "$HOOK"
                echo "✅ Installed pre-commit guard"
            fi
            ;;
        *) echo "ℹ️  Skipped hook. See hooks/pre-commit to install later." ;;
    esac
else
    echo "ℹ️  $TARGET is not a git repo — skipping hook. Run hooks/pre-commit setup after 'git init'."
fi

echo ""
echo "🎉 Done. Edit assets in $TARGET/.ai/, then run ./sync-agentic.sh."
echo "   With the global CLI installed, you can also run: agentic sync"
echo "   Docs: $TARGET/.ai/README.md"
