---
name: bugs
description: Log a structured bug report to a SlashNote sticky note
allowed-tools:
  - mcp__slashnote__create_note
  - mcp__slashnote__list_notes
  - Bash
---

# /bugs — Bug Logger

Create a structured bug report in a SlashNote sticky note.

## Usage

```
/bugs <description>
```

## Behavior

1. Parse the user's bug description
2. Collect git context (branch name) via quick `git rev-parse --abbrev-ref HEAD`
3. Create a pink note with structured format:

```markdown
# Bug: <concise title>

## Summary
<1-2 sentence description from user input>

## Context
Branch: <current git branch>
Date: <today's date>

## Steps to Reproduce
- [ ] <step 1 — infer from description or leave placeholder>

## Expected vs Actual
**Expected:** <infer or "TBD">
**Actual:** <from description>
```

4. Call `mcp__slashnote__create_note` with:
   - `color`: "pink"
   - `content`: formatted markdown above
   - `pinned`: false

## Rules

- Always use **pink** color for bugs
- Extract a concise title from the description (max 8 words)
- If the user provides enough detail, fill in Steps/Expected/Actual
- If not enough detail, use placeholders ("TBD", empty checkboxes)
- Keep it compact — bug notes should be scannable
- Do NOT ask followup questions — create the note immediately with what you have
- Git branch lookup should be quick (1 Bash call max), skip if not in a repo

## Examples

**Input:** `/bugs Login crashes on Safari when clicking the submit button`
**Result:**
```markdown
# Bug: Login crash on Safari submit

## Summary
Login page crashes on Safari when clicking the submit button.

## Context
Branch: feature/auth-flow
Date: 2026-02-18

## Steps to Reproduce
- [ ] Open login page in Safari
- [ ] Enter credentials
- [ ] Click submit button

## Expected vs Actual
**Expected:** Successful login redirect
**Actual:** Page crashes
```

**Input:** `/bugs race condition in websocket`
**Result:** Pink note with minimal structure, placeholders for details
