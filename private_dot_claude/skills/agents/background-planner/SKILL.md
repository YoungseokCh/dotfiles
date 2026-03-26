---
name: planning-in-background
description: Orchestrates AI agents configured in ~/.agents/agents.toml for parallel planning in the background with auto-save. Agents continue running even when session hits context limits. Use for "백그라운드 기획", "bg plan", "병렬 기획", "멀티 AI 기획", "기획해줘", "N명이 기획", "계획", "플래닝", "plan", "설계" requests.
allowed-tools: Read, Bash, Grep, Glob, Task, Write, Edit, TodoWrite, AskUserQuestion, Agent
priority: high
tags: [planning, background, parallel-execution, autonomous, multi-llm, codex, gemini]
---

# Background Planner

Multi-LLM parallel planning with context-safe auto-save.

## Quick Start

```bash
# 1. Parse topic and perspectives
# 2. Create: .context/plans/
# 3. Determine round: R01, R02, ...
# 4. Run agents in background → {round}-{agent}.md
# 5. Track agent completion automatically
# 6. Merge when all agents complete (or on user request)
```

## Output Convention

```
.context/plans/
├── R01-claude.md          # Round 1: Claude's plan
├── R01-codex.md           # Round 1: Codex's plan
├── R01-gemini.md          # Round 1: Gemini's plan
├── R01-merged.md          # Round 1: merged plan
├── R02-claude.md          # Round 2: refined after feedback
└── R02-merged.md
```

**Round number** increments each planning iteration:
```bash
mkdir -p .context/plans
ROUND=$(printf "R%02d" $(( $(ls .context/plans/R*-*.md 2>/dev/null | sed 's/.*\/R\([0-9]*\)-.*/\1/' | sort -rn | head -1 | sed 's/^0*//') + 1 )))
```

## Agent Configuration

**Read `~/.agents/agents.toml`** for enabled agents and priority order.
See [common/AGENTS.md](../common/AGENTS.md) for the full resolution algorithm, invocation reference, and config schema.

### Resolution

1. Check `[skills.planner].priority` override, else use `[defaults].priority`
2. Walk priority left to right — skip disabled or uninstalled agents
3. Select up to `defaults.max_parallel` agents

> **Planner note:** All agents should use **read-only** mode (`exec_readonly` in config). Planners analyze — they don't write files.

## Workflow

### Step 1: Setup

```bash
mkdir -p .context/plans
ROUND=$(printf "R%02d" $(( $(ls .context/plans/R*-*.md 2>/dev/null | sed 's/.*\/R\([0-9]*\)-.*/\1/' | sort -rn | head -1 | sed 's/^0*//') + 1 )))
```

### Step 2: Run Agents (all with run_in_background)

Resolve agents from `~/.agents/agents.toml` (see [common/AGENTS.md](../common/AGENTS.md) for invocation details).

**IMPORTANT**: Use `run_in_background: true` on ALL agent launches. This provides automatic completion notifications without polling.

For each enabled agent in priority order:

**claude:**
```
Agent({
  subagent_type: "general-purpose",
  prompt: "기획 주제: ${topic}\n관점: ${perspective}\n결과 저장: .context/plans/${ROUND}-claude.md",
  run_in_background: true,
  name: "claude-planner"
})
```

**codex:**
```
Bash({
  command: "codex exec --full-auto --sandbox read-only \"${prompt}. Output the COMPLETE plan as markdown. Print the ENTIRE content directly.\" 2>/dev/null | sed '/^[[:space:]]*$/d' > .context/plans/${ROUND}-codex.md && wc -l .context/plans/${ROUND}-codex.md",
  run_in_background: true,
  timeout: 600000
})
```

**gemini:**
```
Bash({
  command: "gemini -p \"${prompt}\" -o text > .context/plans/${ROUND}-gemini.md 2>/dev/null && wc -l .context/plans/${ROUND}-gemini.md",
  run_in_background: true,
  timeout: 600000
})
```

**opencode:**
```
Bash({
  command: "opencode run -q -f text \"${prompt}\" > .context/plans/${ROUND}-opencode.md 2>/dev/null && wc -l .context/plans/${ROUND}-opencode.md",
  run_in_background: true,
  timeout: 600000
})
```

> See [common/AGENTS.md](../common/AGENTS.md) for per-agent CLI flags and gotchas.

### Step 3: Track Completion (AUTOMATIC)

Because all agents use `run_in_background: true`, the planner receives automatic notifications when each completes. No polling needed.

After launching all agents, display the tracking table and tell the user you will notify them:

```markdown
## Planning Agents Running (${ROUND})

| Agent  | Output | Status |
|--------|--------|--------|
| (per enabled agent) | .context/plans/${ROUND}-{agent}.md | ⏳ running |

I'll notify you as each agent completes. When all are done, say "머지해줘" to merge.
```

As each background task completes, verify the output quality:
```bash
# Check file exists and has substantial content (>20 lines)
wc -l .context/plans/${ROUND}-{agent}.md
```

If an agent produced less than 20 lines, report it as a failure and note why.

### Step 4: Merge (on request or when all complete)

Read all `${ROUND}-*.md` plan files and create `.context/plans/${ROUND}-merged.md`:
- Compare perspectives
- Highlight agreements/conflicts
- Synthesize final recommendation

## Best Practices

**DO:**
- Use 2-4 agents for diverse perspectives
- Always use `run_in_background: true` for automatic tracking
- Verify output quality (line count) on completion
- Report completion status to user as each agent finishes

**DON'T:**
- Use Codex `-o` flag (it only captures summaries)
- Use `nohup ... &` for background (use tool's `run_in_background` instead)
- Let Codex write files (always use `--sandbox read-only`)
- Poll for completion (notifications are automatic)
- Merge before all agents complete
