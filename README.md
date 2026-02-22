# /note — SlashNote Plugin for Claude Code

> Your coding companion: capture ideas, track tasks, run standups — all from the terminal.

SlashNote plugin adds 11 slash commands and 4 automatic hooks to Claude Code, turning [SlashNote](https://slashnote.app) sticky notes into your developer dashboard.

```
You: /note fix the auth token refresh before release
→ 📌 Pink sticky note appears on screen with structured bug report
```

## Quick Install

**Option A — From GitHub (recommended):**

```bash
claude plugin marketplace add slashnote-app/claude-code-plugin
claude plugin install slashnote
```

**Option B — Manual:**

```bash
git clone https://github.com/slashnote-app/claude-code-plugin.git ~/.claude/plugins/slashnote
```

Then add `"slashnote@local": true` to `~/.claude/settings.json` under `enabledPlugins`.

> Both options require SlashNote.app with MCP server enabled — see [Prerequisites](#prerequisites).

## What It Does

| Command | Category | Color | What it creates |
|---------|----------|-------|-----------------|
| `/note <text>` | Capture | auto | Auto-typed sticky note (confidence scoring) |
| `/todo <tasks>` | Capture | peach | Task list with priorities and deadlines |
| `/bug <desc>` | Capture | pink | Structured bug report with severity + git context |
| `/meeting <notes>` | Capture | blue | Meeting notes with decisions + action items |
| `/snippet <code>` | Capture | purple | Code snippet with language detection |
| `/decide <desc>` | Capture | green | Architectural decision record (Y-statement ADR) |
| `/note-loop <tasks>` | Workflow | green | Task execution loop — run, schedule, pause, stop |
| `/find <query>` | Workflow | — | Search across all notes with ranking |
| `/standup` | Reporting | green | Daily standup from git + notes + PRs |
| `/wrapup` | Reporting | green | Session summary with handoff notes |
| `/context` | Reporting | blue | Context snapshot for session continuity |

## Skills Reference

### Capture

#### `/note <text>`

Quick capture — creates a sticky note with auto-detected type and color using confidence scoring (minimum 2 points to trigger a category).

```
/note remember to update the API docs
/note - [ ] deploy staging - [ ] run smoke tests - [ ] merge to main
/note bug: login fails on Safari when cookies disabled
/note met with the team, decided to use JWT for auth
/note https://react.dev/learn — good tutorial
```

**Auto-detection** (confidence scoring, highest score wins):

| Category | Color | Signals |
|----------|-------|---------|
| Todo | Peach | Checkboxes, bullet lists, numbered items |
| Bug | Pink | crash, error, broken, fails + context |
| Meeting | Blue | met, discussed, agreed, standup |
| Snippet | Purple | Code patterns, backticks, `func`, `import` |
| Link | Blue | URLs (3 points — instant trigger) |
| Idea | Blue | maybe, what if, explore, consider |
| General | Yellow | Default when no category reaches 2 points |

Notes longer than 20 words get an auto-generated title.

---

#### `/todo <tasks>`

Smart task list with priority detection and time markers.

```
/todo Write tests, Update API docs, Deploy staging
/todo !Fix production crash ASAP
/todo !!Critical security patch needed today
/todo --append Add one more task to the latest list
```

| Feature | Syntax |
|---------|--------|
| Priority High | `!` prefix |
| Priority Critical | `!!` prefix |
| Time markers | `today`, `tomorrow`, `this week` — detected and shown |
| Append mode | `--append` — adds to the most recent peach note |

Creates a **peach** note with checkboxes and auto-generated context-aware title.

---

#### `/bug <description>`

Structured bug report with severity inference and git context.

```
/bug Login page crashes when password field is empty
/bug API returns 500 on malformed JSON — breaks checkout flow
/bug Wrong color on hover state in dark mode
```

**Severity auto-detection:**

| Keywords | Severity |
|----------|----------|
| crash, fatal, data loss | Critical |
| broken, fails, blocks, unusable | High |
| wrong, incorrect, unexpected | Medium |
| cosmetic, minor, typo | Low |

Creates a **pink** note: Title, Summary, Steps to Reproduce, Expected/Actual, Severity badge, `git diff --stat` context. Works without git too (non-git mode omits branch/diff).

---

#### `/meeting <notes>`

Meeting notes with automatic decision and action item extraction.

```
/meeting Sync with team: decided to deploy Friday, @Alex update changelog by Wednesday
/meeting Retro — agreed on 2-week sprints, @Sara owns migration plan, need to explore caching options
```

**Smart extraction:**
- **Decisions** detected by: "decided to", "agreed on", "going with", "chose"
- **Action items** with `@Owner` and deadline extraction from natural language
- **Key points** — everything else worth noting

Creates a **blue** note: `## Date` heading, Decisions, Action Items (`@Owner: task — deadline`), Key Points.

---

#### `/snippet <code or file:lines>`

Save a code snippet with language detection and optional annotation.

```
/snippet src/auth.swift:10-25
/snippet const debounce = (fn, ms) => { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms) } }
/snippet func validate(token: String) -> Bool { ... } -- JWT validation helper
```

**Two modes:**
1. **File reference:** `path:lines` — reads file, detects language from extension
2. **Inline code:** paste directly, language detected from syntax (`func` → Swift, `def` → Python, etc.)

Annotation separator `--` adds a "why I saved this" note below the code.

Creates a **purple** note: auto-generated title, syntax-highlighted code block, `source · date` footer. Max ~50 lines.

---

#### `/decide <description>`

Architectural decision record using Y-statement format.

```
/decide Use JWT instead of sessions for API authentication
/decide Chose PostgreSQL over MongoDB for the user service — need relational queries
```

**Compact format** (default):
```
Context → Decision → Why → Over (alternatives) → Means (consequences)
```

**Extended format** (for complex decisions — auto-detected):
- Adds **Trade-offs** and **Rejected** sections
- **Supersedes** chain links to previous related decisions

Creates a **green** note. Checks for duplicate decisions before creating.

---

### Workflow

#### `/note-loop`

Task execution loop — run, schedule, pause, skip, stop, and manage automated task loops.

**Start a loop with new tasks:**
```
/note-loop fix login bug, add rate limiting, write API tests
```

Creates a green pinned note with checkboxes, starts sequential execution immediately.

**Loop from existing note:**
```
/note-loop <note-uuid>
```

**Schedule for later (new Terminal session):**
```
/note-loop <note-uuid> --new-session 2h
```

**Resume a paused loop:**
```
/note-loop
```

**Control the loop:**

| Command | Effect |
|---------|--------|
| `/note-loop pause` | Immediate pause — resume later with `/note-loop` |
| `/note-loop pause after` | Graceful pause — finish current task, then stop |
| `/note-loop skip <reason>` | Skip current task with reason, move to next |
| `/note-loop stop <reason>` | Stop loop entirely, cancel remaining tasks |
| `/note-loop list` | List all active/scheduled loops |
| `/note-loop cancel <uuid>` | Cancel a scheduled loop |

Safety: `max_iterations = max(30, tasks × 3)`. Blocked tasks tracked with reasons.
Progress report on every pause/stop: `✓ Done · ⊘ Blocked · → Current (N% complete)`

---

#### `/find <query>`

Search across all notes with relevance ranking.

```
/find authentication
/find --type bug
/find JWT --type decide --pinned
```

| Flag | Effect |
|------|--------|
| `<query>` | Full-text search across note content |
| `--type <type>` | Filter by type: `todo`, `bug`, `meeting`, `snippet`, `decide` |
| `--pinned` | Only show pinned notes |

Flags are combinable. Ranking: pinned first → recency → content match.

If nothing found → suggests broadening the query → offers to create a new note.

---

### Reporting

#### `/standup` or `/standup --week` or `/standup --notes`

Generate a daily standup summary from git, notes, and PRs.

```
/standup                  # Git + notes since yesterday
/standup --week           # Weekly summary
/standup --notes          # Notes-only mode (no git required)
```

Creates a **green** note:

```markdown
# Standup Feb 18, 2026
5 commits, 12 files changed, 2 PRs

## Done
- Features: OAuth2 login, token refresh
- PR: "Add voice input" (merged)

## In Progress
- Skills plugin deep dive (9/12)

## Today
- Deploy staging
- Write integration tests

## Blockers
- API rate limiting not configured
```

Related commits are grouped by conventional commit prefix. Recommended max items per section: Done=10, In Progress=7, Today=5, Blockers=5.

---

#### `/wrapup` or `/wrapup --notes`

End-of-session summary with handoff notes.

```
/wrapup
/wrapup --notes
/wrapup spent most of the session debugging the WebSocket reconnection
```

Creates a **green** note with cross-reference analysis (git ↔ notes ↔ conversation):

- **Done:** completed work from git commits + note checkboxes
- **Decisions:** from `/decide` notes created this session
- **Changed:** files modified (`git diff --stat`, staged + unstaged)
- **Open:** unfinished tasks, open bugs, uncommitted changes
- **Risks:** uncommitted changes, blocked tasks, failing tests
- **Next:** specific next steps with `file:line` references

The "Next" section is the key handoff — each item answers: "What file, what function, what's left?"

---

#### `/context`

Save a snapshot of current session state for seamless handoff between Claude Code sessions.

```
/context
/context also need to check the WebSocket reconnection logic
```

Creates a **blue pinned** note:

```markdown
# Context Feb 19, 2026 01:15

**MyProject** @ `feature/auth` | 3 uncommitted changes

## Working On
Implementing JWT validation in auth middleware

## Key Files
- `src/auth.swift:45-80` — JWT parsing logic
- `src/middleware.ts` — auth middleware
- `tests/auth.test.ts` — new test cases

## State
- Branch: adding JWT authentication
- 2 staged, 1 modified, 0 untracked
- /note-loop: 5/8 tasks done

## Open Questions
- Should refresh tokens use separate storage?

## Resume With
Continue editing `src/auth.swift:80` — add token expiry check, then run tests
```

"Resume With" is the critical section — a fresh session reading only this line should know exactly what to do next.

---

## Hooks

The plugin includes 4 automatic hooks that run without manual invocation:

| Hook | Trigger | What it does |
|------|---------|--------------|
| **SessionStart** | New Claude Code session | Injects git context + checks for pending tasks |
| **Stop** | Session end | Continues task loop if tasks remain |
| **TaskCompleted** | Any task completion | Auto-checks matching checkbox in note-loop note |
| **PreCompact** | Before context compression | Saves session snapshot to a blue note |

Hooks communicate with SlashNote via its HTTP bridge (localhost:51423) and require no configuration.

## Prerequisites

1. **SlashNote.app** installed on your Mac — [Download from slashnote.app](https://slashnote.app)
2. **MCP server enabled** in SlashNote:
   - Click the SlashNote menu bar icon
   - Right-click → Settings → MCP → Enable MCP Server
3. **MCP server added to Claude Code:**
   ```bash
   claude mcp add slashnote -- /Applications/SlashNote.app/Contents/MacOS/slashnote-mcp
   ```

## Configuration

The plugin works out of the box. All configuration is optional.

**Task loop state** is stored in `.claude/slashnote-loop.local.md` (auto-created, safe to delete to reset).

**Hook timeouts:**
- SessionStart: 5 seconds
- All others: 10 seconds

**Max loop iterations:** 30 (safety limit to prevent runaway loops).

## Task Loop Guide

The `/note-loop` command turns Claude Code into an autonomous task executor with SlashNote as the visual dashboard.

### How it works

```
┌─────────────────────────────────────────────┐
│  /note-loop task1, task2, task3             │
│                                             │
│  1. Creates note-loop note with checkboxes   │
│  2. Creates Claude Code tasks               │
│  3. Starts executing task1                  │
│                                             │
│  ┌──── Loop ────────────────────────────┐   │
│  │  Execute current task                │   │
│  │  ↓                                   │   │
│  │  Task complete → checkbox ✅          │   │
│  │  ↓                                   │   │
│  │  Stop hook fires → finds next task   │   │
│  │  ↓                                   │   │
│  │  Block exit → execute next task      │   │
│  │  ↓                                   │   │
│  │  Repeat until all done               │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  All done → exit normally                   │
└─────────────────────────────────────────────┘
```

### Step by step

1. **Start the loop:**
   ```
   /note-loop fix auth bug, add rate limiting, write tests
   ```

2. **Watch progress** on the sticky note — checkboxes update in real time.

3. **Pause if needed:**
   - `/note-loop pause` — pause and resume later
   - `/note-loop skip` — skip a stuck task
   - `/note-loop stop` — cancel everything

4. **Resume a paused loop:**
   ```
   /note-loop
   ```

5. **Loop ends** when all tasks are complete or stopped.

### Tips

- Keep tasks small and specific — "fix auth bug in login.swift" > "fix auth"
- Each task gets max 3 attempts before being marked as blocked
- Use `/note-loop skip` to move past a stuck task
- The checkboxes on the sticky note update in real-time as tasks complete

## Manual Installation

If you prefer not to use the GitHub marketplace:

1. Clone or copy the plugin files to `~/.claude/plugins/slashnote/`
2. The directory structure should be:
   ```
   ~/.claude/plugins/slashnote/
   ├── .claude-plugin/
   │   └── plugin.json
   ├── skills/
   │   ├── note/SKILL.md
   │   ├── todo/SKILL.md
   │   ├── bug/SKILL.md
   │   ├── meeting/SKILL.md
   │   ├── snippet/SKILL.md
   │   ├── decide/SKILL.md
   │   ├── note-loop/SKILL.md
   │   ├── find/SKILL.md
   │   ├── standup/SKILL.md
   │   ├── wrapup/SKILL.md
   │   └── context/SKILL.md
   ├── hooks/
   │   ├── hooks.json
   │   ├── session-start.sh
   │   ├── stop-loop.sh
   │   ├── task-completed.sh
   │   └── pre-compact.sh
   └── scripts/
       └── git-context.sh    # Git utilities for hooks
   ```
3. Add to `~/.claude/settings.json`:
   ```json
   {
     "enabledPlugins": {
       "slashnote@local": true
     }
   }
   ```
4. Restart Claude Code.

## Uninstall

**If installed via marketplace:**
```bash
claude plugin uninstall slashnote
```

**If installed manually:**
```bash
rm -rf ~/.claude/plugins/slashnote
```

Then remove `"slashnote@local": true` from `~/.claude/settings.json`.

## Troubleshooting

**Notes don't appear:**
- Check SlashNote.app is running (menu bar icon visible)
- Check MCP server is enabled: right-click SlashNote icon → Settings → MCP
- Test MCP connection: in Claude Code, try asking "list my notes" — the `list_notes` tool should work

**"MCP server not found" error:**
- Verify the path: `ls /Applications/SlashNote.app/Contents/MacOS/slashnote-mcp`
- Re-add the MCP server: `claude mcp add slashnote -- /Applications/SlashNote.app/Contents/MacOS/slashnote-mcp`

**Task loop doesn't continue:**
- Check `.claude/slashnote-loop.local.md` exists and contains valid JSON
- Resume with `/note-loop`
- Reset loop state: delete `.claude/slashnote-loop.local.md` and start fresh

**Hooks not firing:**
- Ensure the plugin is enabled in `~/.claude/settings.json`
- Check hook scripts are executable: `chmod +x ~/.claude/plugins/slashnote/hooks/*.sh`

**Slash commands not showing:**
- Restart Claude Code after plugin installation
- Verify plugin.json exists at `~/.claude/plugins/slashnote/.claude-plugin/plugin.json`

---

Made with ❤️ by [SlashNote](https://slashnote.app)
