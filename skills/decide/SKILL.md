---
name: decide
description: Log a technical decision (ADR-lite) with context and consequences
allowed-tools:
  - mcp__slashnote__create_note
  - mcp__slashnote__list_notes
  - mcp__slashnote__search_notes
---

# /decide — Decision Logger

Log technical and architectural decisions as lightweight ADR (Architecture Decision Records).

## Usage

```
/decide <what was decided and why>
```

## Behavior

1. Parse the user's input to extract:
   - **Context** — what problem/situation prompted this decision
   - **Decision** — what was chosen
   - **Why** — reasoning (infer from context if not stated)
   - **Over what** — alternatives rejected (infer common ones if not stated)
   - **Consequences** — what this decision implies going forward
2. Quick duplicate check: `mcp__slashnote__search_notes` with 2-3 key terms
3. If similar note exists → add `Supersedes: <previous title>` line, still create new one
4. Create **green** note with compact format

## Output Format

### Compact (default)

```markdown
# <Actionable title: "Use X for Y">

**Context:** <what problem prompted this — one sentence>
**Decision:** <what was chosen — one sentence>
**Why:** <key reason — one sentence>
**Over:** <alternatives rejected, comma-separated>
**Means:** <consequence/implication — what changes as a result>

<date>
```

The **Context → Decision → Why → Over → Means** flow reads as a story:
> "Given [context], we decided [decision] because [why], instead of [over]. This means [consequence]."

### Extended Format (for complex decisions)

Only use this when the user provides detailed context with multiple trade-offs:

```markdown
# <Actionable title>

**Context:** <what problem prompted this>
**Decision:** <what was chosen>
**Why:** <key reason>

## Trade-offs
- Pro: <benefit 1>
- Pro: <benefit 2>
- Con: <trade-off accepted>

## Rejected
- <Alternative 1> — <why rejected>
- <Alternative 2> — <why rejected>

## Means
<1-2 sentences about consequences and what needs to change>

<date>
```

## Field Rules

### Context
- Infer from the decision if not explicitly stated
- "Use JWT for auth" → Context: "Need stateless authentication for API"
- Keep to one sentence — this is a sticky note, not a design doc

### Decision
- One sentence, present tense, definitive
- Good: "Use WebSockets for bidirectional real-time communication."
- Bad: "We might want to consider WebSockets."

### Why
- The single most important reason
- Not a list — if multiple reasons, pick the strongest one
- The extended format has Trade-offs for additional reasoning

### Over (Alternatives)
- Comma-separated, brief
- If user doesn't mention alternatives → infer 1-2 common ones for that domain
- Max 3 alternatives

### Means (Consequences)
- What changes as a result of this decision
- What teams/code/infrastructure will be affected
- Infer from the decision domain if not stated
- "Use Redis for sessions" → Means: "Need to add Redis to infrastructure; session data is not persistent."
- Skip if consequences are obvious or trivial

### Supersedes
If search finds a related previous decision note:
- Add `**Supersedes:** <previous decision title>` after the title
- This creates an implicit decision history chain

## Formatting Rules

- Always **green** color (decisions are "settled" — green = done)
- Title MUST be actionable: "Use JWT for auth" not "Authentication"
- Date: human-readable, last line, no heading (e.g., "Feb 19, 2026")
- Default to compact format — use extended only when user gives enough detail for trade-offs
- If user only says the decision (no why) → infer reasoning from conversation context
- If no alternatives mentioned → infer 1-2 common alternatives for that domain
- Max 1 screenful — this is ADR-**lite**

## Examples

**Input:** `/decide Use WebSockets instead of SSE for real-time updates`
**Result:**
```markdown
# Use WebSockets for real-time updates

**Context:** Need real-time bidirectional communication for the app.
**Decision:** Use WebSockets for real-time communication.
**Why:** Need server push + client messages; SSE is server-to-client only.
**Over:** SSE (unidirectional), polling (high latency)
**Means:** Need WebSocket server infrastructure; handle reconnection logic.

Feb 19, 2026
```

**Input:** `/decide Store sessions in Redis with 24h TTL because we need shared state across instances and fast lookups. Considered Postgres but too slow for session checks, and in-memory won't work with multiple pods.`
**Result (extended):**
```markdown
# Use Redis for session storage

**Context:** Multiple pods need shared session state with fast lookups.
**Decision:** Store sessions in Redis with 24h TTL.
**Why:** Sub-millisecond reads + native cross-pod sharing.

## Trade-offs
- Pro: Sub-millisecond reads, built-in TTL
- Pro: Shared across all pods natively
- Con: Additional infrastructure dependency

## Rejected
- Postgres — Too slow for per-request session lookups
- In-memory — Doesn't share state across pods
- JWT (stateless) — Can't revoke sessions instantly

## Means
Need to add Redis to deployment. Sessions are ephemeral (24h); users re-authenticate after expiry.

Feb 19, 2026
```

**Input:** `/decide Use Swift concurrency over Combine`
**Result:**
```markdown
# Use Swift concurrency over Combine

**Context:** Choosing async pattern for the codebase.
**Decision:** Use async/await and structured concurrency instead of Combine.
**Why:** Native language feature, simpler API, better debuggability.
**Over:** Combine (verbose, harder to debug), RxSwift (third-party dependency)
**Means:** Existing Combine code migrated incrementally; new code uses async/await only.

Feb 19, 2026
```

**Input:** `/decide Switch from REST to GraphQL for the mobile API` (and search finds previous "Use REST for API" note)
**Result:**
```markdown
# Switch to GraphQL for mobile API
**Supersedes:** Use REST for API

**Context:** Mobile clients over-fetching data; multiple round-trips per screen.
**Decision:** Use GraphQL for the mobile API.
**Why:** Single request per screen, client-controlled data shape.
**Over:** REST with sparse fieldsets, BFF pattern (extra service layer)
**Means:** Need GraphQL server setup; mobile team learns new query patterns.

Feb 19, 2026
```

## Important

- One tool call for search, one for create — max 2 calls
- Do NOT ask for more details — work with what's given
- Compact format by default — developers don't read long ADRs
- Green color always
- Context → Decision → Why → Over → Means — this flow tells the complete story
- Supersedes creates decision history — always check for previous related decisions
