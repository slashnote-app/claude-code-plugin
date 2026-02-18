---
name: snippet
description: Save a code snippet to a SlashNote sticky note
allowed-tools:
  - mcp__slashnote__create_note
  - mcp__slashnote__list_notes
  - Read
  - Glob
---

# /snippet — Code Snippet Saver

Save a code snippet to a purple SlashNote sticky note.

## Usage

```
/snippet <code or file_path:lines or description>
```

## Input Modes

### Mode 1: File path with line range
```
/snippet src/auth.swift:10-25
/snippet src/utils.ts:42
```
- Read the file at the given path
- Extract the specified line range (or single line + surrounding context)
- Detect language from file extension

### Mode 2: Inline code
```
/snippet func validate(token: String) -> Bool { ... }
```
- User provides code directly
- Detect language from syntax

### Mode 3: Description
```
/snippet the retry logic in mcp-client.sh
```
- Search for the described code using Glob/Read
- Extract the relevant section
- If not found, ask user to be more specific

## Note Format

```markdown
# <descriptive title>

\`\`\`<language>
<code>
\`\`\`

Source: `<file_path>:<lines>` | <date>
```

## Behavior

1. Detect which input mode applies
2. For Mode 1: Use Read tool to get the file content, extract lines
3. For Mode 2: Use the inline code directly
4. For Mode 3: Use Glob to find file, Read to extract code
5. Generate a descriptive title from the code (function name, class, or purpose)
6. Call `mcp__slashnote__create_note` with:
   - `color`: "purple"
   - `content`: formatted markdown with code block
   - `pinned`: false

## Rules

- Always use **purple** color for snippets
- Auto-detect language for syntax highlighting (swift, typescript, python, bash, etc.)
- Include source file path and line numbers when available
- Keep the title short and descriptive (e.g., "JWT validation middleware", "Retry with backoff")
- Max ~50 lines of code per snippet. If more, truncate with `// ... (truncated)` comment
- Do NOT modify the code — save it exactly as-is
- Add today's date in the Source line

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
| Other | (no language tag) |
