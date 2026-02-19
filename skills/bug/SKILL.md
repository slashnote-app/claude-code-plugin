---
name: bug
description: Log a structured bug report with git context and recent diff
allowed-tools:
  - mcp__slashnote__create_note
  - mcp__slashnote__list_notes
  - Bash
---

# /bug — Bug Report

Create a structured bug report in a SlashNote sticky note with git context.

## Usage

```
/bug <description>
```

## Behavior

1. Parse the user's bug description
2. Collect git context with a **single** Bash call:
   ```bash
   echo "BRANCH:$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'no-git')" && echo "---DIFF---" && git diff --stat HEAD~1 2>/dev/null | tail -5
   ```
3. Create a **pink** note with structured format

## Output Format

```markdown
# Bug: <concise title (max 8 words)>
**Severity:** <Critical / High / Medium / Low>

## What happens
<1-2 sentence description from user input>

## Context
Branch: <current git branch>
Date: <today's date>
Recent changes: <summary of git diff --stat, e.g. "3 files changed (auth.swift, api.ts, test.ts)">

## Repro
- [ ] <step 1>
- [ ] <step 2>
- [ ] <step 3>

## Expected → Actual
**Expected:** <inferred or "TBD">
**Actual:** <from description>
```

### Severity Inference

Infer severity from the description — do not ask the user:

| Keyword Signals | Severity |
|----------------|----------|
| "crash", "data loss", "security", "down", "blocks" | **Critical** |
| "broken", "fails", "can't", "regression" | **High** |
| "wrong", "incorrect", "unexpected", "slow" | **Medium** |
| "minor", "cosmetic", "typo", "alignment" | **Low** |
| No clear signal | **Medium** (safe default) |

## Git Context Rules

- **One Bash call** — combine branch + diff in a single command
- If not in a git repo → skip "Branch" and "Recent changes" lines entirely
- Parse `git diff --stat` output: extract changed file names, summarize as "N files changed (file1, file2, ...)"
- Show max 3 file names in the summary, use "+N more" for the rest
- This context helps identify which recent changes may have caused the bug

## Formatting Rules

- Always **pink** color
- Title: max 8 words, actionable ("Login crashes on Safari" not "Bug with login")
- "What happens" instead of "Summary" — more natural
- "Repro" instead of "Steps to Reproduce" — shorter
- "Expected → Actual" — compact format
- If user provides enough detail → fill in Repro steps (infer logical sequence)
- If minimal input → use placeholder checkboxes ("Describe step 1", "Describe step 2")
- Keep it compact — bug notes should be scannable in 5 seconds

## Examples

**Input:** `/bug Login crashes on Safari when clicking submit`
**Result:**
```markdown
# Bug: Login crashes on Safari submit

## What happens
Login page crashes on Safari when clicking the submit button.

## Context
Branch: feature/auth-flow
Date: Feb 19, 2026
Recent changes: 3 files changed (AuthController.swift, LoginView.swift, +1 more)

## Repro
- [ ] Open login page in Safari
- [ ] Enter credentials
- [ ] Click submit button

## Expected → Actual
**Expected:** Successful login redirect
**Actual:** Page crashes on submit
```

**Input:** `/bug race condition in websocket`
**Result:**
```markdown
# Bug: Race condition in WebSocket handler

## What happens
Race condition occurring in WebSocket handler.

## Context
Branch: main
Date: Feb 19, 2026
Recent changes: 2 files changed (WebSocketManager.swift, ConnectionPool.swift)

## Repro
- [ ] Describe trigger condition
- [ ] Describe sequence of events

## Expected → Actual
**Expected:** TBD
**Actual:** Race condition in WebSocket handler
```

## Non-Git Mode

If not in a git repo (Bash returns "no-git"):
- Skip "Branch" and "Recent changes" lines
- Context section becomes just `Date: <today>`
- Everything else stays the same

## Important

- Do NOT ask followup questions — create the note immediately
- One Bash call max for git context
- Keep the note scannable — developers glance at bugs, they don't read essays
- Severity is inferred, never asked — it's a visual hint, not a SLA commitment
