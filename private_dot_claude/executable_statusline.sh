#!/bin/bash
# Concise Claude Code statusline - single line format with colors
# cwd | git | model | ctx bar | cost | reset bar

input=$(cat)

HAS_JQ=0
command -v jq >/dev/null 2>&1 && HAS_JQ=1

# Colors
RST='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
# Foreground
BLUE='\033[38;5;75m'
GREEN='\033[38;5;114m'
YELLOW='\033[38;5;221m'
ORANGE='\033[38;5;209m'
PURPLE='\033[38;5;183m'
CYAN='\033[38;5;80m'
RED='\033[38;5;203m'
GRAY='\033[38;5;245m'

# Progress bar helper with color
bar() {
  pct="${1:-0}"; width="${2:-8}"; color="${3:-$GREEN}"
  [ "$pct" -lt 0 ] && pct=0; [ "$pct" -gt 100 ] && pct=100
  filled=$((pct * width / 100)); empty=$((width - filled))
  printf "${color}%s${DIM}%s${RST}" "$(printf '█%.0s' $(seq 1 $filled 2>/dev/null))" "$(printf '░%.0s' $(seq 1 $empty 2>/dev/null))"
}

# ---- extract data ----
if [ "$HAS_JQ" -eq 1 ]; then
  current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""' 2>/dev/null)
  model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"' 2>/dev/null)
  session_id=$(echo "$input" | jq -r '.session_id // ""' 2>/dev/null)
  cost_usd=$(echo "$input" | jq -r '.cost.total_cost_usd // empty' 2>/dev/null)
else
  current_dir=$(echo "$input" | grep -o '"current_dir"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
  model_name="Claude"
  session_id=""
  cost_usd=""
fi

# Format directory with ~ for home
cwd=$(echo "$current_dir" | sed "s|^$HOME|~|")
[ -z "$cwd" ] && cwd="~"

# Shorten model: "Claude Opus 4.5" -> "Op4.5", "Claude Sonnet 4" -> "Son4"
model_short=$(echo "$model_name" | sed -E 's/Claude //; s/Opus ([0-9.]+)/Op\1/; s/Sonnet ([0-9.]+)/Son\1/; s/Haiku ([0-9.]+)/Hai\1/')

# Git branch (full)
git_branch=""
if git rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git branch --show-current 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
fi

# Context remaining %
ctx_pct=""
if [ -n "$session_id" ] && [ "$HAS_JQ" -eq 1 ]; then
  current_dir_full=$(echo "$current_dir" | sed "s|^~|$HOME|")
  project_dir=$(echo "$current_dir_full" | sed 's|/|-|g; s|^-||')
  session_file="$HOME/.claude/projects/-${project_dir}/${session_id}.jsonl"

  if [ -f "$session_file" ]; then
    tokens=$(tail -20 "$session_file" | jq -r 'select(.message.usage) | .message.usage | ((.input_tokens // 0) + (.cache_read_input_tokens // 0))' 2>/dev/null | tail -1)
    if [ -n "$tokens" ] && [ "$tokens" -gt 0 ]; then
      ctx_pct=$(( 100 - (tokens * 100 / 200000) ))
    fi
  fi
fi

# Reset time and burn rate from ccusage
reset_time=""
reset_pct=""
burn_rate=""
if command -v ccusage >/dev/null 2>&1 && [ "$HAS_JQ" -eq 1 ]; then
  blocks=$(ccusage blocks --json 2>/dev/null)
  if [ -n "$blocks" ]; then
    reset_ts=$(echo "$blocks" | jq -r '.blocks[] | select(.isActive == true) | .endTime // empty' 2>/dev/null | head -1)
    start_ts=$(echo "$blocks" | jq -r '.blocks[] | select(.isActive == true) | .startTime // empty' 2>/dev/null | head -1)
    burn_rate=$(echo "$blocks" | jq -r '.blocks[] | select(.isActive == true) | .burnRate.costPerHour // empty' 2>/dev/null | head -1)
    if [ -n "$reset_ts" ] && [ "$reset_ts" != "null" ]; then
      reset_epoch=$(date -d "$reset_ts" +%s 2>/dev/null)
      start_epoch=$(date -d "$start_ts" +%s 2>/dev/null)
      if [ -n "$reset_epoch" ]; then
        now=$(date +%s)
        remaining=$((reset_epoch - now))
        if [ "$remaining" -gt 0 ]; then
          h=$((remaining / 3600))
          m=$(((remaining % 3600) / 60))
          reset_time="${h}h${m}m"
          # Calculate percentage of time elapsed
          if [ -n "$start_epoch" ]; then
            total=$((reset_epoch - start_epoch))
            [ "$total" -lt 1 ] && total=1
            elapsed=$((now - start_epoch))
            reset_pct=$((elapsed * 100 / total))
          fi
        fi
      fi
    fi
  fi
fi

# ---- render single line with colors ----
parts=()

# cwd - blue
parts+=("${BLUE}${cwd}${RST}")

# git branch - green
[ -n "$git_branch" ] && parts+=("${GREEN}${git_branch}${RST}")

# model - purple
parts+=("${PURPLE}${model_short}${RST}")

# context bar - color based on remaining %
if [ -n "$ctx_pct" ]; then
  if [ "$ctx_pct" -le 20 ]; then
    ctx_color=$RED
  elif [ "$ctx_pct" -le 40 ]; then
    ctx_color=$ORANGE
  else
    ctx_color=$CYAN
  fi
  ctx_bar=$(bar "$ctx_pct" 12 "$ctx_color")
  parts+=("${GRAY}ctx:${ctx_color}${ctx_pct}%${RST}[${ctx_bar}]")
fi

# reset time bar - orange (with session usage %)
if [ -n "$reset_time" ]; then
  if [ -n "$reset_pct" ]; then
    rst_bar=$(bar "$reset_pct" 12 "$ORANGE")
    parts+=("${GRAY}rst:${ORANGE}${reset_time}${RST}(${ORANGE}${reset_pct}%${RST})[${rst_bar}]")
  else
    parts+=("${GRAY}rst:${ORANGE}${reset_time}${RST}")
  fi
fi

# cost & burn rate - yellow/red (last)
if [ -n "$cost_usd" ] && [[ "$cost_usd" =~ ^[0-9.]+$ ]]; then
  cost_str="${YELLOW}\$$(printf '%.2f' "$cost_usd")${RST}"
  if [ -n "$burn_rate" ] && [[ "$burn_rate" =~ ^[0-9.]+$ ]]; then
    cost_str="${cost_str}(${RED}\$$(printf '%.1f' "$burn_rate")/h${RST})"
  fi
  parts+=("$cost_str")
fi

# Join with dim separator
sep="${DIM} | ${RST}"
output=""
for i in "${!parts[@]}"; do
  [ $i -gt 0 ] && output+="$sep"
  output+="${parts[$i]}"
done
echo -e "$output"
