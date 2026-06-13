#!/bin/sh
# Install the Agentic Config CLI and bundled templates.
#
# Typical remote use:
#   curl -fsSL <install-script-url> | sh
#
# Local/test use:
#   AGENTIC_CONFIG_SOURCE_DIR=/path/to/agentic-config sh install-agentic-config.sh
set -eu

INSTALL_DIR="${AGENTIC_CONFIG_HOME:-$HOME/.local/share/agentic-config-kit}"
BIN_DIR="${AGENTIC_CONFIG_BIN:-$HOME/.local/bin}"
DEFAULT_RELEASE_API_URL="https://api.github.com/repos/Thjodann/agentic-config/releases/latest"
DEFAULT_RELEASE_ARCHIVE_BASE="https://github.com/Thjodann/agentic-config/archive/refs/tags"
DEFAULT_RELEASE_HTML_BASE="https://github.com/Thjodann/agentic-config"
RELEASE_API_URL="${AGENTIC_CONFIG_RELEASE_API_URL:-$DEFAULT_RELEASE_API_URL}"
RELEASE_ARCHIVE_BASE="${AGENTIC_CONFIG_RELEASE_ARCHIVE_BASE:-$DEFAULT_RELEASE_ARCHIVE_BASE}"
RELEASE_HTML_BASE="${AGENTIC_CONFIG_RELEASE_HTML_BASE:-$DEFAULT_RELEASE_HTML_BASE}"
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
    tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/agentic-config.XXXXXX")
    archive="$tmp_dir/kit.tar.gz"
    if [ -z "$ARCHIVE_URL" ]; then
        echo "Checking latest Agentic Config release..."
        release_json=$(curl -fsSL "$RELEASE_API_URL")
        release_tag=$(printf '%s\n' "$release_json" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
        if [ -z "$release_tag" ]; then
            echo "ERROR: could not determine latest Agentic Config release tag." >&2
            exit 1
        fi
        ARCHIVE_URL="$RELEASE_ARCHIVE_BASE/$release_tag.tar.gz"
        echo "Downloading Agentic Config $release_tag..."
    else
        echo "Downloading Agentic Config..."
    fi
    curl -fsSL "$ARCHIVE_URL" -o "$archive"
    tar -xzf "$archive" -C "$tmp_dir"
    source_dir=$(find "$tmp_dir"/* -maxdepth 0 -type d -name "agentic-config*" | head -n 1)
fi

if [ ! -f "$source_dir/agentic-config" ] || [ ! -d "$source_dir/.ai" ]; then
    echo "ERROR: source directory is not an Agentic Config checkout: $source_dir" >&2
    exit 1
fi

source_remote_url=""
if command -v git >/dev/null 2>&1; then
    source_remote_url=$(git -C "$source_dir" config --get remote.origin.url 2>/dev/null || true)
fi

remote_to_https_base() {
    remote="$1"
    case "$remote" in
        https://*/*)
            rest=${remote#https://}
            rest=${rest#*@}
            rest=${rest%.git}
            printf 'https://%s\n' "$rest"
            ;;
        http://*/*)
            rest=${remote#http://}
            rest=${rest#*@}
            rest=${rest%.git}
            printf 'http://%s\n' "$rest"
            ;;
        git@*:*)
            rest=${remote#git@}
            host=${rest%%:*}
            path=${rest#*:}
            path=${path%.git}
            printf 'https://%s/%s\n' "$host" "$path"
            ;;
        ssh://git@*/*)
            rest=${remote#ssh://git@}
            host=${rest%%/*}
            path=${rest#*/}
            path=${path%.git}
            printf 'https://%s/%s\n' "$host" "$path"
            ;;
    esac
}

release_source_base=""
if [ -n "$source_remote_url" ]; then
    release_source_base=$(remote_to_https_base "$source_remote_url" || true)
fi

if [ -n "$release_source_base" ]; then
    base_without_scheme=${release_source_base#https://}
    base_without_scheme=${base_without_scheme#http://}
    host=${base_without_scheme%%/*}
    repo_path=${base_without_scheme#*/}
    if [ "$repo_path" != "$base_without_scheme" ]; then
        if [ -z "${AGENTIC_CONFIG_RELEASE_API_URL:-}" ]; then
            if [ "$host" = "github.com" ]; then
                RELEASE_API_URL="https://api.github.com/repos/$repo_path/releases/latest"
            else
                RELEASE_API_URL="https://$host/api/v3/repos/$repo_path/releases/latest"
            fi
        fi
        if [ -z "${AGENTIC_CONFIG_RELEASE_ARCHIVE_BASE:-}" ]; then
            RELEASE_ARCHIVE_BASE="$release_source_base/archive/refs/tags"
        fi
        if [ -z "${AGENTIC_CONFIG_RELEASE_HTML_BASE:-}" ]; then
            RELEASE_HTML_BASE="$release_source_base"
        fi
    fi
fi

mkdir -p "$INSTALL_DIR" "$BIN_DIR"

rm -rf "$INSTALL_DIR/.ai" "$INSTALL_DIR/hooks" "$INSTALL_DIR/assets"
cp -R "$source_dir/.ai" "$INSTALL_DIR/.ai"
[ -d "$source_dir/hooks" ] && cp -R "$source_dir/hooks" "$INSTALL_DIR/hooks"
[ -d "$source_dir/assets" ] && cp -R "$source_dir/assets" "$INSTALL_DIR/assets"

for file in agentic-config sync-agentic.sh install.sh install-agentic-config.sh uninstall-agentic-config.sh README.md AGENTIC-CONFIG-RUNBOOK.md INSTALLER-RUNBOOK.md AGENT-ASSISTED-UPDATE-RUNBOOK.md VERSION CHANGELOG.md .gitignore; do
    if [ -f "$source_dir/$file" ]; then
        cp "$source_dir/$file" "$INSTALL_DIR/$file"
    fi
done
{
    printf '%s\n' "managed_by=agentic-config-kit"
    [ -n "$release_source_base" ] && printf '%s\n' "source_base=$release_source_base"
    printf '%s\n' "release_api_url=$RELEASE_API_URL"
    printf '%s\n' "release_archive_base=$RELEASE_ARCHIVE_BASE"
    printf '%s\n' "release_html_base=$RELEASE_HTML_BASE"
} > "$INSTALL_DIR/.agentic-config-kit-install"

chmod +x "$INSTALL_DIR/agentic-config" "$INSTALL_DIR/sync-agentic.sh"
[ -f "$INSTALL_DIR/uninstall-agentic-config.sh" ] && chmod +x "$INSTALL_DIR/uninstall-agentic-config.sh"

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
            echo "WARNING: $dest already exists and is not Agentic Config-managed; leaving it unchanged." >&2
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

if install_cli_name "agentic"; then
    agentic_status="installed"
else
    agentic_status="skipped"
fi

install_cli_name "agentic-config" "force"
if install_cli_name "agc"; then
    agc_status="installed"
else
    agc_status="skipped"
fi

if [ "$agentic_status" = "installed" ]; then
    next_cmd="agentic"
else
    next_cmd="agentic-config"
fi

echo "Installed Agentic Config:"
echo "  kit: $INSTALL_DIR"
if [ "$agentic_status" = "installed" ]; then
    echo "  cli: $BIN_DIR/agentic"
else
    echo "  cli: agentic skipped because an existing non-Agentic Config command was found"
fi
echo "  compatibility: $BIN_DIR/agentic-config"
if [ "$agc_status" = "installed" ]; then
    echo "  legacy alias: $BIN_DIR/agc"
else
    echo "  legacy alias: agc skipped because an existing non-Agentic Config command was found"
fi

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        echo ""
        echo "Add this to your PATH to use $next_cmd everywhere:"
        echo "  export PATH=\"$BIN_DIR:\$PATH\""
        ;;
esac

echo ""
echo "Next:"
echo "  $next_cmd init /path/to/repo"
echo "  $next_cmd init --stealth /path/to/repo"
echo ""
echo "Compatibility command also works:"
echo "  agentic-config init /path/to/repo"
