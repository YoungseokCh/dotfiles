# Shared Agent Configuration

All background skills (implementer, planner, reviewer) share a common agent registry at `~/.agents/agents.toml`. Skills MUST read this file to determine which agents to use.

## Config Location

```
~/.agents/agents.toml
```

## Resolution Algorithm

1. Read `~/.agents/agents.toml`
2. Check `[skills.<skill-name>].priority` for a per-skill override; fall back to `[defaults].priority`
3. Walk the priority list left to right:
   - Skip if `agents.<name>.enabled = false`
   - Skip if `agents.<name>.type = "cli"` and `command` is not found on `$PATH`
   - Select the agent (up to `defaults.max_parallel` agents total)
4. For each selected agent, use the matching invocation pattern below

## Agent Invocation Reference

### claude (type = builtin)

Runs inside Claude Code as a subagent — no external CLI.

**Implementation / Planning:**
```typescript
Agent({
  subagent_type: "general-purpose",
  prompt: "<task prompt>. Save output to <output-path>",
  run_in_background: true,
  name: "claude-<role>"
})
```

**Review:**
```typescript
Agent({
  subagent_type: "feature-dev:code-reviewer",
  prompt: "<review prompt>. Save output to <output-path>",
  run_in_background: true
})
```

### codex (type = cli)

**Implementation (writes files):**
```bash
nohup codex exec --full-auto \
  -C <workdir> \
  --add-dir <extra-write-path> \
  -o <output-path> \
  "<prompt>" \
  > <log-path> 2>&1 &
```
- Use git worktrees for parallel Codex agents to avoid file conflicts
- Use absolute paths for files outside the worktree

**Planning (read-only):**
```bash
codex exec --full-auto --sandbox read-only \
  "<prompt>. Print the COMPLETE output as markdown." \
  2>/dev/null | sed '/^[[:space:]]*$/d' > <output-path>
```
- Do NOT use `-o` for planning — it only captures the summary, not full content
- Pipe stdout instead

**Review:**
```bash
nohup codex exec --full-auto \
  --add-dir <review-dir> \
  "<review prompt>. Save review to <output-path>" \
  > <log-path> 2>&1 &
```

### gemini (type = cli)

**Implementation (writes files):**
```bash
nohup gemini -p "<prompt>" \
  --yolo -o text > <log-path> 2>/dev/null &
```
- `--yolo` auto-approves file writes (required for background)

**Planning / Review (read-only):**
```bash
nohup gemini -p "<prompt>" \
  -o text > <output-path> 2>/dev/null &
```

**Notes:**
- Do NOT use `-s` (that is `--sandbox`, not silent)
- Redirect stdout to capture output

### opencode (type = cli)

```bash
nohup opencode run -q -f text "<prompt>" \
  > <output-path> 2>/dev/null &
```
- `-q` suppresses spinner, `-f text` outputs plain text
- Use `--attach http://localhost:PORT` to reuse running server

### ollama (type = cli)

```bash
echo "<prompt>" | ollama run <model> > <output-path> 2>/dev/null
```
- Model from `agents.ollama.model` (default: `llama3.2`)
- Fully local, no API keys

## Background Execution Patterns

**Claude:** Use `run_in_background: true` on Agent/Task — automatic completion notification.

**CLI agents:** Use `Bash({ command: "...", run_in_background: true, timeout: 600000 })` — automatic completion notification. Preferred over `nohup ... &` because it integrates with Claude Code's background tracking.

**Fallback (nohup):** Use `nohup <cmd> > <log> 2>&1 &` when Bash background is unavailable.

## Config Schema Quick Reference

```toml
[defaults]
priority = ["claude", "codex", "gemini"]   # global fallback order
max_parallel = 3                            # max concurrent agents

[agents.<name>]
enabled = true/false
type = "builtin" | "cli"
command = "<binary>"          # cli only — checked via `which`
exec = "<template>"           # write mode command template
exec_readonly = "<template>"  # read-only mode command template
review = "<template>"         # review mode command template (optional)
model = "<model-name>"        # ollama only
strengths = [...]             # informational tags
notes = "..."                 # agent-specific gotchas

[skills.<skill-name>]
priority = [...]              # per-skill override
```
