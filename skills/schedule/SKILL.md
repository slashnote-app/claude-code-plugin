---
name: schedule
description: Schedule a Focus Loop to run at a specific time — delayed auto-execution of note tasks
allowed-tools:
  - mcp__slashnote__schedule_focus_loop
  - mcp__slashnote__cancel_schedule
  - mcp__slashnote__list_schedules
  - mcp__slashnote__list_notes
  - mcp__slashnote__read_note
  - mcp__slashnote__search_notes
---

# /schedule — Scheduled Focus Loop

Schedule a Focus Loop to run at a specific time. When the timer fires, SlashNote opens a Terminal window and launches `claude` with `/focus` on the specified note.

## Usage

```
/schedule <note-uuid> in 2h              # Fire in 2 hours
/schedule <note-uuid> at 18:00           # Fire at specific time
/schedule <note-uuid> in 30m --plan      # Safe mode (analysis only)
/schedule <note-uuid> in 1h --bypass     # Dangerous: full autopilot
/schedule cancel <note-uuid>             # Cancel a schedule
/schedule list                           # List active schedules
```

## Input Detection

| Input | Action |
|-------|--------|
| `cancel <uuid>` | Cancel schedule for note |
| `list` | List all active schedules |
| `<uuid> in <duration>` | Schedule with relative time |
| `<uuid> at <time>` | Schedule with absolute time |
| `<uuid>` (no time) | Default: schedule in 60 minutes |

## Duration Parsing

| Format | Example | Minutes |
|--------|---------|---------|
| `Xm` | `30m` | 30 |
| `Xh` | `2h` | 120 |
| `Xh Ym` | `1h 30m` | 90 |
| `X minutes` | `45 minutes` | 45 |
| `X hours` | `2 hours` | 120 |

## Time Parsing

| Format | Example |
|--------|---------|
| `HH:MM` | `18:00` |
| `H:MM AM/PM` | `6:00 PM` |

When parsing `at <time>`:
- If the time is in the past today, assume tomorrow
- Convert to ISO 8601 for the `fire_at` parameter

## Permission Modes

| Flag | Mode | Description |
|------|------|-------------|
| `--plan` | `plan` | Safe: only analysis, no file changes |
| (default) | `acceptEdits` | Recommended: auto-accept file edits |
| `--bypass` | `bypassPermissions` | Dangerous: full autopilot, no confirmations |

## Behavior

### Schedule (default)

1. Parse input to extract: note UUID, time, permission mode
2. If no UUID provided, search for the most recent focus note via `mcp__slashnote__search_notes`
3. Read the note via `mcp__slashnote__read_note` to verify it exists and has tasks
4. Determine the working directory:
   - Use current working directory (`$PWD`) as default
5. Call `mcp__slashnote__schedule_focus_loop` with:
   - `note_id`: the note UUID
   - `directory`: working directory
   - `delay_minutes` or `fire_at`: parsed time
   - `permission_mode`: parsed mode (default: `acceptEdits`)
6. Confirm with: schedule details, fire time, countdown, permission mode

### Cancel

1. Parse note UUID from input
2. Call `mcp__slashnote__cancel_schedule` with `note_id`
3. Confirm cancellation

### List

1. Call `mcp__slashnote__list_schedules`
2. Display table with: note ID, fire time, directory, permission mode, time remaining
3. If no active schedules, inform the user

## Response Format

After scheduling, show:
```
Scheduled Focus Loop:
  Note: <first line of note content>
  Fire at: 18:00 (in 2h 15m)
  Directory: ~/project
  Permission: acceptEdits
```

After cancelling:
```
Schedule cancelled for note <uuid short>.
```

## Rules

- Always verify the note exists before scheduling
- Default delay is 60 minutes if no time specified
- Default permission mode is `acceptEdits`
- Warn user when using `--bypass` (bypassPermissions) — it's dangerous
- Only one schedule per note — setting a new schedule replaces the old one
- Use `$PWD` as default directory
- Show the countdown in human-readable format (e.g., "in 2h 15m")

## Examples

**Schedule in 2 hours:**
```
/schedule A550DE30-9B73-4CE5-A138-38F848471329 in 2h
```
-> Schedules focus loop for note, fires in 120 minutes with acceptEdits mode

**Schedule at specific time in safe mode:**
```
/schedule A550DE30-9B73-4CE5-A138-38F848471329 at 18:00 --plan
```
-> Schedules for 18:00 with plan (read-only) mode

**Cancel:**
```
/schedule cancel A550DE30-9B73-4CE5-A138-38F848471329
```
-> Cancels the schedule

**List active:**
```
/schedule list
```
-> Shows all active schedules with fire times
