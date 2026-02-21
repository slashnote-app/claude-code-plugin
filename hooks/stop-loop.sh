#!/bin/bash
# Stop hook — task execution loop controller
# If loop active: block exit and return next task instructions
# If loop inactive: check focus note for reminders (non-blocking)
set -euo pipefail

MCP_BASE_URL="${MCP_BASE_URL:-http://127.0.0.1:51423}"
STATE_FILE=".claude/slashnote-loop.local.md"

# --- Helper: read JSON value from state file ---
state_get() {
  local key="$1"
  grep "\"$key\"" "$STATE_FILE" 2>/dev/null | sed "s/.*\"$key\": *//;s/,$//" | tr -d ' "' || echo ""
}

state_get_array() {
  local key="$1"
  grep "\"$key\"" "$STATE_FILE" 2>/dev/null | sed "s/.*\"$key\": *\[//;s/\].*//" | tr -d ' ' || echo ""
}

# --- No state file → exit normally ---
if [ ! -f "$STATE_FILE" ]; then
  # Check for focus note with pending items (non-blocking reminder)
  focus_search=$(curl -s -f --connect-timeout 2 "$MCP_BASE_URL/notes/search?q=Focus&limit=1" 2>/dev/null) || true
  if [ -n "$focus_search" ] && echo "$focus_search" | grep -q '"checkboxStats"'; then
    total=$(echo "$focus_search" | grep -o '"total":[0-9]*' | head -1 | grep -o '[0-9]*' || echo "0")
    done_count=$(echo "$focus_search" | grep -o '"done":[0-9]*' | head -1 | grep -o '[0-9]*' || echo "0")
    if [ "$total" -gt 0 ] && [ "$done_count" -lt "$total" ]; then
      remaining=$((total - done_count))
      echo "{\"systemMessage\":\"[SlashNote] Reminder: $remaining pending tasks in Focus note\"}"
    fi
  fi
  exit 0
fi

# --- Read state ---
active=$(state_get "active")
note_id=$(state_get "note_id")
current_task=$(state_get "current_task")
iteration=$(state_get "iteration")
max_iterations=$(state_get "max_iterations")

# Default values
current_task=${current_task:-0}
iteration=${iteration:-1}
max_iterations=${max_iterations:-30}

# --- Loop not active → exit normally ---
if [ "$active" != "true" ]; then
  exit 0
fi

# --- Safety: max iterations ---
if [ "$iteration" -ge "$max_iterations" ]; then
  # Deactivate loop and get task counts
  task_counts=$(python3 -c "
import json
with open('$STATE_FILE', 'r') as f: state = json.load(f)
state['active'] = False
state['paused_reason'] = 'max_iterations_reached'
with open('$STATE_FILE', 'w') as f: json.dump(state, f, indent=2)
tasks = state.get('tasks', [])
completed = state.get('completed_tasks', [])
blocked = state.get('blocked_tasks', [])
print(f'{len(completed)} {len(blocked)} {len(tasks)}')
" 2>/dev/null) || task_counts="0 0 0"
  read tc_completed tc_blocked tc_total <<< "$task_counts"

  # Notify app that schedule is completed
  if [ -n "$note_id" ]; then
    curl -s -f --connect-timeout 3 -X POST "$MCP_BASE_URL/notes/$note_id/schedule/complete" \
      -H "Content-Type: application/json" \
      -d "{\"tasksCompleted\": $tc_completed, \"tasksBlocked\": $tc_blocked, \"totalTasks\": $tc_total, \"message\": \"Stopped: max iterations ($max_iterations) reached\"}" \
      2>/dev/null || true
  fi

  echo "{\"systemMessage\":\"[SlashNote] Task loop stopped: max iterations ($max_iterations) reached. Use /focus --loop to restart.\"}"
  exit 0
fi

# --- Get task list from state ---
tasks_json=$(python3 -c "
import json
with open('$STATE_FILE', 'r') as f: state = json.load(f)
tasks = state.get('tasks', [])
completed = state.get('completed_tasks', [])
blocked = state.get('blocked_tasks', [])
current = state.get('current_task', 0)

# Find next uncompleted, unblocked task
next_task = None
for i in range(len(tasks)):
    if i not in completed and i not in blocked:
        next_task = i
        break

if next_task is None:
    print(json.dumps({'done': True, 'total': len(tasks), 'completed': len(completed), 'blocked': len(blocked)}))
else:
    print(json.dumps({'done': False, 'task_index': next_task, 'task_text': tasks[next_task], 'total': len(tasks), 'completed': len(completed), 'remaining': len(tasks) - len(completed) - len(blocked)}))
" 2>/dev/null) || tasks_json='{"done":true}'

is_done=$(echo "$tasks_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('done', True))")

# --- All tasks done → cleanup and exit ---
if [ "$is_done" = "True" ]; then
  total=$(echo "$tasks_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('total', 0))")
  completed_count=$(echo "$tasks_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('completed', 0))")
  blocked_count=$(echo "$tasks_json" | python3 -c "import json,sys; print(json.load(sys.stdin).get('blocked', 0))")

  # Deactivate
  python3 -c "
import json
with open('$STATE_FILE', 'r') as f: state = json.load(f)
state['active'] = False
state['completed_at'] = '$(date -u +%Y-%m-%dT%H:%M:%SZ)'
with open('$STATE_FILE', 'w') as f: json.dump(state, f, indent=2)
"

  # Notify app that schedule is completed
  if [ -n "$note_id" ]; then
    curl -s -f --connect-timeout 3 -X POST "$MCP_BASE_URL/notes/$note_id/schedule/complete" \
      -H "Content-Type: application/json" \
      -d "{\"tasksCompleted\": $completed_count, \"tasksBlocked\": $blocked_count, \"totalTasks\": $total, \"message\": \"All tasks complete\"}" \
      2>/dev/null || true
  fi

  echo "{\"systemMessage\":\"[SlashNote] All tasks complete! $completed_count/$total done, $blocked_count blocked.\"}"
  exit 0
fi

# --- Next task available → block exit and instruct ---
task_index=$(echo "$tasks_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['task_index'])")
task_text=$(echo "$tasks_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['task_text'])")
remaining=$(echo "$tasks_json" | python3 -c "import json,sys; print(json.load(sys.stdin)['remaining'])")

# Increment iteration in state
python3 -c "
import json
with open('$STATE_FILE', 'r') as f: state = json.load(f)
state['current_task'] = $task_index
state['iteration'] = state.get('iteration', 0) + 1
with open('$STATE_FILE', 'w') as f: json.dump(state, f, indent=2)
"

# Mark task in progress in SlashNote
if [ -n "$note_id" ]; then
  curl -s -f --connect-timeout 3 -X POST "$MCP_BASE_URL/notes/$note_id/toggle" \
    -H "Content-Type: application/json" \
    -d "{\"checkboxIndex\": $task_index, \"state\": \"inProgress\"}" \
    2>/dev/null || true
fi

# Block exit with next task instruction
cat <<EOF
{"decision":"block","reason":"[SlashNote Loop] Task $((task_index + 1))/$((task_index + remaining)): $task_text\n\nExecute this task now. When done, mark it complete with TaskUpdate. $remaining tasks remaining.\nTo pause: /pause | To skip: /pause skip | To stop: /pause stop"}
EOF
