---
name: note-find
description: Search and surface relevant SlashNote notes by topic, content, or type
allowed-tools:
  - mcp__slashnote__list_notes
  - mcp__slashnote__read_note
  - mcp__slashnote__search_notes
  - mcp__slashnote__show_note
  - mcp__slashnote__get_open_notes
---

# /note-find — Search & Surface

Search existing SlashNote notes and surface relevant ones.

## Usage

```
/note-find <query>                    # Search by content/topic
/note-find <query> --type note-bug    # Combined: content + type filter
/note-find --type note-bug            # Filter by note type (color)
/note-find --recent                   # Show recently modified notes
/note-find --recent 5                 # Show N most recent
/note-find --open                     # Show all currently open notes
/note-find --pinned                   # Show pinned notes only
```

## Search Modes

### Content Search (default)
```
/note-find auth
/note-find WebSocket bug
/note-find meeting with Alex
```

1. Call `mcp__slashnote__search_notes` with the query
2. If results found → display summary table
3. If no results → try broader search (see "No Results" section)
4. Show the most relevant note via `mcp__slashnote__show_note`

### Combined Search (query + flag)
```
/note-find auth --type note-bug         # Bugs mentioning "auth"
/note-find API --type note-decide       # Decisions about "API"
/note-find login --type note-snippet    # Code snippets about "login"
```

1. Call `mcp__slashnote__search_notes` with the query
2. Filter results by type (color/pattern)
3. Display matching subset

### Type Filter (`--type`)
```
/note-find --type note-bug        # Pink notes (bugs)
/note-find --type note-todo       # Peach notes (checklists)
/note-find --type idea            # Blue notes with "Idea" heading
/note-find --type note-snippet    # Purple notes (code)
/note-find --type note-meeting    # Blue notes with meeting patterns
/note-find --type note-decide     # Green notes with decision patterns
/note-find --type note-loop       # Green notes with "/note-loop" heading
/note-find --type note-context    # Blue notes with "Context" heading
```

1. Call `mcp__slashnote__list_notes` with `brief: true` for lighter token usage
2. Filter by color + content pattern:

| Type | Color | Pattern |
|------|-------|---------|
| `note-bug` | pink | — |
| `note-todo` | peach | has checkboxes |
| `idea` | blue | has "Idea" heading |
| `note-snippet` | purple | has code blocks |
| `note-meeting` | blue | has "Key Points" or "Action Items" |
| `note-decide` | green | has "Decision:" or "Over:" |
| `note-loop` | green | has "/note-loop" heading |
| `note-context` | blue | has "Context" heading |

3. Display matching notes as summary table

**Optimization:** For type-only filters that map to a single color, use `tag` parameter in `list_notes` if a matching tag exists, or filter by color client-side from the brief response.

### Recent (`--recent`)
```
/note-find --recent
/note-find --recent 5
```

1. Call `mcp__slashnote__list_notes` with `limit: N, brief: true`
2. Notes are returned sorted by `updatedAt` (most recent first)
3. Show top N notes (default: 5, max: 10)

### Open (`--open`)
```
/note-find --open
```

1. Call `mcp__slashnote__get_open_notes` to get all visible notes with window positions and screen info
2. Show all currently visible notes with their screen positions

### Pinned (`--pinned`)
```
/note-find --pinned
```

1. Call `mcp__slashnote__list_notes` with `pinned: true, brief: true`
2. Show all pinned notes

## Output Format

Display results as a compact summary:

```
Found N notes:

1. 📌 [green] /note-loop — 3/5 tasks done
2. [pink] Bug: Login crash — Feb 18
3. [blue] Sprint Planning — 2 action items
4. [purple] JWT validation — 15 lines Swift
5. [peach] Shopping list — 4 items, 1 done

Showing #1. Say "show 2" to open another.
```

### Summary Line Rules

| Note Type | Summary Format |
|-----------|---------------|
| Checklist (peach) | `<title> — N items, M done` |
| Bug (pink) | `<title> — <severity if present>, <date>` |
| Idea (blue) | `<title> — <first 8 words>...` |
| Code (purple) | `<title> — N lines <language>` |
| Meeting (blue) | `<title> — N action items` |
| Decision (green) | `<title> — <decision one-liner>` |
| /note-loop (green) | `<title> — N/M tasks done` |
| Context (blue) | `<title> — <date>` |
| Other | `<title> — <first 8 words>...` |

### Result Ranking

When multiple results match, rank by:
1. **Pinned notes first** — they represent active/important items
2. **Recency** — more recently updated notes rank higher
3. **Content match** — exact title match > content match
4. Pinned notes get a `📌` prefix in the output

## No Results Handling

When search returns no results:

1. **Broaden the search**: Remove least important words and retry
   - "WebSocket connection bug" → try "WebSocket bug" → try "WebSocket"
2. **Suggest alternatives**: "No notes found for 'auth'. Try `/note-find --type note-bug` or `/note-find --recent`"
3. **Offer creation**: "Create one with `/note <text>` or `/note-bug <description>`"

## Rules

- Always show results as numbered list with color tag
- Auto-show the most relevant result (highest-ranked match)
- User can say "show 2", "show 3" to open other results
- Max 10 results per search
- If no notes at all → "No notes found. Create one with `/note <text>`"
- Keep output compact — one line per note
- Do NOT read all notes' full content — use `brief: true` with `list_notes` for minimal token usage
- Only read full content when showing a specific note
- Use `list_notes` filtering params: `pinned`, `is_open`, `tag` to narrow results server-side
- Flags can be combined: `/note-find auth --type note-bug --pinned` works
