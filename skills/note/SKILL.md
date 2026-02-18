---
name: note
description: Quick capture — instantly create a SlashNote with auto-detected type
allowed-tools:
  - mcp__slashnote__create_note
  - mcp__slashnote__list_notes
  - mcp__slashnote__search_notes
---

# /note — Quick Capture

Create a SlashNote sticky note instantly from the user's input.

## Usage

```
/note <text>
```

## Auto-Detection Rules

Analyze the user's input and pick the **first matching** rule:

| Signal | Color | Tag | Format |
|--------|-------|-----|--------|
| Contains `- ` list items or comma-separated tasks or TODO keywords | peach | `todo` emoji or no tag | Convert each item to a checkbox line (`- [ ] Item`) |
| Contains words: bug, crash, error, fix, broken, issue, regression | pink | `bug` emoji or no tag | Single line: `# Bug: <summary>` then the text as body |
| Contains words: idea, maybe, could, what if, consider, explore | blue | no tag | `# Idea` heading + the text |
| Contains code patterns: backticks, `->`, `func `, `def `, `class `, `import ` | purple | no tag | Wrap in code block with detected language |
| Default (anything else) | yellow | no tag | Plain text, no heading |

## Behavior

1. Parse the user's input after `/note `
2. Apply auto-detection rules above (first match wins)
3. Call `mcp__slashnote__create_note` with detected color and formatted content
4. Confirm to the user: "Created [color] note: [first line preview]"

## Examples

**Input:** `/note Fix race condition in WebSocket handler`
**Result:** Pink note with `# Bug: Fix race condition in WebSocket handler`

**Input:** `/note - Buy milk - Review PR - Deploy staging`
**Result:** Peach note with checkboxes:
```
- [ ] Buy milk
- [ ] Review PR
- [ ] Deploy staging
```

**Input:** `/note Use LRU cache for API responses`
**Result:** Yellow note with plain text

**Input:** `/note Maybe we should try Server-Sent Events instead of WebSockets`
**Result:** Blue note with `# Idea` heading

## Important

- Keep it fast — one tool call, no extra questions
- Do NOT ask the user for confirmation, color choice, or anything else
- If input is ambiguous, prefer the simpler format (yellow plain text)
- Short inputs (< 5 words) → always yellow plain text
