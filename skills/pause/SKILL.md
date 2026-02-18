---
name: pause
description: Pause, skip, or stop the SlashNote task execution loop
allowed-tools:
  - mcp__slashnote__toggle_checkbox
  - mcp__slashnote__update_note
  - mcp__slashnote__read_note
  - mcp__slashnote__show_note
  - Read
  - Write
  - Edit
  - TaskUpdate
  - TaskList
---

# /pause — Pause/Skip/Stop Task Loop

Control the SlashNote task execution loop.

## Usage

```
/pause              # Pause loop (can resume with /focus --loop)
/pause skip         # Skip current task, continue with next
/pause stop         # Completely stop loop
```

## Subcommands

### `/pause` (no args) — Pause

1. Read state file `.claude/slashnote-loop.local.md`
2. If no state file or loop not active → inform user "No active loop"
3. Set `"active": false` and `"paused_reason": "user_paused"` in state file
4. Toggle current task checkbox back to `unchecked` in SlashNote
5. Inform user: "Loop paused. Use `/focus --loop` to resume."

### `/pause skip` — Skip Current Task

1. Read state file
2. If no active loop → inform user
3. Add current task index to `blocked_tasks` array
4. Toggle current task checkbox to `unchecked` in SlashNote
5. Increment `current_task` to next unblocked, uncompleted task
6. If no more tasks → deactivate loop, inform user "All tasks done or skipped"
7. If tasks remain → toggle next task to `inProgress`, continue loop
8. Inform user: "Skipped task N. Now on task N+1: <text>"

### `/pause stop` — Full Stop

1. Read state file
2. If no state file → inform user "No active loop"
3. Set `"active": false` and `"paused_reason": "user_stopped"` in state file
4. Toggle current task checkbox back to `unchecked` in SlashNote
5. Cancel any in-progress internal tasks via TaskUpdate
6. Inform user: "Loop stopped. Progress saved in SlashNote."
7. Do NOT delete the state file (preserves progress for potential resume)

## State File

Path: `.claude/slashnote-loop.local.md` (relative to working directory)
Format: JSON

## Rules

- Always read state file first — never assume state
- If state file doesn't exist, inform user there's no active loop
- Never delete the SlashNote note — only modify loop state
- After pause/stop, the focus note remains pinned with current progress visible
- Skip only skips the current task — loop continues with the next one
- Use `TaskList` and `TaskUpdate` to sync internal Claude Code tasks with the loop state
