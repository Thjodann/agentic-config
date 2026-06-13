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
RELEASE_API_URL="${AGENTIC_CONFIG_RELEASE_API_URL:-https://api.github.com/repos/Thjodann/agentic-config-kit/releases/latest}"
RELEASE_ARCHIVE_BASE="${AGENTIC_CONFIG_RELEASE_ARCHIVE_BASE:-https://github.com/Thjodann/agentic-config-kit/archive/refs/tags}"
ARCHIVE_URL="${AGENTIC_CONFIG_ARCHIVE_URL:-}"

tmp_dir=""
cleanup() {
    if [ -n "$tmp_dir" ] && [ -d "$tmp_dir" ]; then
        rm -rf "$tmp_dir"
    fi
}
trap cleanup EXIT INT TERM

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source_dir="${AGENTIC_CONFIG_SOURCE_DIR:-}"

if [ -z "$ARCHIVE_URL" ] && [ -z "$source_dir" ] && [ -f "$script_dir/agentic-config" ] && [ -d "$script_dir/.ai" ]; then
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
    if [ -z "$ARCHIVE_URL" ]; then
        echo "Checking latest Agentic Config Kit release..."
        release_json=$(curl -fsSL "$RELEASE_API_URL")
        release_tag=$(printf '%s\n' "$release_json" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
        if [ -z "$release_tag" ]; then
            echo "ERROR: could not determine latest Agentic Config Kit release tag." >&2
            exit 1
        fi
        ARCHIVE_URL="$RELEASE_ARCHIVE_BASE/$release_tag.tar.gz"
        echo "Downloading Agentic Config Kit $release_tag..."
    else
        echo "Downloading Agentic Config Kit..."
    fi
    curl -fsSL "$ARCHIVE_URL" -o "$archive"
    tar -xzf "$archive" -C "$tmp_dir"
    source_dir=$(find "$tmp_dir"/* -maxdepth 0 -type d -name "agentic-config-kit*" | head -n 1)
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

for file in agentic-config sync-agentic.sh install.sh install-agentic-config.sh README.md INSTALLER-RUNBOOK.md AGENT-ASSISTED-UPDATE-RUNBOOK.md VERSION CHANGELOG.md .gitignore; do
    if [ -f "$source_dir/$file" ]; then
        cp "$source_dir/$file" "$INSTALL_DIR/$file"
    fi
done

chmod +x "$INSTALL_DIR/agentic-config" "$INSTALL_DIR/sync-agentic.sh"

install_cli_name() {
    name="$1"
    dest="$BIN_DIR/$name"
    force="${2:-}"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ "$force" = "force" ]; then
            rm -f "$dest"
        elif [ -L "$dest" ] && [ "$(readlink "$dest" 2>/dev/null || true)" = "$INSTALL_DIR/agentic-config" ]; then
            rm -f "$dest"
        elif [ -f "$dest" ] && cmp -s "$dest" "$INSTALL_DIR/agentic-config"; then
            rm -f "$dest"
        else
            echo "WARNING: $dest already exists and is not ACK-managed; leaving it unchanged." >&2
            return 1
        fi
    fi

    if ln -s "$INSTALL_DIR/agentic-config" "$dest" 2>/dev/null; then
        :
    else
        cp "$INSTALL_DIR/agentic-config" "$dest"
        chmod +x "$dest"
    fi
    return 0
}

install_cli_name "agentic-config" "force"
if install_cli_name "agc"; then
    agc_status="installed"
else
    agc_status="skipped"
fi

echo "Installed Agentic Config Kit:"
echo "  kit: $INSTALL_DIR"
echo "  cli: $BIN_DIR/agentic-config"
if [ "$agc_status" = "installed" ]; then
    echo "  alias: $BIN_DIR/agc"
else
    echo "  alias: agc skipped because an existing non-ACK command was found"
fi

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
echo "  agc init /path/to/repo"
echo "  agc init --stealth /path/to/repo"
echo ""
echo "Full command also works:"
echo "  agentic-config init /path/to/repo"
