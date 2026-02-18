---
name: wrapup
description: Generate a session summary with handoff notes for next session
allowed-tools:
  - mcp__slashnote__create_note
  - mcp__slashnote__list_notes
  - mcp__slashnote__read_note
  - mcp__slashnote__search_notes
  - Bash
---

# /wrapup — Session Summary

Generate an end-of-session summary with handoff notes for the next session.

## Usage

```
/wrapup
/wrapup <optional context or notes>
```

## Behavior

### Step 1: Analyze session

Collect from this conversation and environment:

1. **Git activity this session:**
   ```bash
   git log --oneline -20 2>/dev/null
   git diff --stat 2>/dev/null
   ```

2. **SlashNote state:**
   - List all notes, read focus note if exists
   - Check loop state file for task progress

3. **Conversation context:**
   - What tasks were discussed/completed in this session
   - Any decisions made
   - Any issues encountered

### Step 2: Generate summary

Create a green note:

```markdown
# Session Wrapup <date>

## Accomplished
- <what was completed this session>
- <merged PRs, closed issues>

## Changes
- <files/areas modified>
- <key code changes>

## In Progress
- <uncompleted tasks>
- <open PRs>

## Next Session
- <what to pick up next>
- <pending reviews>
- <known issues to address>
```

### Step 3: Create note

Call `mcp__slashnote__create_note`:
- Color: **green**
- Pinned: false

## Rules

- "Next Session" is the most important section — it's the handoff
- Be specific in "Next Session": file names, function names, exact next steps
- "Accomplished" should match actual git commits, not aspirational goals
- "Changes" should reference actual files modified (from `git diff --stat`)
- If loop was active, include task progress summary
- If user provided additional context, incorporate it
- Keep each section to 3-5 items max
- Don't repeat information across sections
- Date format: "Feb 18, 2026" (human readable)

## Next Session Best Practices

Good handoff items:
- "Continue implementing `validateToken()` in `auth.swift:45` — JWT parsing done, need expiry check"
- "Run test suite after fixing the flaky WebSocket test in `ws.test.ts`"
- "Review PR #42 — approved by Alice, needs one more review"

Bad handoff items:
- "Keep working on auth" (too vague)
- "Fix bugs" (no specifics)
