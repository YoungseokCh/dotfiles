---
name: implementing-in-background
description: Orchestrates AI agents configured in ~/.agents/agents.toml for parallel implementation in the background. Separates independent tasks from planning docs, each agent writes code directly. Context-safe with auto-save. Use for "백그라운드 구현", "bg impl", "병렬 구현", "구현해줘", "코드 작성해줘" requests.
allowed-tools: Read, Bash, Grep, Glob, Task, Write, Edit, TodoWrite, AskUserQuestion
priority: high
tags: [implementation, background, parallel-execution, autonomous, codex, gemini, multi-llm]
---

# Background Implementer

Multi-LLM background implementation with context-safe parallel execution.

## Quick Start

```bash
# 1. Analyze planning doc → extract tasks
# 2. Create output dir: .context/impl/
# 3. Determine round: R01, R02, ...
# 4. Run agents in background → {round}-{agent}.md
# 5. Guide user to check results manually
```

## Output Convention

```
.context/impl/
├── R01-tasks.md               # Round 1: task decomposition
├── R01-claude.md              # Round 1: Claude's implementation notes
├── R01-codex.md               # Round 1: Codex's implementation notes
├── R01-gemini.md              # Round 1: Gemini's implementation notes
├── R01-summary.md             # Round 1: merged summary
├── R02-claude.md              # Round 2: fixes/iterations
└── R02-summary.md
```

**Round number** increments each implementation iteration:
```bash
mkdir -p .context/impl
ROUND=$(printf "R%02d" $(( $(ls .context/impl/R*-*.md 2>/dev/null | sed 's/.*\/R\([0-9]*\)-.*/\1/' | sort -rn | head -1 | sed 's/^0*//') + 1 )))
```

## Agent Configuration

**Read `~/.agents/agents.toml`** for enabled agents and priority order.
See [common/AGENTS.md](../common/AGENTS.md) for the full resolution algorithm, invocation reference, and config schema.

### Resolution

1. Check `[skills.implementer].priority` override, else use `[defaults].priority`
2. Walk priority left to right — skip disabled or uninstalled agents
3. Select up to `defaults.max_parallel` agents

## Workflow

### Step 1: Analyze & Decompose

Extract from planning docs:
- DB migrations (independent)
- Models (depends on migration)
- Handlers (depends on models)
- Frontend (often independent)

### Step 2: Wave Execution

```
Wave 1 (parallel): Migration + Frontend + Types
Wave 2 (after migration): Models
Wave 3 (after models): Handlers
```

### Step 3: Run Agents

Resolve agents from `~/.agents/agents.toml` (see [common/AGENTS.md](../common/AGENTS.md) for invocation details).

```bash
mkdir -p .context/impl
ROUND=$(printf "R%02d" $(( $(ls .context/impl/R*-*.md 2>/dev/null | sed 's/.*\/R\([0-9]*\)-.*/\1/' | sort -rn | head -1 | sed 's/^0*//') + 1 )))
```

For each enabled agent in priority order, launch with `run_in_background: true`:

**claude:**
```typescript
Agent({
  subagent_type: "general-purpose",
  prompt: `Read task file: .context/impl/${ROUND}-tasks.md
Implement the assigned tasks and save implementation notes to .context/impl/${ROUND}-claude.md`,
  run_in_background: true
})
```

**codex:**
```bash
# Use git worktrees for parallel Codex agents
PROJ_DIR="$(pwd)"
nohup codex exec --full-auto \
  -C <worktree-path> \
  --add-dir "${PROJ_DIR}/.context/impl" \
  -o "${PROJ_DIR}/.context/impl/${ROUND}-codex.md" \
  "Read task file at ${PROJ_DIR}/.context/impl/${ROUND}-tasks.md and implement all described changes." \
  > "${PROJ_DIR}/.context/impl/${ROUND}-codex.log" 2>&1 &
```

**gemini:**
```bash
nohup gemini -p "Implement tasks from .context/impl/${ROUND}-tasks.md" \
  --yolo -o text > .context/impl/${ROUND}-gemini.log 2>/dev/null &
```

**opencode:**
```bash
nohup opencode run -q -f text \
  "Read task file .context/impl/${ROUND}-tasks.md and implement all described changes." \
  > .context/impl/${ROUND}-opencode.log 2>/dev/null &
```

> See [common/AGENTS.md](../common/AGENTS.md) for per-agent CLI flags and gotchas.

### Step 4: Guide User (NO MONITORING)

**IMPORTANT:** Don't poll for completion. Output this guide:

```markdown
## Agents Running (${ROUND})

| Agent  | Output |
|--------|--------|
| (per enabled agent) | .context/impl/${ROUND}-{agent}.md |

Check results manually:
- `ls .context/impl/${ROUND}-*.md`
- `git status`

When done, ask me to "확인해줘" or "빌드 체크"
```

## Token Efficiency

1. **Input**: Write task instructions to `.md` file, pass path only
2. **Output**: Agents save structured markdown summaries
3. **Verify**: Read summaries only, not full output

See [references/token-efficiency.md](references/token-efficiency.md) for details.

## Output Structure

```
.context/impl/
├── R01-tasks.md              # Round 1: task decomposition
├── R01-claude.md             # Round 1: Claude implementation notes
├── R01-codex.md              # Round 1: Codex implementation notes
├── R01-gemini.md             # Round 1: Gemini test/review notes
├── R01-summary.md            # Round 1: merged summary
├── R02-tasks.md              # Round 2: follow-up tasks
├── R02-claude.md
└── R02-summary.md
```

## Best Practices

**DO:**
- Use markdown files for task instructions
- Respect dependency order (migration → models → handlers)
- Let user check completion manually

**DON'T:**
- Poll TaskOutput repeatedly (token waste)
- Run 10+ agents simultaneously
- Have multiple agents edit same file

## References

- [Provider setup & CLI install](references/providers.md)
- [Agent prompt templates](references/templates.md)
- [Wave execution strategy](references/parallel-patterns.md)
- [Token efficiency patterns](references/token-efficiency.md)
