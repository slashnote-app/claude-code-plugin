---
name: standup
description: Generate a daily standup summary from git activity, notes, and PRs
allowed-tools:
  - mcp__slashnote__create_note
  - mcp__slashnote__list_notes
  - mcp__slashnote__read_note
  - mcp__slashnote__search_notes
  - Bash
---

# /standup — Daily Standup

Generate a standup report from git commits, SlashNote notes, and PR activity. Replaces previous standup note to keep only the latest.

## Usage

```
/standup                  # Default: since yesterday
/standup --week           # Weekly summary
/standup --notes          # Notes-only mode (no git required)
```

## Behavior

### Step 0: Clean up previous standup

Search for existing standup notes (`mcp__slashnote__search_notes` with "Standup"). If found, the new standup will **replace** the most recent one (via update, not create+delete) to avoid note clutter.

### Step 1: Collect data

**Git + PR data** (skip if `--notes` or not in a git repo):
```bash
echo "COMMITS:" && git log --oneline --since="yesterday" --author="$(git config user.name)" 2>/dev/null && echo "---FILES---" && git diff --stat HEAD~5 --shortstat 2>/dev/null && echo "---PRS---" && gh pr list --author="@me" --state=all --limit=5 --json title,state,updatedAt 2>/dev/null || echo "no-gh"
```
For `--week`: use `--since="1 week ago"` and `HEAD~20`

**SlashNote data** (always collected):
1. `mcp__slashnote__list_notes` — get all notes
2. Read notes with checkboxes to find:
   - Recently completed items (done checkboxes)
   - In-progress items
   - Bug notes (pink)
3. Check focus note for current task
4. Check loop state file for blocked tasks

### Step 2: Generate standup

Create/update a **green** note:

```markdown
# Standup <date>
<N commits, M files changed, K PRs>

## Done
- <grouped commit summaries>
- <completed checkbox items>
- <merged PRs>

## In Progress
- <in-progress checkbox items>
- <open PRs>

## Today
- <unchecked focus/todo items — what's planned next>

## Blockers
- <blocked tasks>
- <recent bug notes>
```

### Section Details

#### Metrics Line
Right below the title, one line of activity metrics:
- `5 commits, 12 files changed, 2 PRs` (git mode)
- `3 tasks completed, 2 in progress` (notes mode)
- Omit if no meaningful metrics

#### "Done" Section
- Group related commits by conventional commit prefix (see table below)
- Include completed checkbox items from notes
- Include merged PRs: `PR: "Title" (merged)`
- Max 10 items — summarize if more

#### "In Progress" Section
- In-progress checkboxes from notes
- Open/draft PRs: `PR: "Title" (open, N reviews)`
- Current focus task
- Max 7 items

#### "Today" Section
- Source from unchecked checkboxes in focus/todo notes
- This is the **plan**, not history
- If no planned items → omit section
- Max 5 items

#### "Blockers" Section
- Blocked tasks from loop state file
- Recent bug notes (pink, created in last 24h)
- **Omit entirely** if no blockers — don't show empty section

### Non-Git Mode (`--notes` or no git repo)

When git is not available or `--notes` flag used:

```markdown
# Standup <date>
<N tasks completed, M in progress>

## Done
- <completed checkbox items from notes>

## In Progress
- <in-progress items from notes>

## Today
- <unchecked items from focus/todo notes>
```

- No git/PR calls at all
- Works everywhere — not just in git repos

## Commit Grouping

| Prefix | Group Label |
|--------|-------------|
| `fix:`, `bugfix:` | Bug fixes |
| `feat:`, `feature:` | Features |
| `refactor:` | Refactoring |
| `docs:` | Documentation |
| `test:` | Tests |
| `chore:`, `ci:` | Maintenance |
| No prefix | Group by modified area |

Example: 3 commits with `feat:` prefix → single line: "Features: animated AI loader, heading placeholders, notes limit removal"

## Rules

- **One Bash call** max for git+PR+files data (combined command)
- **Replace** previous standup note, don't create new ones daily
- Group related commits — never list individual commits raw
- Concise: one line per item, no full commit messages
- Skip merge commits and CI-related commits
- Date: human-readable ("Feb 19, 2026")
- PR activity: `PR: "title" (merged/open/draft)`
- If no commits → skip git items in "Done" (still show note completions)
- If no in-progress → omit section or show "Clear — ready for new tasks"
- If no blockers → omit "Blockers" entirely
- Max items per section: Done=10, In Progress=7, Today=5, Blockers=5

## Examples

**Git + Notes:**
```markdown
# Standup Feb 19, 2026
5 commits, 12 files changed, 2 PRs

## Done
- Features: animated AI loader, heading placeholders
- Bug fixes: removed debug Pro override, restored Pro gates
- PR: "Add voice input support" (merged)
- Completed plugin skills research

## In Progress
- Skills plugin deep dive (9/12 done)
- PR: "Refactor NoteStorage" (open, 2 reviews)

## Today
- Finish /standup improvements
- Start /wrapup deep dive
- Review open PR feedback

## Blockers
- Bug: race condition in WebSocket handler
```

**Notes-only (--notes):**
```markdown
# Standup Feb 19, 2026
3 tasks completed, 2 in progress

## Done
- Improved /note auto-detection
- Created /context skill
- Improved /find search UX

## In Progress
- /standup deep dive
- Plugin integration tests

## Today
- Finish /wrapup improvements
- Start /context deep dive
```
