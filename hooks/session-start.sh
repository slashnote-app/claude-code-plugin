#!/bin/bash
# SessionStart hook — inject git context + check pending SlashNote tasks
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_BASE_URL="${MCP_BASE_URL:-http://127.0.0.1:51423}"

# Source git utilities
source "$SCRIPT_DIR/../scripts/git-context.sh"

# Collect git context
branch=$(get_git_branch)
project=$(get_project_name)
commits=$(get_recent_commits 5)

# Check SlashNote for pending tasks (non-blocking)
pending_info=""
stats=$(curl -s -f --connect-timeout 2 "$MCP_BASE_URL/stats" 2>/dev/null) || true
if [ -n "$stats" ]; then
  total_notes=$(echo "$stats" | grep -o '"totalNotes":[0-9]*' | grep -o '[0-9]*' || echo "0")
  if [ "$total_notes" -gt 0 ]; then
    # Search for focus notes with unchecked items
    focus_search=$(curl -s -f --connect-timeout 2 "$MCP_BASE_URL/notes/search?q=Focus&limit=1" 2>/dev/null) || true
    if [ -n "$focus_search" ]; then
      pending_info=" | SlashNote: $total_notes notes"
    fi
  fi
fi

# Check for active task loop
STATE_FILE=".claude/slashnote-loop.local.md"
loop_info=""
if [ -f "$STATE_FILE" ]; then
  active=$(grep '^"active":' "$STATE_FILE" 2>/dev/null | grep -o 'true\|false' || echo "false")
  if [ "$active" = "true" ]; then
    loop_info=" | Task loop ACTIVE (use /pause to stop)"
  fi
fi

# Output system message
cat <<EOF
{"systemMessage":"[SlashNote] $project @ $branch$pending_info$loop_info"}
EOF
