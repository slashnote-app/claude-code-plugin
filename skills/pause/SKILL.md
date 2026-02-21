---
name: pause
description: Pause, skip, or stop the SlashNote task execution loop
allowed-tools:
  - mcp__slashnote__toggle_checkbox
  - mcp__slashnote__update_note
  - mcp__slashnote__read_note
  - mcp__slashnote__show_note
  - mcp__slashnote__complete_schedule
  - Read
  - Write
  - Edit
  - TaskUpdate
  - TaskList
---

# /pause — Loop Control

Control the SlashNote task execution loop: pause, skip, or stop.

## Usage

```
/pause                    # Pause loop immediately + progress summary
/pause after              # Finish current task, then pause (graceful)
/pause skip               # Skip current task, continue with next
/pause skip <reason>      # Skip with reason recorded
/pause stop               # Completely stop loop + final summary
/pause stop <reason>      # Stop with reason recorded
```

## Subcommands

### `/pause` — Immediate Pause

1. Read state file `.claude/slashnote-loop.local.md`
2. If no state file or loop not active → inform user "No active loop"
3. Set `"active": false` in state file
4. Record: `"paused_at": "<ISO timestamp>"`, `"paused_reason": "user_paused"`
5. Toggle current task checkbox back to `unchecked` in SlashNote
6. **Show progress summary** (see format below)
7. Inform: "Loop paused. Use `/focus --loop` to resume."

### `/pause after` — Graceful Pause

1. Read state file
2. If no active loop → inform user
3. Set `"pause_after_current": true` in state file
4. Inform: "Will pause after current task completes."
5. **Do NOT stop the current task** — let it finish naturally
6. The stop hook will read `pause_after_current` and pause instead of continuing

This is the recommended way to pause — avoids interrupting work mid-task.

### `/pause skip` — Skip Current Task

1. Read state file
2. If no active loop → inform user
3. Add current task to `blocked_tasks` array:
   ```json
   {"index": 2, "reason": "<user reason or 'skipped by user'>"}
   ```
4. Toggle current task checkbox to `unchecked` in SlashNote
5. Find next unblocked, uncompleted task
6. If no more tasks → deactivate loop, show final summary
7. If tasks remain → toggle next task to `inProgress`, continue loop
8. Inform: "Skipped: <task>. Next: <next task>"

### `/pause stop` — Full Stop

1. Read state file
2. If no state file → inform user "No active loop"
3. Set `"active": false` in state file
4. Record: `"stopped_at": "<ISO timestamp>"`, `"paused_reason": "<user reason or 'user_stopped'>"`
5. Toggle current task checkbox back to `unchecked` in SlashNote
6. Cancel any in-progress internal tasks via TaskUpdate
7. **Show final summary** (see format below)
8. Call `mcp__slashnote__complete_schedule` with note_id, task counts, and message (e.g. "Stopped by user")
9. Do NOT delete state file (preserves progress for potential resume)

## Progress Summary Format

Always show when pausing or stopping:

```
Loop: N/M tasks (XX%)

Done:
  ✓ Task A
  ✓ Task B

Skipped:
  ⊘ Task C — <reason>

Remaining:
  → Task D ← current
    Task E
    Task F

Resume: /focus --loop
```

### Format Rules

- **Percentage**: `round(completed / total * 100)`
- **Done** section: only show if there are completed tasks
- **Skipped** section: only show if there are blocked/skipped tasks — include reason if recorded
- **Remaining** section: mark current task with `← current` and `→` prefix
- **Resume** line: only show on pause (not on stop)
- Keep it compact — task names only, no extra decoration

## State File

Path: `.claude/slashnote-loop.local.md` (relative to working directory)
Format: JSON

### Fields added by /pause

| Field | Set by | Purpose |
|-------|--------|---------|
| `active` | pause/stop | `false` when paused/stopped |
| `paused_at` | pause/stop | ISO timestamp of when paused |
| `paused_reason` | pause/stop | Why the loop was paused |
| `pause_after_current` | pause after | Flag for graceful pause |

## Rules

- Always read state file first — never assume state
- If state file doesn't exist → "No active loop"
- Never delete the SlashNote note — only modify loop state
- Focus note remains pinned with current progress visible
- Skip only skips one task — loop continues with next
- Progress summary is mandatory for all subcommands
- Use `TaskList` and `TaskUpdate` to sync internal tasks
- `/pause after` is non-destructive — it sets a flag, not interrupts
