---
name: decisions
description: Log an architectural decision (ADR-lite) to a SlashNote sticky note
allowed-tools:
  - mcp__slashnote__create_note
  - mcp__slashnote__list_notes
  - mcp__slashnote__search_notes
---

# /decisions — Architectural Decision Logger

Log architectural and technical decisions as lightweight ADR (Architecture Decision Records) in SlashNote.

## Usage

```
/decisions <decision description>
/decisions Use LRU caching for API responses instead of Redis
```

## Behavior

### Step 1: Check for duplicates

Search existing notes: `mcp__slashnote__search_notes` with key terms from the decision.
If a similar decision note already exists, inform the user and ask if they want to update or create a new one.

### Step 2: Generate ADR

Parse the user's input to extract:
- The **decision** itself
- The **context** (why this came up)
- **Alternatives** considered (if mentioned)

### Step 3: Create note

```markdown
# Decision: <concise title>

## Context
<why this decision was needed — infer from conversation context or description>

## Decision
<what was decided>

## Reasoning
- <why this approach was chosen>
- <key trade-offs considered>

## Alternatives
- <other options that were considered>
- <why they were rejected>

## Date
<today's date>
```

Call `mcp__slashnote__create_note`:
- Color: **purple**
- Pinned: false

## Rules

- Always use **purple** color for decisions
- Check for duplicate/similar decisions before creating
- Title should be actionable: "Use X for Y" not just "Caching"
- If user only gives the decision (no context), infer from the current conversation
- Keep each section to 2-4 bullet points
- If no alternatives were discussed, note "No alternatives evaluated" or infer common alternatives
- Date format: "Feb 18, 2026"
- Don't over-document — this is ADR-**lite**, keep it to one screenful

## Examples

**Input:** `/decisions Use LRU caching for API responses`
**Result:**
```markdown
# Decision: Use LRU caching for API responses

## Context
API response times are too slow for frequently accessed data.

## Decision
Implement in-memory LRU cache for API responses with 5-minute TTL.

## Reasoning
- Simple to implement, no infrastructure changes
- Sufficient for current traffic levels
- Easy to replace with Redis later if needed

## Alternatives
- Redis: Too complex for current scale
- CDN caching: Doesn't work for authenticated endpoints
- No caching: Current performance is unacceptable

## Date
Feb 18, 2026
```
