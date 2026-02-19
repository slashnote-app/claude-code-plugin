---
name: note
description: Quick capture — instantly create a SlashNote with auto-detected type
allowed-tools:
  - mcp__slashnote__create_note
  - mcp__slashnote__list_notes
  - mcp__slashnote__search_notes
---

# /note — Quick Capture

Create a SlashNote sticky note instantly from the user's input. Zero friction — one command, one tool call, done.

## Usage

```
/note <text>
```

## Auto-Detection Rules

Analyze the user's input using a **confidence scoring** system. Each signal adds weight — the category with the highest score wins. Minimum 2 points to activate a category; otherwise default to plain note.

### Checklist (peach) — score 2+ to activate

| Signal | Points |
|--------|--------|
| Contains `- ` or `* ` list items (2+ items) | 3 |
| Contains comma-separated items (3+ items, no verbs/sentences) | 2 |
| Contains TODO/task keywords: "todo", "task", "checklist", "list" | 2 |
| Contains action verbs at start of items: "buy", "review", "deploy", "send", "check", "update" | 1 |

**Format:** Convert each item to `- [ ] Item`. If comma-separated, split by commas. No heading needed.

### Bug (pink) — score 2+ to activate

| Signal | Points |
|--------|--------|
| Explicit bug words: "bug", "crash", "broken", "regression" | 3 |
| Error context: "error", "exception", "fails", "not working", "undefined" | 2 |
| Word "fix" combined with another bug signal | 1 |
| Word "fix" alone (without other signals) | 0 |
| Word "issue" with technical context | 1 |

**Format:** `# Bug: <concise title (max 8 words)>` then body text. The word "fix" alone does NOT trigger bug — it's too common in normal usage.

### Idea (blue) — score 2+ to activate

| Signal | Points |
|--------|--------|
| Speculative words: "maybe", "what if", "could we", "how about" | 3 |
| Exploration words: "consider", "explore", "experiment", "try" | 2 |
| Word "idea" or "concept" | 3 |
| Question format about approach/design | 1 |

**Format:** `# Idea` heading + the text as body.

### Code (purple) — score 2+ to activate

| Signal | Points |
|--------|--------|
| Contains triple backticks | 3 |
| Contains code keywords: `func `, `def `, `class `, `import `, `const `, `let `, `var ` at word boundary | 2 |
| Contains code operators: `->`, `=>`, `::`, `\|>` | 2 |
| Contains file path patterns: `src/`, `.swift`, `.ts`, `.py`, `.rs` | 1 |

**Format:** Wrap in code block with detected language. Add `# Snippet` heading if content is multi-line.

### Link (yellow + bookmark) — score 2+ to activate

| Signal | Points |
|--------|--------|
| Contains URL pattern: `http://`, `https://`, `www.` | 3 |
| Contains domain pattern: `*.com`, `*.io`, `*.dev`, `*.org` | 2 |
| Contains "link", "url", "site", "page", "article" keywords | 1 |

**Format:** If input is URL-only → `# Bookmark` heading + URL as body. If URL + description → description as title + URL below. Color stays **yellow** but content is formatted.

### Default (yellow) — fallback

When no category reaches 2 points, or input is short (< 5 words):
- Plain text, no heading, no formatting
- Color: **yellow**

## Auto-Title

For notes longer than 20 words that don't get a heading from category detection:
- Generate a concise title (max 6 words) from the content
- Add as `# <Title>` heading
- This makes notes scannable in the list view

Short notes (< 20 words) → no auto-title needed.

## Tie-Breaking

If multiple categories score equally:
1. Checklist > Bug > Idea > Code > Link (priority order)
2. If still ambiguous, default to yellow plain text

## Behavior

1. Parse the user's input after `/note `
2. Score each category using signals above
3. Pick the highest-scoring category (minimum 2 points)
4. Apply auto-title if needed (long notes without heading)
5. Call `mcp__slashnote__create_note` with detected color and formatted content
6. Confirm to the user: "Created [color] note: [first line preview]"

## Examples

**Input:** `/note Fix race condition in WebSocket handler`
**Scoring:** Bug gets 0 ("fix" alone = 0 points) → **Yellow** plain text

**Input:** `/note Bug: race condition crashes WebSocket handler`
**Scoring:** Bug gets 6 → **Pink** bug note
**Result:** `# Bug: Race condition crashes WebSocket handler`

**Input:** `/note - Buy milk - Review PR - Deploy staging`
**Scoring:** Checklist gets 4 → **Peach** checklist with 3 checkboxes

**Input:** `/note buy milk, review PR, deploy staging, send email`
**Scoring:** Checklist gets 3 → **Peach** checklist with 4 checkboxes

**Input:** `/note Use LRU cache for API responses`
**Scoring:** No category reaches 2 → **Yellow** plain text

**Input:** `/note Maybe we should try SSE instead of WebSockets`
**Scoring:** Idea gets 5 → **Blue** idea with `# Idea` heading

**Input:** `/note func validate(token: String) -> Bool`
**Scoring:** Code gets 4 → **Purple** Swift code block

**Input:** `/note https://github.com/anthropics/claude-code`
**Scoring:** Link gets 3 → **Yellow** bookmark
**Result:** `# Bookmark` heading + URL

**Input:** `/note Great article about SwiftUI performance https://swiftui-lab.com/performance`
**Scoring:** Link gets 3 → **Yellow** with description as title
**Result:** `# SwiftUI Performance Article` heading + URL below

**Input:** `/note We discussed the migration strategy with the team today. The consensus was to use a phased approach starting with the auth module, then moving to the API layer, and finally the UI components. Timeline is 3 sprints.`
**Auto-title applied** (>20 words, no category) → **Yellow** with generated title
**Result:** `# Migration Strategy — Phased Approach` heading + full text

## Important

- Keep it fast — one tool call, no extra questions
- Do NOT ask the user for confirmation, color choice, or anything else
- Confidence scoring happens in your head — do not show scores to the user
- Short inputs (< 5 words) → always yellow plain text (skip scoring)
- When in doubt, prefer yellow plain text over a wrong category
- Zero friction is the #1 goal — never add steps between input and note creation
