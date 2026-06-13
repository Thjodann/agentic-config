#!/bin/sh
# Uninstall the user-level Agentic Config Kit CLI and bundled templates.
#
# Typical remote use:
#   curl -fsSL <uninstall-script-url> | sh
#
# Dry run:
#   sh uninstall-agentic-config.sh --dry-run
set -eu

DEFAULT_INSTALL_DIR="$HOME/.local/share/agentic-config-kit"
INSTALL_DIR="${AGENTIC_CONFIG_HOME:-$DEFAULT_INSTALL_DIR}"
BIN_DIR="${AGENTIC_CONFIG_BIN:-$HOME/.local/bin}"
INSTALL_MARKER=".agentic-config-kit-install"
DRY_RUN=0

for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=1
            ;;
        -h|--help)
            echo "Usage: sh uninstall-agentic-config.sh [--dry-run]"
            exit 0
            ;;
        *)
            echo "ERROR: unknown argument: $arg" >&2
            echo "Usage: sh uninstall-agentic-config.sh [--dry-run]" >&2
            exit 2
            ;;
    esac
done

abs_link_target() {
    path="$1"
    link_target=$(readlink "$path" 2>/dev/null || true)
    case "$link_target" in
        /*) printf '%s\n' "$link_target" ;;
        *) printf '%s/%s\n' "$(CDPATH= cd -- "$(dirname -- "$path")" && pwd)" "$link_target" ;;
    esac
}

is_managed_cli() {
    path="$1"
    target="$INSTALL_DIR/agentic-config"
    if [ ! -e "$path" ] && [ ! -L "$path" ]; then
        return 1
    fi
    if [ -L "$path" ]; then
        [ "$(abs_link_target "$path")" = "$target" ]
        return $?
    fi
    if [ -f "$path" ] && [ -f "$target" ] && cmp -s "$path" "$target"; then
        return 0
    fi
    return 1
}

install_dir_looks_managed() {
    [ -d "$INSTALL_DIR" ] &&
        [ ! -L "$INSTALL_DIR" ] &&
        { [ -f "$INSTALL_DIR/$INSTALL_MARKER" ] || [ "$INSTALL_DIR" = "$DEFAULT_INSTALL_DIR" ]; } &&
        [ -f "$INSTALL_DIR/agentic-config" ] &&
        [ -f "$INSTALL_DIR/.ai/sync.py" ]
}

remove_file() {
    description="$1"
    path="$2"
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "Would remove $description: $path"
    else
        rm -f "$path"
        echo "Removed $description: $path"
    fi
}

remove_dir() {
    description="$1"
    path="$2"
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "Would remove $description: $path"
    else
        rm -rf "$path"
        echo "Removed $description: $path"
    fi
}

echo "Agentic Config Kit uninstall"
echo "  kit: $INSTALL_DIR"
echo "  bin: $BIN_DIR"

for name in agentic-config agc; do
    path="$BIN_DIR/$name"
    if [ ! -e "$path" ] && [ ! -L "$path" ]; then
        echo "Skipped missing command: $path"
    elif is_managed_cli "$path"; then
        remove_file "command" "$path"
    else
        echo "Skipped non-ACK command: $path"
    fi
done

if [ -e "$INSTALL_DIR" ]; then
    if install_dir_looks_managed; then
        remove_dir "kit directory" "$INSTALL_DIR"
    else
        echo "ERROR: refusing to remove install dir that does not look ACK-managed: $INSTALL_DIR" >&2
        exit 1
    fi
else
    echo "Skipped missing kit directory: $INSTALL_DIR"
fi

if [ "$DRY_RUN" -eq 1 ]; then
    echo "Dry run complete; no files were removed."
else
    echo "Uninstall complete."
    echo "Open a new shell or run 'hash -r' / 'rehash' if your shell cached the command."
fi
