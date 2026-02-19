---
name: meeting
description: Capture meeting notes — attendees, decisions, action items with owners
allowed-tools:
  - mcp__slashnote__create_note
  - mcp__slashnote__list_notes
  - mcp__slashnote__search_notes
---

# /meeting — Meeting Notes

Capture meeting notes with structured format: topic, decisions, and action items with owners.

## Usage

```
/meeting <topic or raw notes>
```

## Behavior

1. Parse the user's input to extract:
   - **Topic/title** — what the meeting is about
   - **Attendees** — names mentioned
   - **Decisions** — things that were decided/agreed on
   - **Key points** — discussions, important info (non-decisions)
   - **Action items** — tasks with owners and deadlines
2. Create a **blue** note with structured format
3. Confirm: "Created meeting note: <title>"

## Output Format

```markdown
# <Meeting Title>
**Attendees:** Name1, Name2

## Decisions
- Decision 1
- Decision 2

## Key Points
- Point 1
- Point 2

## Action Items
- [ ] @Name: Task description (by <deadline>)
- [ ] @Name: Task description
- [ ] Task without owner

## <Date>
```

### Section Rules

- **Decisions** appears ABOVE Key Points — decisions are the highest-value output
- **Key Points** — discussion items, observations, information shared (NOT decisions)
- If no clear decisions were made → omit Decisions section entirely
- If no clear discussion points → omit Key Points section entirely
- At least one of Decisions or Key Points must be present

### Action Item Format

Each action item should pass the **"stranger test"** — could someone unfamiliar with the meeting understand exactly what needs to be done?

| Component | Format | Example |
|-----------|--------|---------|
| Owner | `@Name:` prefix | `@Maria: Update API docs` |
| Deadline | `(by <date>)` suffix | `(by Friday)` |
| Both | Combined | `@Maria: Update API docs (by Friday EOD)` |
| Neither | Plain task | `Set up A/B testing` |

### Deadline Extraction

Detect deadline signals in the input and attach them to the relevant action item:

| Signal | Output |
|--------|--------|
| "by Friday", "before Friday" | `(by Friday)` |
| "by EOD", "end of day" | `(by EOD)` |
| "by end of week" | `(by end of week)` |
| "next week", "next Monday" | `(by next Monday)` |
| "tomorrow" | `(by tomorrow)` |
| "ASAP", "urgent" | `(ASAP)` |
| No deadline mentioned | No suffix |

### Date Format

Date appears as the last section heading (not bold text):
- Format: `## Feb 19, 2026`
- This makes it scannable in note list and separates metadata from content

## Parsing Intelligence

### From structured input
If user provides clear notes with bullet points, names, or decisions — organize into Decisions, Key Points, and Action Items.

### From raw/unstructured input
If user provides a stream-of-consciousness dump:
- Extract anything phrased as agreement/conclusion → **Decisions** ("decided to", "agreed on", "going with", "we'll use")
- Extract anything that sounds like a task/follow-up → **Action Items** (with owner if name is mentioned)
- Extract discussion topics → **Key Points**
- Extract meeting topic from the most prominent subject
- Discard filler words and organize into clean format

### From topic-only input
If user provides just a meeting topic (e.g., `/meeting Sprint planning`):
- Create the note with the topic as title
- Add placeholder sections:
  ```markdown
  ## Key Points
  -

  ## Action Items
  - [ ]

  ## Feb 19, 2026
  ```

## Attendee Extraction

Detect names from the input:
- Explicit: "with Alex and Maria", "attendees: John, Sarah"
- Implicit from action items: "Maria will handle frontend" → Maria is an attendee AND action owner
- Only include `**Attendees:**` line if 1+ names detected
- Names in action items: `@Maria: handle frontend changes`

## Formatting Rules

- Always **blue** color
- Title: concise meeting topic, no "Meeting:" prefix (the skill name implies it)
- Decisions: bullet list — these are conclusions, not tasks
- Key Points: bullet list — these are facts/observations, not tasks
- Action Items: checkboxes — these are actionable follow-ups
- Date: as `##` heading at the bottom (scannable)
- Max 5 decisions, max 7 key points, max 7 action items — keep it scannable
- If more content, summarize — meeting notes should fit on one screen

## Examples

**Input:** `/meeting Sprint planning — discussed auth refactor, decided to use JWT, need to update API docs by Friday, Maria will handle frontend`
**Result:**
```markdown
# Sprint Planning
**Attendees:** Maria

## Decisions
- Use JWT for authentication

## Key Points
- Discussed auth refactor approach

## Action Items
- [ ] @Maria: Handle frontend changes
- [ ] Update API docs (by Friday)

## Feb 19, 2026
```

**Input:** `/meeting 1:1 with Alex`
**Result:**
```markdown
# 1:1 with Alex
**Attendees:** Alex

## Key Points
-

## Action Items
- [ ]

## Feb 19, 2026
```

**Input:** `/meeting We talked about the new pricing page, John suggested A/B testing, we agreed to go with tiered pricing, Sarah needs to deliver designs by Friday, also discussed the analytics bug — decided to deprioritize it`
**Result:**
```markdown
# Pricing Page Discussion
**Attendees:** John, Sarah

## Decisions
- Go with tiered pricing model
- Deprioritize analytics bug

## Key Points
- Discussed new pricing page approach
- John suggested A/B testing strategy
- Analytics bug acknowledged but deprioritized

## Action Items
- [ ] @Sarah: Deliver pricing page designs (by Friday)
- [ ] Set up A/B testing for pricing page

## Feb 19, 2026
```

**Input:** `/meeting Quick sync about deployment — we'll deploy Monday morning, Alex will run migrations first, then Sarah deploys the API, I need to update the status page ASAP`
**Result:**
```markdown
# Deployment Sync
**Attendees:** Alex, Sarah

## Decisions
- Deploy Monday morning
- Migrations run first, then API deployment

## Action Items
- [ ] @Alex: Run database migrations (by Monday morning)
- [ ] @Sarah: Deploy the API (by Monday morning)
- [ ] Update status page (ASAP)

## Feb 19, 2026
```

## Important

- One tool call — create note immediately
- Do NOT ask for more details — work with what you have
- Blue color always — this is the meeting color
- Keep it scannable — meetings generate noise, notes should be signal
- **Decisions are the #1 output** — separate them from discussion
- Action items need owners when possible — "stranger test" is the quality bar
- Deadlines extracted from natural language, not asked for
