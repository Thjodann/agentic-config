#!/bin/sh
# Install the Agentic Config Kit CLI and bundled templates.
#
# Typical remote use:
#   curl -fsSL <install-script-url> | sh
#
# Local/test use:
#   AGENTIC_CONFIG_SOURCE_DIR=/path/to/agentic-config-kit sh install-agentic-config.sh
set -eu

INSTALL_DIR="${AGENTIC_CONFIG_HOME:-$HOME/.local/share/agentic-config-kit}"
BIN_DIR="${AGENTIC_CONFIG_BIN:-$HOME/.local/bin}"
ARCHIVE_URL="${AGENTIC_CONFIG_ARCHIVE_URL:-https://github.boozallencsn.com/CORNERSTONE/agentic-config-kit/archive/refs/heads/main.tar.gz}"

tmp_dir=""
cleanup() {
    if [ -n "$tmp_dir" ] && [ -d "$tmp_dir" ]; then
        rm -rf "$tmp_dir"
    fi
}
trap cleanup EXIT INT TERM

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source_dir="${AGENTIC_CONFIG_SOURCE_DIR:-}"

if [ -z "$source_dir" ] && [ -f "$script_dir/agentic-config" ] && [ -d "$script_dir/.ai" ]; then
    source_dir="$script_dir"
fi

if [ -z "$source_dir" ]; then
    command -v curl >/dev/null 2>&1 || {
        echo "ERROR: curl is required unless AGENTIC_CONFIG_SOURCE_DIR is set." >&2
        exit 1
    }
    command -v tar >/dev/null 2>&1 || {
        echo "ERROR: tar is required unless AGENTIC_CONFIG_SOURCE_DIR is set." >&2
        exit 1
    }
    tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/agentic-config-kit.XXXXXX")
    archive="$tmp_dir/kit.tar.gz"
    echo "Downloading Agentic Config Kit..."
    curl -fsSL "$ARCHIVE_URL" -o "$archive"
    tar -xzf "$archive" -C "$tmp_dir"
    source_dir=$(find "$tmp_dir" -maxdepth 1 -type d -name "agentic-config-kit*" | head -n 1)
fi

if [ ! -f "$source_dir/agentic-config" ] || [ ! -d "$source_dir/.ai" ]; then
    echo "ERROR: source directory is not an Agentic Config Kit checkout: $source_dir" >&2
    exit 1
fi

mkdir -p "$INSTALL_DIR" "$BIN_DIR"

rm -rf "$INSTALL_DIR/.ai" "$INSTALL_DIR/hooks" "$INSTALL_DIR/assets"
cp -R "$source_dir/.ai" "$INSTALL_DIR/.ai"
[ -d "$source_dir/hooks" ] && cp -R "$source_dir/hooks" "$INSTALL_DIR/hooks"
[ -d "$source_dir/assets" ] && cp -R "$source_dir/assets" "$INSTALL_DIR/assets"

for file in agentic-config sync-agentic.sh install.sh install-agentic-config.sh README.md INSTALLER-RUNBOOK.md .gitignore; do
    if [ -f "$source_dir/$file" ]; then
        cp "$source_dir/$file" "$INSTALL_DIR/$file"
    fi
done

chmod +x "$INSTALL_DIR/agentic-config" "$INSTALL_DIR/sync-agentic.sh"

rm -f "$BIN_DIR/agentic-config"
if ln -s "$INSTALL_DIR/agentic-config" "$BIN_DIR/agentic-config" 2>/dev/null; then
    :
else
    cp "$INSTALL_DIR/agentic-config" "$BIN_DIR/agentic-config"
    chmod +x "$BIN_DIR/agentic-config"
fi

echo "Installed Agentic Config Kit:"
echo "  kit: $INSTALL_DIR"
echo "  cli: $BIN_DIR/agentic-config"

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        echo ""
        echo "Add this to your PATH to use agentic-config everywhere:"
        echo "  export PATH=\"$BIN_DIR:\$PATH\""
        ;;
esac

echo ""
echo "Next:"
echo "  agentic-config init /path/to/repo"
echo "  agentic-config init --stealth /path/to/repo"
