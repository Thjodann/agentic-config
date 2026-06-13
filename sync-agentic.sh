#!/bin/bash
# Manage per-IDE agentic config from canonical .ai/ config. See .ai/README.md.
#
#   ./sync-agentic.sh                         regenerate all IDE folders
#   ./sync-agentic.sh check                   fail if generated output is stale
#   ./sync-agentic.sh doctor                  diagnose native-only/stale/conflicts
#   ./sync-agentic.sh adopt cursor <path>     promote native config into .ai/
#   ./sync-agentic.sh reconcile --all-exact   canonicalize exact duplicates
#   ./sync-agentic.sh demote cursor <path>    hide a generated path from one IDE
#   ./sync-agentic.sh promote cursor <path>   restore a demoted generated path
#   ./sync-agentic.sh clean                   remove generated projections
#   ./sync-agentic.sh bootstrap               generate local projections after clone
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$ROOT_DIR/.ai/sync.py" "$@"
