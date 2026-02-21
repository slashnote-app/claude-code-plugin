---
name: todo
description: Create a TODO checklist — quick task list capture with smart parsing
allowed-tools:
  - mcp__slashnote__create_note
  - mcp__slashnote__list_notes
  - mcp__slashnote__search_notes
  - mcp__slashnote__update_note
  - mcp__slashnote__read_note
  - mcp__slashnote__reorder_checkboxes
---

# /todo — Quick TODO List

Create a TODO checklist note or append tasks to an existing one. Inspired by Todoist's zero-friction capture.

## Usage

```
/todo <tasks>                    # Create new TODO note
/todo <tasks> --append           # Append to existing TODO note (most recent peach note)
```

## Parsing Rules

Parse the input into individual task items. Support these formats:

| Input Format | Example |
|-------------|---------|
| Comma-separated | `buy milk, review PR, deploy` |
| Dash-separated list | `- buy milk - review PR - deploy` |
| Numbered list | `1. buy milk 2. review PR 3. deploy` |
| Newline-separated | Multi-line input |
| Single item | `review the auth PR` |
| Natural sentence | `I need to fix the login bug and update docs` → split on "and"/"then"/"also" |

### Smart Splitting

When input is a natural sentence (not a list format):
- Split on conjunctions: "and", "then", "also", "plus"
- Only split if result gives 2+ meaningful items (3+ words each)
- If splitting produces items too short or unclear, keep as single item

### Priority Detection

If a task item contains urgency markers, note them inline:

| Marker | Meaning | Format |
|--------|---------|--------|
| `!` at end or "urgent" | High priority | Prepend item with `(!)` |
| `!!` at end or "asap", "critical" | Critical | Prepend item with `(!!)` |
| "today", "now" | Time-sensitive | Prepend item with `(today)` |
| "tomorrow" | Next-day | Prepend item with `(tomorrow)` |

Priority markers are stripped from the original text and shown as prefix. This is lightweight — not a full task manager, just visual hints.

### Context-Aware Title

If all tasks relate to one theme (e.g., all about a feature, all about shopping):
- Auto-generate a title: `# <Theme> TODO`
- Examples: "# Auth Refactor TODO", "# Shopping TODO", "# Release TODO"
- If tasks are unrelated → no title (just checkboxes)

## Behavior

### Create Mode (default)

1. Parse input into task items
2. Detect priority markers
3. Generate context-aware title if applicable
4. Format as checklist:
   ```markdown
   # <Optional Title> TODO

   - [ ] (!) Task 1
   - [ ] Task 2
   - [ ] Task 3
   ```
5. Call `mcp__slashnote__create_note` with:
   - Color: **peach**
   - Pinned: **false**
6. Confirm: "Created TODO with N items"

### Append Mode (`--append`)

1. Search for most recent peach note with checkboxes: `mcp__slashnote__list_notes`
2. If found: `mcp__slashnote__read_note` → append new checkboxes at the end
3. If not found: create new note (same as create mode)
4. Confirm: "Added N items to existing TODO" or "Created new TODO with N items"

## Examples

**Input:** `/todo buy milk, review PR, deploy staging`
**Result:** Peach note:
```
- [ ] Buy milk
- [ ] Review PR
- [ ] Deploy staging
```

**Input:** `/todo fix the login bug and update the docs and write tests`
**Result:** Peach note (smart split on "and"):
```
- [ ] Fix the login bug
- [ ] Update the docs
- [ ] Write tests
```

**Input:** `/todo fix auth crash !!, update error messages, add retry logic !`
**Result:** Peach note with priorities:
```
# Auth TODO

- [ ] (!!) Fix auth crash
- [ ] Update error messages
- [ ] (!) Add retry logic
```

**Input:** `/todo Review auth PR`
**Result:** Peach note:
```
- [ ] Review auth PR
```

**Input:** `/todo add error handling, write tests --append`
**Result:** Appends to most recent peach TODO note

## Formatting

- Capitalize first letter of each task item
- Remove trailing punctuation (periods, commas)
- Remove leading "to " or "need to " from items ("need to fix X" → "Fix X")
- Keep items concise — if an item is > 15 words, it's probably not a single task
- Max 10 items per note — if more, warn user and suggest splitting

## Important

- Always **peach** color — this is the TODO color in SlashNote
- One tool call for create, two for append (read + update)
- Title: auto-generated from context OR for 5+ items, never for 1-2 items
- Do NOT ask for confirmation or additional details
- Keep it fast — parse and create immediately
- Priority is lightweight (visual prefix only) — we're a sticky note, not Todoist

## Schedule Execution

After creating a TODO note, you can schedule automatic execution of all tasks:
- Use `/schedule <note-uuid> in 2h` to auto-execute tasks later
- Use `/focus <note-uuid>` to start executing tasks immediately
- The scheduled loop will open a Terminal and run each task via Claude Code
