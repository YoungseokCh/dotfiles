---
name: managing-context-worktree
description: Evaluates whether new work should stay on the current branch or move to an isolated git worktree. Uses <project_dir>/.worktree for worktrees, symlinks each worktree's .context to the project root, and updates .git/info/exclude for .worktree when needed.
compatibility: opencode
metadata:
  priority: medium
  tags: git,worktree,context,isolation,workflow
---

# Context Worktree

Create isolated git worktrees for unrelated work while keeping shared project context in one place.

## When to Activate

- Starting a new feature while another feature is already in progress
- Switching to a different issue, hotfix, or unrelated module
- The requested task does not match the current branch context

## Conventions

- **Worktree root:** `<project_dir>/.worktree`
- **Shared context source:** `<project_dir>/.context`
- **Per-worktree context path:** `<worktree_path>/.context` → symbolic link to `<project_dir>/.context`

## Workflow

### Step 1: Evaluate Similarity

Compare the new request against the current branch:
- File/module overlap
- Related issue or PR
- Whether the task is a follow-up to current work

**Similar:** stay on the current branch

**Different:** create a new worktree under `<project_dir>/.worktree`

### Step 2: Create the Worktree

```bash
PROJECT_DIR="$(git rev-parse --show-toplevel)"
WORKTREE_NAME="feature-name"
BRANCH_NAME="feature/feature-name"
WORKTREE_DIR="${PROJECT_DIR}/.worktree/${WORKTREE_NAME}"

mkdir -p "${PROJECT_DIR}/.worktree"
git worktree add "${WORKTREE_DIR}" -b "${BRANCH_NAME}"
```

### Step 3: Link Shared Context

If `<project_dir>/.context` exists, make every worktree reuse it:

```bash
PROJECT_DIR="$(git rev-parse --show-toplevel)"
WORKTREE_DIR="${PROJECT_DIR}/.worktree/feature-name"

if [ -e "${PROJECT_DIR}/.context" ] && [ ! -e "${WORKTREE_DIR}/.context" ]; then
  ln -s "${PROJECT_DIR}/.context" "${WORKTREE_DIR}/.context"
fi
```

If `<worktree_path>/.context` already exists and is not the expected symlink, inspect it before replacing anything.

### Step 4: Keep `.worktree` out of normal git status

If `.worktree` is being surfaced by git, ensure `.git/info/exclude` contains this entry:

```text
/.worktree/
```

Example check/update:

```bash
PROJECT_DIR="$(git rev-parse --show-toplevel)"
EXCLUDE_FILE="${PROJECT_DIR}/.git/info/exclude"

mkdir -p "$(dirname "${EXCLUDE_FILE}")"
touch "${EXCLUDE_FILE}"

if ! grep -qx '/.worktree/' "${EXCLUDE_FILE}"; then
  printf '\n/.worktree/\n' >> "${EXCLUDE_FILE}"
fi
```

> Note: `.git/info/exclude` only affects untracked files. If `.worktree` was already committed previously, stop tracking it separately before relying on the exclude rule.

## Commands

```bash
# List worktrees
git worktree list

# Add worktree under project-local directory
git worktree add "$(git rev-parse --show-toplevel)/.worktree/<name>" -b "<branch>"

# Remove worktree
git worktree remove "$(git rev-parse --show-toplevel)/.worktree/<name>"

# Prune stale metadata
git worktree prune
```

## Decision Matrix

| Current Work | New Request | Action |
|--------------|-------------|--------|
| Feature A | Bug in Feature A | Continue |
| Feature A | Feature B | New worktree |
| Feature A | Hotfix | New worktree |
| None | Any | Continue |

## Best Practices

**DO:**
- Use descriptive worktree names inside `.worktree/`
- Reuse the root `.context` via symlink instead of copying docs
- Check `.git/info/exclude` before assuming `.worktree` is ignored
- Clean up finished worktrees after merge

**DON'T:**
- Create worktrees for tiny, closely related edits
- Copy `.context` into each worktree
- Delete or overwrite an existing `.context` path in a worktree without checking it first
- Assume `.git/info/exclude` will untrack already committed files
