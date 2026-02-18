#!/bin/bash
# PreCompact hook — save session context to SlashNote before context compression
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_BASE_URL="${MCP_BASE_URL:-http://127.0.0.1:51423}"

# Source git utilities
source "$SCRIPT_DIR/../scripts/git-context.sh"

# Collect context
branch=$(get_git_branch)
project=$(get_project_name)
uncommitted=$(get_uncommitted_summary)
timestamp=$(date '+%Y-%m-%d %H:%M')

# Check for active loop state
STATE_FILE=".claude/slashnote-loop.local.md"
loop_context=""
if [ -f "$STATE_FILE" ]; then
  loop_context=$(python3 -c "
import json
with open('$STATE_FILE', 'r') as f: state = json.load(f)
tasks = state.get('tasks', [])
completed = state.get('completed_tasks', [])
current = state.get('current_task', 0)
active = state.get('active', False)
if active:
    remaining = [t for i, t in enumerate(tasks) if i not in completed]
    print(f'\n## Active Loop\nCurrent task #{current + 1}: {tasks[current] if current < len(tasks) else \"?\"}\nRemaining: {\", \".join(remaining)}')
else:
    print('')
" 2>/dev/null) || true
fi

# Build note content
content="# Context Snapshot
**$timestamp** | $project @ $branch

## Working State
$uncommitted
$loop_context

## Recent Commits
$(get_recent_commits 3)"

# Create context note (blue, not pinned)
curl -s -f --connect-timeout 3 -X POST "$MCP_BASE_URL/notes" \
  -H "Content-Type: application/json" \
  -d "{
    \"content\": $(echo "$content" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'),
    \"color\": \"blue\",
    \"tag\": \"\"
  }" 2>/dev/null || true

exit 0
