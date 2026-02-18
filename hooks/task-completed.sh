#!/bin/bash
# TaskCompleted hook — auto-toggle matching checkbox in SlashNote
set -euo pipefail

MCP_BASE_URL="${MCP_BASE_URL:-http://127.0.0.1:51423}"
STATE_FILE=".claude/slashnote-loop.local.md"

# Read task info from stdin (Claude Code passes JSON with task details)
input=$(cat)
task_subject=$(echo "$input" | grep -o '"task_subject":"[^"]*"' | sed 's/"task_subject":"//;s/"$//' || echo "")

# Skip if no task subject
[ -z "$task_subject" ] && exit 0

# Check if loop is active with a note
[ ! -f "$STATE_FILE" ] && exit 0
note_id=$(grep '"note_id"' "$STATE_FILE" | grep -o '"[a-f0-9-]*"' | tail -1 | tr -d '"' || echo "")
[ -z "$note_id" ] && exit 0

# Try to toggle matching checkbox by text
curl -s -f --connect-timeout 3 -X POST "$MCP_BASE_URL/notes/$note_id/toggle" \
  -H "Content-Type: application/json" \
  -d "{\"checkboxText\": $(echo "$task_subject" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().strip()))'), \"state\": \"done\"}" \
  2>/dev/null || true

exit 0
