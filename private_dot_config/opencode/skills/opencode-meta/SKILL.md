---
name: opencode-meta
description: Defines OpenCode-native agents, subagents, skills, commands, and config. Use for creating or refining OpenCode automation such as agent markdown files, opencode.json settings, SKILL.md files, or reusable command prompts.
compatibility: opencode
metadata:
  priority: high
  tags: opencode,meta,agents,skills,commands,configuration
---

# OpenCode Meta

Create and refine OpenCode-native building blocks only.

This skill is for defining:
- Agents and subagents in `~/.config/opencode/agents/` or `.opencode/agents/`
- Skills in `~/.config/opencode/skills/<name>/SKILL.md` or `.opencode/skills/<name>/SKILL.md`
- Commands in `~/.config/opencode/commands/` or `.opencode/commands/`
- `opencode.json` configuration for permissions, models, agents, tools, and commands

Do not default to Claude-specific conventions unless the user explicitly asks for Claude compatibility.

## Core Rules

1. Prefer OpenCode-native paths and terminology.
2. Match the exact OpenCode docs format for frontmatter and config.
3. Keep generated prompts short, specific, and tool-aware.
4. Prefer the smallest correct config shape.
5. Use markdown-based agent or command files when the prompt body is non-trivial.
6. Use `opencode.json` when changing permissions, models, or small config-only overrides.
7. When a request mixes agent design and skill design, separate them clearly.

## What To Build

### Agents

Use agents when the user wants a reusable assistant persona with a dedicated prompt, model, permission set, or mode.

OpenCode agent locations:
- Global: `~/.config/opencode/agents/<name>.md`
- Project: `.opencode/agents/<name>.md`

Required agent frontmatter:
- `description`

Common agent fields:
- `mode`: `primary`, `subagent`, or `all`
- `model`
- `temperature`
- `top_p`
- `steps`
- `permission`
- `hidden`

Notes:
- The markdown filename becomes the agent name.
- Use `mode: subagent` for agents intended to be launched through the Task tool or `@` mention.
- Use `hidden: true` only for internal subagents that should not appear in autocomplete.
- Prefer `permission` over deprecated `tools`.

Minimal subagent example:

```md
---
description: Reviews API changes for security and correctness
mode: subagent
permission:
  edit: deny
  bash:
    "*": ask
    "git diff *": allow
    "git log*": allow
    "rg *": allow
---
Focus on authentication, authorization, input validation, and breaking behavior.
Return findings first, ordered by severity.
```

### Skills

Use skills when the user wants reusable instructions that other agents can load on demand through the native `skill` tool.

OpenCode skill locations:
- Global: `~/.config/opencode/skills/<name>/SKILL.md`
- Project: `.opencode/skills/<name>/SKILL.md`

Every skill must start with YAML frontmatter.

Required skill fields:
- `name`
- `description`

Optional skill fields:
- `license`
- `compatibility`
- `metadata`

Validation rules:
- `name` must match the directory name
- `name` must match `^[a-z0-9]+(-[a-z0-9]+)*$`
- `description` should be specific enough for the `skill` tool listing

Skill writing rules:
- Lead with what the skill does and when to use it
- Include concrete workflows, constraints, and examples
- Keep instructions executable, not aspirational
- Mention exact OpenCode file paths when relevant

Minimal skill example:

```md
---
name: docs-maintainer
description: Writes and updates OpenCode project documentation and command help text.
compatibility: opencode
metadata:
  tags: docs,markdown
---

# Docs Maintainer

Use this skill when updating repository docs, OpenCode command docs, or onboarding guides.

## Workflow

1. Read the target docs first.
2. Preserve existing terminology and structure.
3. Prefer concise examples over long explanations.
4. Update adjacent references if the command name or path changes.
```

### Commands

Use commands when the user wants a reusable slash command that expands into a prompt.

OpenCode command locations:
- Global: `~/.config/opencode/commands/<name>.md`
- Project: `.opencode/commands/<name>.md`

Common command frontmatter:
- `description`
- `agent`
- `model`
- `subtask`

Command rules:
- The markdown filename becomes the command name
- The body becomes the command template
- Use `$ARGUMENTS`, `$1`, `$2`, ... for argument placeholders
- Use `!\`command\`` only when shell output is genuinely needed in the prompt
- Prefer assigning a dedicated agent when the command is specialized

Minimal command example:

```md
---
description: Create a new OpenCode subagent
agent: build
---
Create a new OpenCode subagent named $1.
Put it in `.opencode/agents/$1.md`.
Use a short, precise description and a minimal prompt body.
```

### Config

Use `opencode.json` for global or project configuration when the request is about:
- default models
- agent overrides
- permissions
- commands declared in JSON
- providers, plugins, or instructions

Config rules:
- Prefer `permission` over deprecated `tools`
- Use the last-match-wins ordering for wildcard permission rules
- Put broad `"*"` rules first, then specific exceptions after
- Keep agent-specific overrides local to the agent when possible

Permission example:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "review": {
      "description": "Reviews code without making edits",
      "mode": "subagent",
      "permission": {
        "edit": "deny",
        "bash": {
          "*": "ask",
          "git diff *": "allow",
          "git log*": "allow"
        },
        "webfetch": "deny"
      }
    }
  }
}
```

## Decision Guide

Choose the smallest fitting artifact:

| Need | Best fit |
|------|----------|
| Reusable assistant persona | Agent |
| Reusable instructions loaded by other agents | Skill |
| Reusable slash prompt | Command |
| Global behavior or permissions | `opencode.json` |

When a user says:
- "make a planner/reviewer/debugger" -> create an agent
- "make a reusable workflow other agents can load" -> create a skill
- "make a slash command" -> create a command
- "change what an agent can do" -> update `permission` in config or agent frontmatter

## Workflow

1. Identify whether the target is an agent, subagent, skill, command, config change, or a combination.
2. Confirm the correct OpenCode location: global `~/.config/opencode/...` or project `.opencode/...`.
3. Generate the minimal valid frontmatter or JSON shape.
4. Write a prompt body that is explicit about scope, allowed actions, and output style.
5. If permissions are involved, prefer `permission` rules and keep them as narrow as practical.
6. Verify names, paths, and frontmatter fields against OpenCode docs.

## Guardrails

- Do not invent unsupported frontmatter keys for skills.
- Do not use deprecated `tools` unless the user explicitly asks for backward compatibility.
- Do not silently place OpenCode artifacts under `.claude/` unless dual compatibility is requested.
- Do not create both JSON and markdown definitions for the same thing unless there is a clear reason.
- Do not make a primary agent when a subagent is the better fit.

## Output Expectations

When creating OpenCode meta artifacts:
- state which artifact you are creating
- state where it should live
- emit valid frontmatter or JSON
- keep prompts concrete and brief
- mention any permissions or model assumptions explicitly
