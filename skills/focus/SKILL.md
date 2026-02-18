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
  - mcp__slashnote__insert_chart
  - mcp__slashnote__update_chart
  - mcp__slashnote__list_charts
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
/focus Task1, Task2, Task3 --loop      # Mode B: auto-execute loop
/focus --loop                          # Resume loop from existing focus note
```

## Mode A — Simple Focus (no `--loop`)

For a single task or when `--loop` flag is absent:

1. Search SlashNote for existing focus note: `mcp__slashnote__search_notes` with query "Focus"
2. If found: update its content with new focus via `mcp__slashnote__update_note`
3. If not found: create new pinned note via `mcp__slashnote__create_note`
4. Format:

```markdown
# Focus

- [ ] <task description>
```

- Color: **green**
- Pinned: **true**
- If input contains multiple items (comma-separated or `- ` list) → convert each to a checkbox
- Only ONE focus note at a time — always search and replace

## Mode B — Auto-Execute Loop (with `--loop`)

For multiple tasks with automatic sequential execution:

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
- Insert a progress chart:
  ```
  chart_type: "progress"
  data_points: [
    {"label": "Done", "value": 0, "color": "green"},
    {"label": "Remaining", "value": <total_tasks>, "color": "gray"}
  ]
  title: "Progress"
  ```

### Step 2: Create state file

Write JSON state to `.claude/slashnote-loop.local.md`:

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

### Step 3: Create internal tasks + start execution

1. For each task, call `TaskCreate` to create an internal Claude Code task
2. Mark the first task as `in_progress` with `TaskUpdate`
3. Toggle first checkbox to `inProgress` in SlashNote
4. **Start working on the first task immediately**
5. When done, mark task completed with `TaskUpdate` → the Stop hook will handle the loop continuation

### Loop Mechanics

The Stop hook (`hooks/stop-loop.sh`) handles the loop:
- When Claude finishes a task and tries to stop → hook checks state file
- If tasks remain → hook blocks exit and returns next task instruction
- Claude picks up the next task automatically
- Progress chart is updated by the hook via HTTP bridge

### Safety

- Max 30 iterations (configurable in state file)
- Each task gets max 3 attempts before being marked as blocked
- `/pause` stops the loop at any time

## Rules

- Always search for existing focus note first — never create duplicates
- Simple focus (Mode A) does NOT create a state file or start a loop
- Only `--loop` flag activates the execution loop
- If `--loop` with a single task → still create loop (just 1 iteration)
- If `--loop` without tasks but existing focus note → resume from existing note's checkboxes
- State file path is always `.claude/slashnote-loop.local.md` relative to current working directory

## Examples

**Simple focus:**
```
/focus Implement JWT auth
```
→ Green pinned note with single checkbox, no loop

**Task loop:**
```
/focus Write tests, Implement feature, Update docs --loop
```
→ Green pinned note with 3 checkboxes + progress chart, loop starts, first task begins

**Resume:**
```
/focus --loop
```
→ Finds existing focus note, reads unchecked tasks, creates state file, starts loop
