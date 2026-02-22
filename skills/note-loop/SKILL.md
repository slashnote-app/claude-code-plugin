---
name: note-loop
description: Task execution loop — run, schedule, pause, skip, stop, and manage automated task loops
allowed-tools:
  - mcp__slashnote__create_note
  - mcp__slashnote__list_notes
  - mcp__slashnote__read_note
  - mcp__slashnote__update_note
  - mcp__slashnote__search_notes
  - mcp__slashnote__toggle_checkbox
  - mcp__slashnote__show_note
  - mcp__slashnote__reorder_checkboxes
  - mcp__slashnote__start_note_loop
  - mcp__slashnote__update_note_loop
  - mcp__slashnote__complete_note_loop
  - mcp__slashnote__cancel_note_loop
  - mcp__slashnote__list_note_loops
  - Bash
  - Read
  - Write
  - Edit
  - TaskCreate
  - TaskUpdate
  - TaskList
---

# /note-loop — Task Execution Loop

Run, schedule, pause, and manage automated task execution loops with SlashNote as the visual dashboard.

## Usage

```
/note-loop Task1, Task2, Task3           # Loop in current session (new tasks)
/note-loop <uuid>                        # Loop from existing note
/note-loop                               # Resume from existing note
/note-loop <uuid> --new-session          # Schedule in new session (asks for time)
/note-loop <uuid> --new-session 2h       # Schedule in new session in 2 hours
/note-loop list                          # List active loops
/note-loop cancel <uuid>                 # Cancel a scheduled loop
/note-loop pause                         # Immediate pause
/note-loop pause after                   # Pause after current task
/note-loop skip                          # Skip current task
/note-loop skip <reason>                 # Skip with reason
/note-loop stop                          # Full stop
/note-loop stop <reason>                 # Stop with reason
```

## Input Detection

| Input | Action |
|-------|--------|
| Text with tasks | Create note + loop in current session |
| UUID pattern (8-4-4-4-12 hex) | Loop from existing note |
| UUID + `--new-session` | Schedule in new session |
| UUID + `--new-session <time>` | Schedule with delay |
| `list` | `list_note_loops()` |
| `cancel <uuid>` | `cancel_note_loop(note_id)` |
| `pause` | Immediate pause (state file: active=false) |
| `pause after` | Graceful pause (pause_after_current: true) |
| `skip` / `skip <reason>` | Skip current task, continue with next |
| `stop` / `stop <reason>` | Full stop + `complete_note_loop()` |
| No arguments | Resume from existing note |

---

## Mode: Current Session (New Tasks)

Start a loop immediately in the current Claude Code session.

### Step 1: Create/update note

1. Parse tasks from input (comma-separated, numbered, or `- ` list)
2. Search for existing note-loop note, update or create:

```markdown
# /*n*ote-loop

- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
```

- Color: **green**, Pinned: **true**

### Step 2: Start loop

1. Call `mcp__slashnote__start_note_loop` with:
   - `note_id`: the note UUID
   - `directory`: current working directory
   - No time parameters (current session mode)
2. This creates a **Running** block on the note

### Step 3: State file + execute

(See "Loop Setup" section below)

## Mode: From Existing Note (UUID)

Use an existing SlashNote as the task list:

1. Read the note via `mcp__slashnote__read_note` with the provided UUID
2. Extract all **unchecked** checkboxes (`- [ ]`) as tasks
3. Skip already completed (`- [x]`) and in-progress (`- [/]`) items
4. If note has no unchecked checkboxes -> inform user, do not start loop
5. Show the note via `mcp__slashnote__show_note`
6. Call `mcp__slashnote__start_note_loop` with `note_id` and `directory` (no time)
7. Proceed to "Loop Setup"

**Note:** When using an existing note, do NOT change its color or content. Use it as-is.

## Mode: New Session (`--new-session`)

Schedule the loop to run in a new Terminal session:

1. Parse delay from input (e.g., `2h`, `30m`, `at 18:00`). If `--new-session` without time, ask user.
2. Read the note to verify it exists and has tasks
3. Call `mcp__slashnote__start_note_loop` with:
   - `note_id`: the note UUID
   - `directory`: current working directory
   - `delay_minutes` or `fire_at`: parsed time
   - `permission_mode`: `bypassPermissions` (default), or `plan` / `acceptEdits` if specified
4. This creates a **Scheduled** block on the note
5. Confirm with fire time, countdown, and permission mode

### Duration Parsing

| Format | Example | Minutes |
|--------|---------|---------|
| `Xm` | `30m` | 30 |
| `Xh` | `2h` | 120 |
| `Xh Ym` | `1h 30m` | 90 |
| `X minutes` | `45 minutes` | 45 |
| `X hours` | `2 hours` | 120 |

### Time Parsing

| Format | Example |
|--------|---------|
| `HH:MM` | `18:00` |
| `H:MM AM/PM` | `6:00 PM` |

When parsing `at <time>`:
- If the time is in the past today, assume tomorrow
- Convert to ISO 8601 for the `fire_at` parameter

### Permission Modes

| Flag | Mode | Description |
|------|------|-------------|
| `--plan` | `plan` | Safe: only analysis, no file changes |
| `--edits` | `acceptEdits` | Auto-accept file edits only |
| (default) | `bypassPermissions` | Full autopilot, all actions permitted |

## Mode: Resume (No Arguments)

1. Search for existing note: `mcp__slashnote__search_notes` with query "note-loop"
2. Read the note, extract unchecked checkboxes
3. If no unchecked checkboxes -> "No pending tasks"
4. Otherwise -> start loop (same as "From Existing Note" mode)

---

## Command: `list`

1. Call `mcp__slashnote__list_note_loops`
2. Display table: note ID, status, fire time, permission mode, time remaining
3. If no active loops, inform user

## Command: `cancel <uuid>`

1. Call `mcp__slashnote__cancel_note_loop` with `note_id`
2. Confirm cancellation

## Command: `pause`

Immediately pause the active loop.

1. Read state file `.claude/slashnote-loop.local.md`
2. If no state file or loop not active -> "No active loop"
3. Set `"active": false` in state file
4. Record: `"paused_at": "<ISO timestamp>"`, `"paused_reason": "user_paused"`
5. Toggle current task checkbox back to `unchecked` in SlashNote
6. **Show progress summary** (see format below)
7. Inform: "Loop paused. Use `/note-loop` to resume."

## Command: `pause after`

Graceful pause -- finish current task, then stop.

1. Read state file
2. If no active loop -> inform user
3. Set `"pause_after_current": true` in state file
4. Inform: "Will pause after current task completes."
5. **Do NOT stop the current task** -- let it finish naturally
6. The stop hook will read `pause_after_current` and pause instead of continuing

## Command: `skip` / `skip <reason>`

Skip the current task and move to the next one.

1. Read state file
2. If no active loop -> inform user
3. Add current task to `blocked_tasks` array:
   ```json
   {"index": 2, "reason": "<user reason or 'skipped by user'>"}
   ```
4. Toggle current task checkbox to `unchecked` in SlashNote
5. Find next unblocked, uncompleted task
6. If no more tasks -> deactivate loop, show final summary
7. If tasks remain -> toggle next task to `inProgress`, continue loop
8. Inform: "Skipped: <task>. Next: <next task>"

## Command: `stop` / `stop <reason>`

Completely stop the loop.

1. Read state file
2. If no state file -> "No active loop"
3. Set `"active": false` in state file
4. Record: `"stopped_at": "<ISO timestamp>"`, `"paused_reason": "<user reason or 'user_stopped'>"`
5. Toggle current task checkbox back to `unchecked` in SlashNote
6. Cancel any in-progress internal tasks via TaskUpdate
7. Call `mcp__slashnote__complete_note_loop` with:
   - `note_id`, `tasks_completed`, `tasks_blocked`, `total_tasks`
   - `message`: reason or "Stopped by user"
8. **Show final summary** (see format below)

---

## Loop Setup (shared by current session modes)

### 1. Create state file

Write JSON to `.claude/slashnote-loop.local.md`:

```json
{
  "active": true,
  "note_id": "<uuid>",
  "tasks": ["Task 1", "Task 2", "Task 3"],
  "current_task": 0,
  "completed_tasks": [],
  "blocked_tasks": [],
  "iteration": 0,
  "max_iterations": 30,
  "created_at": "<ISO timestamp>"
}
```

- `tasks` array contains only unchecked items (skip done/in-progress)
- `current_task` is index into `tasks` array
- `max_iterations` scales with task count: `max(30, tasks.length * 3)` -- more tasks get more iterations

### 2. Create internal tasks + start

1. For each task, call `TaskCreate` with descriptive `activeForm` (present continuous)
2. Mark first task as `in_progress` with `TaskUpdate`
3. Toggle first checkbox to `inProgress` in SlashNote
4. **Start working on the first task immediately**

## Loop Mechanics

The Stop hook (`hooks/stop-loop.sh`) handles continuation:
- Claude finishes task -> tries to stop -> hook checks state file
- Tasks remain -> hook blocks exit, returns next task instruction
- Claude picks up next task automatically
- Progress updated by hook via HTTP bridge

## Blocked Task Handling

When a task cannot be completed:

1. Mark the checkbox as unchecked (leave it, don't mark done)
2. Add the task index to `blocked_tasks` array in state file with a reason
3. Update state file: `"blocked_tasks": [{"index": 2, "reason": "API not available"}]`
4. Mark internal task as blocked (don't complete it)
5. **Move to the next task** -- don't stop the loop
6. At loop end, blocked tasks remain unchecked in the note for manual follow-up

## Loop Completion

When all tasks are done (or loop stops due to max iterations), the stop hook automatically:
1. Deactivates the state file
2. Calls `complete_note_loop` MCP endpoint to update the note's loop block with a summary

If the stop hook fails to report completion, call it manually:

```
mcp__slashnote__complete_note_loop(
  note_id: "<uuid>",
  tasks_completed: <count>,
  tasks_blocked: <count>,
  total_tasks: <count>,
  message: "All tasks complete"
)
```

## Safety

- Max iterations scale: `max(30, tasks.length * 3)`
- Each task gets max 3 attempts before marked as blocked
- `/note-loop pause` or `/note-loop stop` stops the loop at any time
- If state file is corrupted -> start fresh, don't crash

---

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

Resume: /note-loop
```

### Format Rules

- **Percentage**: `round(completed / total * 100)`
- **Done** section: only show if there are completed tasks
- **Skipped** section: only show if there are blocked/skipped tasks -- include reason if recorded
- **Remaining** section: mark current task with `← current` and `→` prefix
- **Resume** line: only show on pause (not on stop)
- Keep it compact -- task names only, no extra decoration

---

## Rules

- Always search for existing note-loop note first -- never create duplicates
- UUID input always starts a loop from that note
- No arguments -> resume from existing note-loop note's checkboxes
- State file path: `.claude/slashnote-loop.local.md` relative to cwd
- Never modify the state file format -- hooks depend on it
- Default permission mode for new sessions: `bypassPermissions`
- Only one schedule per note -- setting a new one replaces the old
- Use `$PWD` as default directory

## Examples

**New task loop:**
```
/note-loop Write tests, Implement feature, Update docs
```
-> Green pinned note, Running block, loop starts immediately

**Loop from existing note:**
```
/note-loop A550DE30-9B73-4CE5-A138-38F848471329
```
-> Reads note, extracts unchecked checkboxes, Running block, starts loop

**Schedule for later:**
```
/note-loop A550DE30-9B73-4CE5-A138-38F848471329 --new-session 2h
```
-> Scheduled block on note, fires in 2 hours with bypassPermissions

**Resume:**
```
/note-loop
```
-> Finds existing note-loop note, resumes from unchecked items

**List active loops:**
```
/note-loop list
```
-> Shows all active/scheduled loops

**Cancel scheduled loop:**
```
/note-loop cancel A550DE30-9B73-4CE5-A138-38F848471329
```
-> Cancels the scheduled loop

**Pause immediately:**
```
/note-loop pause
```
-> Pauses loop, shows progress summary

**Pause after current task:**
```
/note-loop pause after
```
-> Finishes current task, then pauses

**Skip a task:**
```
/note-loop skip API is down
```
-> Skips current task with reason, moves to next

**Stop loop:**
```
/note-loop stop finished for today
```
-> Stops loop, calls complete_note_loop, shows final summary
