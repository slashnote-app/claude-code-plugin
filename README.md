# /note — SlashNote Plugin for Claude Code

> Your coding companion: capture ideas, track tasks, run standups — all from the terminal.

SlashNote plugin adds 8 slash commands and 4 automatic hooks to Claude Code, turning [SlashNote](https://slashnote.app) sticky notes into your developer dashboard.

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

| Command | Category | What it creates |
|---------|----------|-----------------|
| `/note <text>` | Capture | Auto-typed sticky note (yellow/pink/blue/purple) |
| `/bugs <desc>` | Capture | Structured bug report with git context |
| `/snippet <code>` | Capture | Syntax-highlighted code snippet |
| `/focus <tasks>` | Workflow | Pinned focus note, optional auto-execute loop |
| `/pause` | Workflow | Pause, skip, or stop task loop |
| `/standup` | Reporting | Daily standup from git + notes |
| `/wrapup` | Reporting | Session summary with handoff notes |
| `/decisions <desc>` | Reporting | Architectural decision record (ADR-lite) |

## Skills Reference

### Capture

#### `/note <text>`

Quick capture — creates a sticky note with auto-detected type and color.

```
/note remember to update the API docs
/note - [ ] deploy staging - [ ] run smoke tests - [ ] merge to main
/note bug: login fails on Safari when cookies disabled
/note what if we used WebSockets instead of polling?
```

**Auto-detection rules** (first match wins):

| Pattern | Color | Format |
|---------|-------|--------|
| Checklist items (`- [ ]`, `- `, `1.`) | Peach | Checkboxes |
| Bug/error keywords | Pink | `# Bug:` heading |
| Idea keywords (maybe, what if, explore) | Blue | `# Idea` heading |
| Code patterns (backticks, `func`, `import`) | Purple | Code block |
| Everything else | Yellow | Plain text |

---

#### `/bugs <description>`

Structured bug report with git branch context.

```
/bugs login page crashes when password field is empty
/bugs API returns 500 on malformed JSON payload in /users endpoint
```

Creates a **pink** note with:
- Concise title (max 8 words)
- Summary, git branch, date
- Steps to Reproduce / Expected / Actual
- Uses smart placeholders when detail is insufficient

---

#### `/snippet <code or file:lines or description>`

Save a code snippet to a sticky note.

```
/snippet src/auth.swift:10-25
/snippet const debounce = (fn, ms) => { let t; return (...a) => { clearTimeout(t); t = setTimeout(() => fn(...a), ms) } }
/snippet the rate limiter middleware in server.ts
```

**Three input modes:**
1. **File path + lines:** `src/auth.swift:10-25` — reads and saves exact lines
2. **Inline code:** saves as-is
3. **Description:** searches codebase, extracts matching code

Creates a **purple** note with language tag, source path, and date. Max ~50 lines.

---

### Workflow

#### `/focus <task>` or `/focus Task1, Task2, Task3 --loop`

Set your current focus or start an automated task execution loop.

**Simple focus:**
```
/focus implement user authentication
/focus fix navbar, add dark mode, update tests
```

Creates/updates a **green pinned** note with your task(s) as checkboxes.

**Auto-execute loop:**
```
/focus fix login bug, add rate limiting, write API tests --loop
```

Starts sequential task execution:
1. Creates focus note with progress chart
2. Creates Claude Code tasks for each item
3. Executes tasks one by one
4. Updates checkboxes and chart as tasks complete
5. Blocks session exit until all tasks are done (or you `/pause stop`)

**Resume a paused loop:**
```
/focus --loop
```

---

#### `/pause` / `/pause skip` / `/pause stop`

Control the task execution loop.

| Command | Effect |
|---------|--------|
| `/pause` | Pause loop — keep progress, resume later with `/focus --loop` |
| `/pause skip` | Skip current task — marks as blocked, moves to next |
| `/pause stop` | Stop loop entirely — cancel remaining tasks |

---

### Reporting

#### `/standup` or `/standup --week`

Generate a daily standup summary.

```
/standup
/standup --week
```

Collects git commits + note activity and creates a **green** note:

```markdown
# Standup — Feb 18, 2026

## Done
- feat: add OAuth2 login flow
- fix: resolve token refresh race condition

## Today
- [ ] Deploy staging
- [ ] Write integration tests

## Blockers
- API rate limiting not configured
```

---

#### `/wrapup`

End-of-session summary with handoff notes for next time.

```
/wrapup
/wrapup spent most of the session debugging the WebSocket reconnection
```

Creates a **green** note with:
- **Accomplished:** completed work and merged PRs
- **Changes:** files/areas modified
- **In Progress:** uncompleted tasks
- **Next Session:** exact next steps (file names, function names, what to do)

---

#### `/decisions <description>`

Log an architectural decision (ADR-lite).

```
/decisions use PostgreSQL instead of MongoDB for the user service
/decisions chose server-side rendering with Next.js for SEO requirements
```

Creates a **purple** note with:
- **Context:** why the decision was needed
- **Decision:** what was decided
- **Reasoning:** trade-offs and rationale
- **Alternatives:** other options considered

Checks for duplicates before creating.

---

## Hooks

The plugin includes 4 automatic hooks that run without manual invocation:

| Hook | Trigger | What it does |
|------|---------|--------------|
| **SessionStart** | New Claude Code session | Injects git context + checks for pending tasks |
| **Stop** | Session end | Continues task loop if tasks remain |
| **TaskCompleted** | Any task completion | Auto-checks matching checkbox in focus note |
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

The `/focus --loop` feature turns Claude Code into an autonomous task executor with SlashNote as the visual dashboard.

### How it works

```
┌─────────────────────────────────────────────┐
│  /focus task1, task2, task3 --loop           │
│                                             │
│  1. Creates focus note with checkboxes      │
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
   /focus fix auth bug, add rate limiting, write tests --loop
   ```

2. **Watch progress** on the sticky note — checkboxes update in real time with a progress chart.

3. **Pause if needed:**
   - `/pause` — pause and resume later
   - `/pause skip` — skip a stuck task
   - `/pause stop` — cancel everything

4. **Resume a paused loop:**
   ```
   /focus --loop
   ```

5. **Loop ends** when all tasks are complete or stopped.

### Tips

- Keep tasks small and specific — "fix auth bug in login.swift" > "fix auth"
- Each task gets max 3 attempts before being marked as blocked
- Use `/pause skip` to move past a stuck task
- The progress chart on the sticky note shows real-time completion

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
   │   ├── bugs/SKILL.md
   │   ├── snippet/SKILL.md
   │   ├── focus/SKILL.md
   │   ├── pause/SKILL.md
   │   ├── standup/SKILL.md
   │   ├── wrapup/SKILL.md
   │   └── decisions/SKILL.md
   ├── hooks/
   │   ├── hooks.json
   │   ├── session-start.sh
   │   ├── stop-loop.sh
   │   ├── task-completed.sh
   │   └── pre-compact.sh
   └── scripts/
       └── git-context.sh
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
- Resume with `/focus --loop`
- Reset loop state: delete `.claude/slashnote-loop.local.md` and start fresh

**Hooks not firing:**
- Ensure the plugin is enabled in `~/.claude/settings.json`
- Check hook scripts are executable: `chmod +x ~/.claude/plugins/slashnote/hooks/*.sh`

**Slash commands not showing:**
- Restart Claude Code after plugin installation
- Verify plugin.json exists at `~/.claude/plugins/slashnote/.claude-plugin/plugin.json`

---

Made with ❤️ by [SlashNote](https://slashnote.app)
