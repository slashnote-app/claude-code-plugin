---
name: focus
description: Set current focus task (pinned note) or start auto-execute task loop
allowed-tools:
  - mcp__slashnote__create_note
  - mcp__slashnote__list_notes
  - mcp__slashnote__read_note
  - mcp__slashnote__update_note
  - mcp__slashnote__search_notes
  - mcp__slashnote__toggle_checkbox
  - mcp__slashnote__show_note
  - mcp__slashnote__reorder_checkboxes
  - mcp__slashnote__schedule_focus_loop
  - mcp__slashnote__complete_schedule
  - Bash
  - Read
  - Write
  - Edit
  - TaskCreate
  - TaskUpdate
  - TaskList
---

# /focus — Session Focus + Task Execution Loop

Set your current focus or start an automated task execution loop.

## Usage

```
/focus <task description>              # Mode A: simple focus
/focus Task1, Task2, Task3 --loop      # Mode B: auto-execute loop with new tasks
/focus <note-uuid> --loop              # Mode C: loop from existing note's checkboxes
/focus <note-uuid>                     # Mode C: UUID always implies loop
/focus --loop                          # Resume loop from existing focus note
/focus <note-uuid> --schedule          # Mode D: schedule loop for later execution
/focus <note-uuid> --schedule 2h       # Mode D: schedule with delay
```

## Input Detection

| Input | Mode |
|-------|------|
| UUID pattern (8-4-4-4-12 hex) | Mode C: use existing note |
| Text with `--loop` flag | Mode B: create new loop |
| Text without `--loop` | Mode A: simple focus |
| Only `--loop` (no text) | Resume: find existing focus note |
| UUID + `--schedule` | Mode D: schedule loop for later |

## Mode A — Simple Focus (no `--loop`)

1. Search for existing focus note: `mcp__slashnote__search_notes` with query "Focus"
2. If found: update content via `mcp__slashnote__update_note`
3. If not found: create new pinned note via `mcp__slashnote__create_note`
4. Format:

```markdown
# Focus

- [ ] <task description>
```

- Color: **green**, Pinned: **true**
- Multiple items (comma-separated or list) → convert each to checkbox

## Mode B — Auto-Execute Loop (new tasks + `--loop`)

### Step 1: Create/update focus note

1. Parse tasks from input (comma-separated, numbered, or `- ` list)
2. Search for existing focus note, update or create:

```markdown
# Focus

- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
```

- Color: **green**, Pinned: **true**

### Step 2: Create state file + start

(See "Loop Setup" section below)

## Mode C — Loop from Existing Note (`<uuid>`)

Use an **existing SlashNote** as the task list:

1. Read the note via `mcp__slashnote__read_note` with the provided UUID
2. Extract all **unchecked** checkboxes (`- [ ]`) as tasks
3. Skip already completed (`- [x]`) and in-progress (`- [/]`) items
4. If note has no unchecked checkboxes → inform user, do not start loop
5. Show the note via `mcp__slashnote__show_note`
6. Proceed to "Loop Setup"

**Note:** When using an existing note, do NOT change its color or content. Use it as-is.

## Mode D — Scheduled Loop (`--schedule`)

Schedule the Focus Loop to run later instead of starting immediately:

1. Parse the delay from input (e.g., `2h`, `30m`, `at 18:00`). Default: 60 minutes.
2. Read the note via `mcp__slashnote__read_note` to verify it exists and has tasks
3. Call `mcp__slashnote__schedule_focus_loop` with:
   - `note_id`: the note UUID
   - `directory`: current working directory
   - `delay_minutes`: parsed delay in minutes
   - `permission_mode`: `acceptEdits` (default), or `plan` / `bypassPermissions` if specified
4. Show the note via `mcp__slashnote__show_note`
5. Confirm with fire time and countdown

**Note:** Mode D does NOT start a loop in the current session. It schedules the app to open a Terminal and run `claude /focus <uuid>` at the specified time.

## Loop Setup (shared by Mode B and C)

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
- `max_iterations` scales with task count: `max(30, tasks.length * 3)` — more tasks get more iterations

### 2. Create internal tasks + start

1. For each task, call `TaskCreate` with descriptive `activeForm` (present continuous)
2. Mark first task as `in_progress` with `TaskUpdate`
3. Toggle first checkbox to `inProgress` in SlashNote
4. **Start working on the first task immediately**

### Loop Mechanics

The Stop hook (`hooks/stop-loop.sh`) handles continuation:
- Claude finishes task → tries to stop → hook checks state file
- Tasks remain → hook blocks exit, returns next task instruction
- Claude picks up next task automatically
- Progress updated by hook via HTTP bridge

### Blocked Task Handling

When a task cannot be completed:

1. Mark the checkbox as unchecked (leave it, don't mark done)
2. Add the task index to `blocked_tasks` array in state file with a reason
3. Update state file: `"blocked_tasks": [{"index": 2, "reason": "API not available"}]`
4. Mark internal task as blocked (don't complete it)
5. **Move to the next task** — don't stop the loop
6. At loop end, blocked tasks remain unchecked in the note for manual follow-up

### Loop Completion

When all tasks are done (or loop stops due to max iterations), the stop hook automatically:
1. Deactivates the state file
2. Calls `complete_schedule` MCP endpoint to update the note's schedule block with a summary

If the stop hook fails to report completion, you can also call it manually at the end of the loop:

```
mcp__slashnote__complete_schedule(
  note_id: "<uuid>",
  tasks_completed: <count>,
  tasks_blocked: <count>,
  total_tasks: <count>,
  message: "All tasks complete"  // or reason for stopping
)
```

### Safety

- Max iterations scale: `max(30, tasks.length * 3)`
- Each task gets max 3 attempts before marked as blocked
- `/pause` stops the loop at any time
- If state file is corrupted → start fresh, don't crash

## Rules

- Always search for existing focus note first — never create duplicates
- Mode A does NOT create a state file or start a loop
- `--loop` flag activates the execution loop
- UUID input implies `--loop` (always start loop from existing note)
- `--loop` without tasks → resume from existing focus note's checkboxes
- State file path: `.claude/slashnote-loop.local.md` relative to cwd
- Never modify the state file format — hooks depend on it

## Examples

**Simple focus:**
```
/focus Implement JWT auth
```
→ Green pinned note with single checkbox, no loop

**Task loop (new tasks):**
```
/focus Write tests, Implement feature, Update docs --loop
```
→ Green pinned note, loop starts

**Loop from existing note:**
```
/focus A550DE30-9B73-4CE5-A138-38F848471329
```
→ Reads note, extracts unchecked checkboxes, starts loop on that note

**Resume:**
```
/focus --loop
```
→ Finds existing focus note, resumes from unchecked items

**Schedule for later:**
```
/focus A550DE30-9B73-4CE5-A138-38F848471329 --schedule 2h
```
→ Schedules loop to fire in 2 hours, note gets a countdown timer block
