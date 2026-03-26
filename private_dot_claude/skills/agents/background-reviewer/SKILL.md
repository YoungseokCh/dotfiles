---
name: background-reviewer
description: Orchestrates multi-LLM parallel code review using agents configured in ~/.agents/agents.toml. Each agent reviews from a different perspective using agent personas (security, architecture, code quality, performance). Use for "코드 리뷰", "리뷰해줘", "bg review", "멀티 리뷰", "background review", "페르소나 리뷰" requests.
allowed-tools: Read, Bash, Grep, Glob, Task, Write, Edit, AskUserQuestion
priority: high
tags: [review, code-review, background, parallel-execution, codex, gemini, multi-llm, quality, persona]
---

# Background Reviewer

Multi-LLM parallel code review with specialized agent personas.

## Quick Start

```bash
# 1. Determine review scope and round number
# 2. Create: .context/reviews/
# 3. Run review agents with personas in background
# 4. Each persona saves findings to {round}-{persona}.md
# 5. Merge into prioritized findings when ready
```

## Output Convention

```
.context/reviews/
├── R01-security-reviewer.md        # Round 1: security persona
├── R01-architecture-reviewer.md    # Round 1: architecture persona
├── R01-code-quality-reviewer.md    # Round 1: code quality persona
├── R01-performance-reviewer.md     # Round 1: performance persona
├── R01-merged.md                   # Round 1: merged findings
├── R02-security-reviewer.md        # Round 2: after fixes, re-review
└── R02-merged.md
```

**Round number** increments each time reviews are run (R01 = first pass, R02 = after fixes, R03 = final check).

Detect next round:
```bash
ROUND=$(printf "R%02d" $(( $(ls .context/reviews/R*-*.md 2>/dev/null | sed 's/.*\/R\([0-9]*\)-.*/\1/' | sort -rn | head -1 | sed 's/^0*//') + 1 )))
# → R01, R02, R03, ...
```

## Persona-Based Review (Recommended)

Each reviewer adopts a detailed agent persona from `.agents/personas/` or `~/.agents/personas/`. Personas define identity, review lens, evaluation framework, and output format — producing consistent, specialized reviews.

### Available Personas

```bash
agt persona list                    # See all available personas
agt persona show security-reviewer  # Preview a persona's focus
```

| Persona | Role | Focus |
|---------|------|-------|
| `security-reviewer` | Senior AppSec Engineer | OWASP, auth, injection, data exposure |
| `architecture-reviewer` | Principal Architect | SOLID, coupling, API design, layer violations |
| `code-quality-reviewer` | Staff Engineer | Readability, complexity, DRY, test coverage |
| `performance-reviewer` | Performance Engineer | Memory, CPU, I/O, scalability |

Custom personas can be created for project-specific needs:
```bash
agt persona create db-reviewer --gemini "DBA with 15yr PostgreSQL optimization"
agt persona create frontend-a11y --ai "React accessibility specialist"
```

### Persona Quick Review (Single)

```bash
# Single persona review with auto-detected LLM
agt persona review security-reviewer

# Specify LLM
agt persona review security-reviewer --gemini
agt persona review architecture-reviewer --codex

# Review only staged changes
agt persona review security-reviewer --staged

# Compare against a branch
agt persona review security-reviewer --base main

# Save to file with round naming
ROUND=$(printf "R%02d" $(( $(ls .context/reviews/R*-*.md 2>/dev/null | sed 's/.*\/R\([0-9]*\)-.*/\1/' | sort -rn | head -1 | sed 's/^0*//') + 1 )))
agt persona review security-reviewer -o ".context/reviews/${ROUND}-security-reviewer.md"
```

### Parallel Persona Review (Multi-LLM)

Run multiple personas simultaneously, each on a different LLM:

```bash
mkdir -p .context/reviews
ROUND=$(printf "R%02d" $(( $(ls .context/reviews/R*-*.md 2>/dev/null | sed 's/.*\/R\([0-9]*\)-.*/\1/' | sort -rn | head -1 | sed 's/^0*//') + 1 )))

# Launch all personas in parallel — each on a different LLM
agt persona review security-reviewer --gemini -o ".context/reviews/${ROUND}-security-reviewer.md" &
agt persona review architecture-reviewer --codex -o ".context/reviews/${ROUND}-architecture-reviewer.md" &
agt persona review code-quality-reviewer --gemini -o ".context/reviews/${ROUND}-code-quality-reviewer.md" &
agt persona review performance-reviewer --codex -o ".context/reviews/${ROUND}-performance-reviewer.md" &
wait

echo "Round ${ROUND} reviews complete"
ls -la .context/reviews/${ROUND}-*.md
```

### Persona Review via Claude Task Agent

For Claude Code sessions, use Task agents with persona content:

```typescript
// Read persona file and pass as context
Task({
  subagent_type: "general-purpose",
  prompt: `Adopt this persona completely and review the current git changes:

$(cat .agents/personas/security-reviewer.md)

Review the git diff (git diff HEAD) from this persona's perspective.
Use the persona's Output Format for your review.
Save to .context/reviews/${ROUND}-security-reviewer.md`,
  run_in_background: true
})
```

## Agent Configuration

**Read `~/.agents/agents.toml`** for enabled agents and priority order.
See [common/AGENTS.md](../common/AGENTS.md) for the full resolution algorithm, invocation reference, and config schema.

### Resolution

1. Check `[skills.reviewer].priority` override, else use `[defaults].priority`
2. Walk priority left to right — skip disabled or uninstalled agents
3. Select up to `defaults.max_parallel` agents

### Default Perspectives per Agent

| Agent | Perspective |
|-------|-------------|
| **Codex** | Code quality + bugs, race conditions, edge cases |
| **Claude** | Architecture + security, OWASP, deep analysis |
| **Gemini** | UX + documentation + types, API consistency |

## Review Scopes

### 1. Branch Diff Review (most common)
```bash
# Review changes between current branch and main
git diff main...HEAD > /tmp/review-diff.txt
```

### 2. Uncommitted Changes Review
```bash
# Review staged + unstaged changes
git diff > /tmp/review-diff.txt
git diff --cached >> /tmp/review-diff.txt
```

### 3. Specific Files Review
```bash
# Review specific files or directories
cat src/flows/engine/*.ts > /tmp/review-target.txt
```

## Workflow

### Step 1: Setup Review Session

```bash
mkdir -p .context/reviews
ROUND=$(printf "R%02d" $(( $(ls .context/reviews/R*-*.md 2>/dev/null | sed 's/.*\/R\([0-9]*\)-.*/\1/' | sort -rn | head -1 | sed 's/^0*//') + 1 )))

# Generate diff for reviewers
git diff main...HEAD > ".context/reviews/${ROUND}-diff.patch"

# List changed files
git diff --name-only main...HEAD > ".context/reviews/${ROUND}-changed-files.txt"
```

### Step 2: Create Review Brief

Write `.context/reviews/${ROUND}-brief.md`:
```markdown
# Review Brief (${ROUND})
- Branch: feat/dashboard
- Base: main
- Changed files: (list)
- Focus areas: (optional user-specified)
```

### Step 3: Launch Review Agents

Resolve agents from `~/.agents/agents.toml` (see [common/AGENTS.md](../common/AGENTS.md) for invocation details).

For each enabled agent in priority order, launch with review-specific prompts:

**codex:**
```bash
nohup codex exec --full-auto \
  --add-dir .context/reviews \
  "Review the git diff between main and HEAD. Focus on:
   1. Bugs and logic errors  2. Race conditions and edge cases
   3. Error handling gaps  4. Performance issues  5. Type safety
   Save review to .context/reviews/${ROUND}-codex.md
   Format: ## Category / ### Finding / severity + description + suggestion" \
  > .context/reviews/${ROUND}-codex.log 2>&1 &
```

**claude:**
```typescript
Agent({
  subagent_type: "general-purpose",
  prompt: `You are a senior security and architecture reviewer.
Read the review brief: .context/reviews/${ROUND}-brief.md
Read changed files listed in: .context/reviews/${ROUND}-changed-files.txt
Review focus: Security (OWASP), Architecture (SOLID), API design, Data integrity, Backward compatibility.
Save to .context/reviews/${ROUND}-claude.md
Format: ## Category / ### Finding / Severity / Description / Suggestion`,
  run_in_background: true
})
```

**gemini:**
```bash
nohup gemini -p "Review files changed between main and HEAD. Focus on:
API consistency, TypeScript type safety, component patterns, documentation gaps, DRY violations.
Format: ## Category / ### Finding / severity + description + suggestion" \
  -o text > .context/reviews/${ROUND}-gemini.md 2>/dev/null &
```

**opencode:**
```bash
nohup opencode run -q -f text \
  "Review the git diff between main and HEAD. Focus on bugs, type safety, and code quality. Format as ## Category / ### Finding / severity + description + suggestion" \
  > .context/reviews/${ROUND}-opencode.md 2>/dev/null &
```

> See [common/AGENTS.md](../common/AGENTS.md) for per-agent CLI flags and gotchas.

### Step 4: Guide User

```markdown
## Review Agents Running (${ROUND})

| Agent  | Output |
|--------|--------|
| (per enabled agent) | .context/reviews/${ROUND}-{agent}.md |

Check progress:
- `ls .context/reviews/${ROUND}-*.md`

When ready: "머지해줘" or "리뷰 결과 확인"
```

### Step 5: Merge Reviews (on request)

Read all `${ROUND}-*.md` review files and create `.context/reviews/${ROUND}-merged.md`:

```markdown
# Code Review Summary (${ROUND})

## Critical Findings (must fix)
- [Finding from any agent, deduplicated]

## High Priority
- [...]

## Medium Priority
- [...]

## Low Priority / Suggestions
- [...]

## Agreements (multiple agents flagged)
- [Findings that 2+ agents independently identified]

## Statistics
- Total findings: N
- Critical: N, High: N, Medium: N, Low: N
- By agent: Codex N, Claude N, Gemini N
```

## Output Structure

```
.context/reviews/
├── R01-brief.md                     # Round 1 review brief
├── R01-diff.patch                   # Round 1 diff snapshot
├── R01-changed-files.txt            # Round 1 changed files
├── R01-security-reviewer.md         # Round 1 persona review
├── R01-architecture-reviewer.md     # Round 1 persona review
├── R01-codex.md                     # Round 1 generic agent review
├── R01-claude.md                    # Round 1 generic agent review
├── R01-gemini.md                    # Round 1 generic agent review
├── R01-merged.md                    # Round 1 merged findings
├── R02-security-reviewer.md         # Round 2 re-review after fixes
├── R02-codex.md
└── R02-merged.md                    # Round 2 merged
```

## Best Practices

**DO:**
- Use agents in priority order from `~/.agents/agents.toml`
- Generate diff/file lists before launching agents
- Let agents review independently for diverse findings
- Deduplicate when merging (same issue found by multiple agents = higher confidence)

**DON'T:**
- Skip the review brief (agents need context)
- Run review on 1000+ line diffs without splitting
- Ignore findings that multiple agents agree on
- Auto-fix critical findings without human review

## Severity Guidelines

| Severity | Definition | Action |
|----------|-----------|--------|
| **Critical** | Security vulnerability, data loss risk, crash bug | Must fix before merge |
| **High** | Logic error, missing validation, breaking change | Should fix before merge |
| **Medium** | Code smell, poor naming, missing error handling | Fix in follow-up |
| **Low** | Style issue, minor optimization, suggestion | Optional |
