---
name: context
description: Save current session context to a SlashNote for handoff to next session
allowed-tools:
  - mcp__slashnote__create_note
  - mcp__slashnote__list_notes
  - mcp__slashnote__read_note
  - mcp__slashnote__search_notes
  - mcp__slashnote__delete_note
  - Bash
  - Read
---

# /context — Session Context Save

Save a snapshot of the current working context to a SlashNote. Designed for preserving state across Claude Code sessions — when context is about to be lost (compaction, session end, context switch).

## Usage

```
/context                      # Auto-capture full context
/context <additional notes>   # Auto-capture + user notes
```

## Behavior

### Step 1: Delete previous context note

Search for existing context notes (`mcp__slashnote__search_notes` with "Context"). Delete the most recent one — only keep the latest snapshot.

### Step 2: Collect context (one Bash call)

```bash
echo "PROJECT:$(basename $(git rev-parse --show-toplevel 2>/dev/null || pwd))" && echo "BRANCH:$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no-git')" && echo "---STATUS---" && git status --short 2>/dev/null | head -20 && echo "---LOG---" && git log --oneline -5 2>/dev/null
```

### Step 3: Collect SlashNote state

1. `mcp__slashnote__list_notes` — overview
2. Read focus note (if exists) → current tasks
3. Read loop state file (if exists) → loop progress

### Step 4: Create context note

**Blue** note, **pinned**:

```markdown
# Context <timestamp>

**<project>** @ `<branch>` | <N> uncommitted changes

## Working On
<current task from focus/loop, or inferred from conversation>

## Key Files
- `path/to/file.swift` — <what's being changed, 5 words max>
- `path/to/other.ts` — <purpose>

## State
- <branch purpose: "Adding X", "Fixing Y">
- <uncommitted changes: "N staged, M modified, K untracked">
- <loop progress: "Focus loop: N/M tasks done">

## Key Decisions
- <important decisions from this session>

## Open Questions
- <unresolved questions or uncertainties>

## Resume With
<exact command or action to pick up where we left off>
```

## Section Details

### Header Line
- Format: `**<project>** @ \`<branch>\` | <N> uncommitted changes`
- This gives instant orientation: what project, what branch, what's dirty
- If no uncommitted changes → `| clean`

### "Working On"
- If focus loop active → current task name + progress (N/M)
- If no loop → infer from conversation (what was being discussed/coded)
- Keep to 1-2 lines
- Be specific: "Improving /context skill in SlashNote plugin" not "Working on stuff"

### "Key Files"
- **NEW section** — list the 3-5 most important files being worked on
- Source from `git status` (modified files) and conversation context
- Each file gets a brief annotation (max 5 words)
- This helps the next session immediately know where to look
- Skip if no specific files are relevant (e.g., research-only session)

### "State"
- Branch purpose (infer from branch name: `feature/X` → "Adding X")
- Uncommitted changes summary: "3 staged, 2 modified, 1 untracked"
- Loop progress if active
- Max 5 items

### "Key Decisions"
- Decisions made in this session (check for decision notes)
- Technical choices, approach changes, rejected alternatives
- **Omit** if no decisions were made

### "Open Questions"
- **NEW section** — unresolved questions or uncertainties
- Things that need clarification from the user or team
- Technical uncertainties that need investigation
- **Omit** if no open questions

### "Resume With"
THE most critical section. Must be specific enough for a fresh Claude Code session to pick up **immediately**.

Quality bar: a new session reading ONLY this line should know exactly what to do next.

Good:
- "Continue editing `skills/focus/SKILL.md` — adding note ID support"
- "Run `/focus --loop` on note `3CEB5A5B` to continue skills roadmap"
- "`git diff` shows 3 modified files — review changes, then commit"
- "Read `auth.swift:45-80`, fix the JWT expiry check, then run tests"

Bad:
- "Continue working" (too vague)
- "Check the code" (meaningless)
- "Keep going" (useless)

## Non-Git Mode

If not in a git repo, skip git calls entirely:

```markdown
# Context <timestamp>

## Working On
<current task>

## Key Notes
- <relevant open notes summary>

## Open Questions
- <unresolved items>

## Resume With
<specific next action>
```

## Rules

- One Bash call max for git data
- Always **pin** the note (context should stay visible)
- Always **blue** color
- Timestamp includes time: "Feb 19, 2026 00:57"
- "Resume With" is **mandatory** — never skip it
- "Key Files" helps the next session navigate — always include if files are relevant
- If user provides additional notes → add as "Notes" section before "Resume With"
- **Delete** previous context notes (only keep latest)
- Keep the entire note scannable — this is a quick-reference card, not a detailed log
- Optimized for LLM compaction — every line has maximum information density
