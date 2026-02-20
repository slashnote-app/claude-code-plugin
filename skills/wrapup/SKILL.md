---
name: wrapup
description: Generate a session summary with handoff notes for next session
allowed-tools:
  - mcp__slashnote__create_note
  - mcp__slashnote__list_notes
  - mcp__slashnote__read_note
  - mcp__slashnote__search_notes
  - mcp__slashnote__update_note
  - Bash
  - Read
---

# /wrapup — Session Summary

Generate an end-of-session summary with handoff notes. Replaces previous wrapup to keep only the latest.

## Usage

```
/wrapup                       # Full analysis (git + notes + conversation)
/wrapup --notes               # Notes-only mode (no git required)
/wrapup <additional context>  # Add extra context to the summary
```

## Behavior

### Step 0: Replace previous wrapup

Search for existing wrapup notes (`mcp__slashnote__search_notes` with "Wrapup"). If found, **replace** the most recent one to avoid clutter.

### Step 1: Collect data

**Git data** (skip if `--notes` or not in a git repo):
```bash
echo "LOG:" && git log --oneline -10 2>/dev/null && echo "---DIFF---" && git diff --stat 2>/dev/null && echo "---STAGED---" && git diff --staged --stat 2>/dev/null && echo "---BRANCH---" && git rev-parse --abbrev-ref HEAD 2>/dev/null
```

**SlashNote data** (always collected):
1. `mcp__slashnote__list_notes` — overview of all notes
2. Read focus note if exists → task progress
3. Read loop state file if exists → blocked/remaining tasks
4. Read recent decision notes (green) → decisions made this session
5. Read recent bug notes (pink) → known issues

**Conversation context** (always available):
- Tasks discussed and completed
- Decisions made
- Issues encountered
- Files modified

### Step 2: Generate summary

#### Full Mode (git + notes)

```markdown
# Wrapup <date>

## Done
- <completed work — from git commits + note checkboxes>
- <loop progress if applicable: "Focus loop: N/M tasks">

## Decisions
- <decisions made this session — from /decide notes>

## Changed
- <file areas modified — from git diff --stat>
- <uncommitted changes warning if any>

## Open
- <uncompleted tasks, open bugs>
- <uncommitted/unstaged changes>

## Risks
- <potential issues for next session>

## Next
- <exact next steps with file:line references>
- <pending reviews or PRs>
```

#### Notes-Only Mode (`--notes`)

```markdown
# Wrapup <date>

## Done
- <completed items from note checkboxes>
- <decisions made (from decision notes)>

## Open
- <in-progress items from notes>
- <unchecked focus items>

## Next
- <specific next steps based on remaining work>
```

### Step 3: Create note

- Color: **green**
- Pinned: **false**
- **Replace** previous wrapup if exists

## Section Details

### "Done" — What was accomplished
- Group related commits (same pattern as /standup)
- Include completed checkbox items from notes
- Include loop progress: "Focus loop: 9/12 tasks completed"
- This is a record — only things actually done

### "Decisions" — Choices made this session
- Source from green decision notes created during this session
- Format: one-liner per decision (title from note)
- **Omit** if no decisions were made
- Cross-reference with git to see if decisions were implemented

### "Changed" — Files and areas modified
- From `git diff --stat` (both staged and unstaged)
- Group by directory/module if many files
- Flag uncommitted changes: "3 files with uncommitted changes"
- **Omit** in notes-only mode

### "Open" — Unfinished work
- Uncommitted/unstaged file changes
- In-progress checkbox items
- Open bugs (pink notes from this session)
- Blocked loop tasks (from state file)

### "Risks" — Watch out for
- Uncommitted changes that could be lost
- Blocked tasks that need external input
- Failing tests mentioned in conversation
- Known bugs that could affect next work
- **Omit** if no risks identified — don't invent problems

### "Next" — THE handoff section
**This is the most important section.** It must be specific enough for a fresh session to pick up immediately.

Quality bar — each item should answer: "What file, what function, what's left to do?"

Good:
- "Continue `validateToken()` in `auth.swift:45` — JWT parsing done, need expiry check"
- "Run tests after fixing flaky WebSocket test in `ws.test.ts`"
- "PR #42 needs one more review — Alice approved"

Bad:
- "Keep working on auth"
- "Fix bugs"
- "Continue development"

## Analysis Intelligence

Cross-reference data sources for richer summary:

| Cross-Reference | Intelligence |
|-----------------|-------------|
| Git commits ↔ Note checkboxes | If commit matches checkbox → confidently "Done" |
| `git diff` ↔ Open tasks | Modified files show WIP areas |
| Decision notes ↔ Commits | Decisions that were already implemented |
| Bug notes ↔ Open items | Known issues that block next steps |
| Loop state ↔ Focus note | Accurate progress tracking |
| Staged vs unstaged | What's ready to commit vs still WIP |

## Rules

- One Bash call max for git data
- **Replace** previous wrapup note — don't accumulate
- "Done" = actual work (verifiable from git/notes), not plans
- "Changed" = actual files from `git diff --stat`
- "Open" = truly open work, not general TODOs
- "Risks" = real identified risks, not hypotheticals
- "Next" = specific, actionable, with file/function references
- 3-5 items per section max
- Don't repeat info across sections
- Date: "Feb 19, 2026"
- If user provides extra context → add as first item in relevant section
- If loop was active → include progress in "Done"
