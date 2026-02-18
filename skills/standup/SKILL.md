---
name: standup
description: Generate a daily standup summary from git activity and SlashNote notes
allowed-tools:
  - mcp__slashnote__create_note
  - mcp__slashnote__list_notes
  - mcp__slashnote__read_note
  - mcp__slashnote__search_notes
  - Bash
---

# /standup — Daily Standup Generator

Generate a standup report from git commits and SlashNote notes.

## Usage

```
/standup                  # Default: since yesterday
/standup --week           # Weekly summary
```

## Behavior

### Step 1: Collect git data

Run via Bash:
```bash
git log --oneline --since="yesterday" --author="$(git config user.name)" 2>/dev/null
```
For `--week`: use `--since="1 week ago"`

### Step 2: Collect SlashNote data

1. `mcp__slashnote__list_notes` — get all notes
2. For notes with checkboxes, read them to find:
   - Recently completed items (done checkboxes)
   - In-progress items
   - Bug notes (pink)

### Step 3: Generate standup

Create a green note with:

```markdown
# Standup <date>

## Done
- <grouped commit summaries>
- <completed checkbox items from notes>

## Today
- <in-progress items from notes>
- <unchecked items from focus note>

## Blockers
- <any blocked tasks from loop state>
- <bug notes created recently>
```

### Step 4: Create note

Call `mcp__slashnote__create_note`:
- Color: **green**
- Pinned: false

## Rules

- Group related commits together (e.g., all "fix:" commits → one "Bug fixes" item)
- Use concise language — one line per item, no full commit messages
- If no git commits found → skip "Done" or note "No commits since yesterday"
- If no in-progress items → "Today" section says "Planning session"
- If no blockers → omit "Blockers" section entirely
- Don't include merge commits or CI-related commits
- Maximum 10 items per section — summarize if more
- Date format: "Feb 18, 2026" (human readable)

## Commit Grouping

| Prefix | Group |
|--------|-------|
| `fix:`, `bugfix:` | Bug fixes |
| `feat:`, `feature:` | New features |
| `refactor:` | Refactoring |
| `docs:` | Documentation |
| `test:` | Testing |
| `chore:`, `ci:` | Maintenance |
| No prefix | Group by related file/area |
