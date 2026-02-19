---
name: snippet
description: Save a code snippet to a SlashNote sticky note with context
allowed-tools:
  - mcp__slashnote__create_note
  - mcp__slashnote__list_notes
  - Read
---

# /snippet — Code Snippet

Save a code snippet to a purple SlashNote sticky note with optional annotation.

## Usage

```
/snippet <file_path:lines>                # Extract from file
/snippet <file_path:lines> -- <why>       # Extract with annotation
/snippet <inline code>                    # Save code directly
/snippet <inline code> -- <why>           # Inline with annotation
```

## Two Modes

### Mode 1: File reference
```
/snippet src/auth.swift:10-25
/snippet src/utils.ts:42
/snippet Services/AI/AIServiceManager.swift
/snippet Core/NoteManager.swift:15-30 -- CRUD pattern to reuse in new module
```
- Read the file at the given path using the `Read` tool
- Extract the specified line range (or single line ± 5 lines of context)
- If no lines specified, save entire file (up to 50 lines; truncate if longer)
- Detect language from file extension

### Mode 2: Inline code
```
/snippet func validate(token: String) -> Bool { return token.count > 0 }
/snippet const debounce = (fn, ms) => { ... } -- useful utility
```
- User provides code directly in the input
- Detect language from syntax patterns
- No file reading needed

### How to tell which mode:
- Contains path-like patterns (`/`, `.swift`, `.ts`, `.py`, `:` with numbers) → **Mode 1**
- Everything else → **Mode 2**

## Annotation (`--` separator)

If input contains ` -- ` (double dash with spaces), everything after it is an annotation explaining **why** the snippet was saved. This adds context for future reference.

| Input | Code Part | Annotation |
|-------|-----------|------------|
| `/snippet auth.swift:10-25 -- JWT validation pattern` | `auth.swift:10-25` | "JWT validation pattern" |
| `/snippet const x = 1 -- example` | `const x = 1` | "example" |
| `/snippet auth.swift:10-25` | `auth.swift:10-25` | (none) |

Annotation appears as italic text below the code block.

## Output Format

### With annotation:
```markdown
# <descriptive title>
*<annotation>*

```<language>
<code>
```

`<file_path>:<lines>` · Feb 19, 2026
```

### Without annotation:
```markdown
# <descriptive title>

```<language>
<code>
```

`<file_path>:<lines>` · Feb 19, 2026
```

### Title Generation

Generate a descriptive title (max 6 words) by analyzing the code:

| Code Pattern | Title Strategy | Example |
|--------------|---------------|---------|
| Function/method | Function name + purpose | "Debounce utility function" |
| Class/struct | Class name | "NoteManager CRUD operations" |
| Config/constants | What it configures | "Redis connection config" |
| Algorithm/logic | What it does | "Binary search implementation" |
| Type/interface | Type name + domain | "User auth types" |
| Can't determine | Use annotation if present, else "Code snippet" | |

### Footer Format

- Source + date on one line, separated by ` · `
- Source line only for Mode 1 (file reference). For inline code, just date.
- Omit source path for inline code — it has no file origin

## Code Formatting

For **inline mode** only — if the code is clearly a one-liner that was compressed:
- Detect if it contains `{ ... }` or `=> { ... }` patterns
- Attempt basic formatting (one statement per line, proper indentation)
- If formatting unclear, save as-is — never break working code

For **file mode** — always save exactly as-is from the file. Never modify.

## Rules

- Always **purple** color
- Auto-detect language from extension or syntax
- Max ~50 lines per snippet — truncate with `// ... (truncated, N more lines)` if longer
- Do NOT modify code from files — save exactly as-is
- One-liner inline code may be formatted for readability
- One tool call for inline, two for file (Read + create_note)
- If file not found → tell user, do not create note

## Language Detection

| Extension | Language |
|-----------|----------|
| .swift | swift |
| .ts/.tsx | typescript |
| .js/.jsx | javascript |
| .py | python |
| .sh/.bash | bash |
| .rs | rust |
| .go | go |
| .rb | ruby |
| .json | json |
| .yaml/.yml | yaml |
| .md | markdown |
| .css/.scss | css |
| .html | html |
| .sql | sql |
| .dockerfile/Dockerfile | dockerfile |
| Other | (no language tag) |

### Syntax-Based Detection (Mode 2)

When no file extension available, detect from syntax:

| Pattern | Language |
|---------|----------|
| `func `, `guard `, `let `, `var ` (Swift style) | swift |
| `const `, `=>`, `async `, `Promise` | typescript/javascript |
| `def `, `import `, `class ` (Python style) | python |
| `fn `, `impl `, `pub `, `mut ` | rust |
| `func ` (Go style with no `->`) | go |

## Examples

**Input:** `/snippet Core/NoteManager.swift:15-30`
**Result:**
```markdown
# NoteManager CRUD operations

```swift
func createNote(preset: NotePreset) -> Note {
    // ... extracted code
}
```

`Core/NoteManager.swift:15-30` · Feb 19, 2026
```

**Input:** `/snippet const debounce = (fn, ms) => { let timer; return (...args) => { clearTimeout(timer); timer = setTimeout(() => fn(...args), ms); }; }`
**Result:**
```markdown
# Debounce utility

```javascript
const debounce = (fn, ms) => {
    let timer;
    return (...args) => {
        clearTimeout(timer);
        timer = setTimeout(() => fn(...args), ms);
    };
};
```

Feb 19, 2026
```

**Input:** `/snippet auth.swift:42-60 -- JWT validation pattern to reuse in API module`
**Result:**
```markdown
# JWT token validation
*JWT validation pattern to reuse in API module*

```swift
func validateToken(_ token: String) -> Bool {
    // ... extracted code
}
```

`auth.swift:42-60` · Feb 19, 2026
```

## Important

- Keep it fast — no searching, no questions
- Purple color always — this is the code color
- If input is ambiguous between modes, prefer Mode 2 (inline)
- Annotation is optional — never ask for it
- Title generation is smart — analyze the code, don't just use "Snippet"
