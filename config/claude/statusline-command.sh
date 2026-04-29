#!/usr/bin/env bash
# Claude Code status line
# Layout: Model | Context Gauge | Tokens | Git | Directory | Cost

input=$(cat)

# ANSI colors
green="\033[32m"
blue="\033[34m"
orange="\033[38;2;255;165;0m"
yellow="\033[33m"
red="\033[31m"
mauve="\033[38;2;203;166;247m"
git_color="\033[38;2;243;139;168m"
dim="\033[2m"
reset="\033[0m"

# Powerline separator (nerd font)
sep=$(printf '\xee\x82\xb1')

# Nerd font icons (printf to emit actual UTF-8 bytes)
icon_brain=$(printf '\xf3\xb0\xa7\x91')
icon_chart=$(printf '\xef\x88\x81')
icon_down=$(printf '\xef\x81\xa3')
icon_up=$(printf '\xef\x81\xa2')
icon_github=$(printf '\xef\x82\x9b')
icon_folder=$(printf '\xef\x81\xbb')
icon_dollar=$(printf '\xef\x85\x95')

# ── model segment ──────────────────────────────────────────────────────────────
model=$(echo "$input" | jq -r '.model.display_name // empty')
model_seg=""
if [ -n "$model" ]; then
  case "$model" in
    *Haiku*)  model_color="$green"  ;;
    *Sonnet*) model_color="$blue"   ;;
    *Opus*)   model_color="$orange" ;;
    *)        model_color="$reset"  ;;
  esac
  model_seg="${model_color}${icon_brain} ${model}${reset}"
fi

# ── context gauge segment ──────────────────────────────────────────────────────
# Block characters for partial fill (1/8 through 8/8)
# We use 10 cells × 8 sub-steps = 80 discrete levels across 0-100%
blocks=(' ' '▏' '▎' '▍' '▌' '▋' '▊' '▉' '█')

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_seg=""
if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  # Threshold coloring: <65 green, 65-75 yellow, >75 red
  if [ "$used_int" -lt 65 ]; then
    bar_color="$green"
  elif [ "$used_int" -le 75 ]; then
    bar_color="$yellow"
  else
    bar_color="$red"
  fi

  # Map 0-100% onto 0-80 eighths (10 cells × 8 sub-steps)
  eighths=$(( used_int * 80 / 100 ))
  [ "$eighths" -gt 80 ] && eighths=80
  full_cells=$(( eighths / 8 ))
  remainder=$(( eighths % 8 ))
  empty_cells=$(( 10 - full_cells - (remainder > 0 ? 1 : 0) ))

  bar=""
  for _ in $(seq 1 "$full_cells"); do bar="${bar}█"; done
  if [ "$remainder" -gt 0 ]; then
    bar="${bar}${blocks[$remainder]}"
  fi
  for _ in $(seq 1 "$empty_cells"); do bar="${bar} "; done

  ctx_seg="${bar_color}${icon_chart} ${bar} ${used_int}%${reset}"
fi

# ── token segment ──────────────────────────────────────────────────────────────
# Input (down arrow): current context input + [total session input]
# Output (up arrow):  current context output + [total session output]
cur_in=$(echo "$input"  | jq -r '.context_window.current_usage.input_tokens  // empty')
cur_out=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // empty')
tot_in=$(echo "$input"  | jq -r '.context_window.total_input_tokens  // empty')
tot_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')

token_seg=""
if [ -n "$cur_in" ] || [ -n "$tot_in" ]; then
  # Format numbers with k suffix for readability
  fmt_num() {
    local n="${1:-0}"
    if [ "$n" -ge 1000 ]; then
      printf "%dk" "$(( n / 1000 ))"
    else
      printf "%d" "$n"
    fi
  }
  ci=$(fmt_num "${cur_in:-0}")
  co=$(fmt_num "${cur_out:-0}")
  ti=$(fmt_num "${tot_in:-0}")
  to=$(fmt_num "${tot_out:-0}")

  token_seg="${blue}${icon_down} ${ci} ${dim}[${ti}]${reset} ${blue}${icon_up} ${co} ${dim}[${to}]${reset}"
fi

# ── git segment ───────────────────────────────────────────────────────────────
git_seg=""
raw_cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
if [ -n "$raw_cwd" ] && branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$raw_cwd" symbolic-ref --short HEAD 2>/dev/null); then
  dirty=$(GIT_OPTIONAL_LOCKS=0 git -C "$raw_cwd" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  git_seg="${git_color}${icon_github} ${branch}"
  [ "$dirty" -gt 0 ] && git_seg="${git_seg} ~${dirty}"
  git_seg="${git_seg}${reset}"
fi

# ── directory segment ──────────────────────────────────────────────────────────
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
dir_seg=""
if [ -n "$cwd" ]; then
  cwd_disp="${cwd/#$HOME/~}"
  dir_seg="${mauve}${icon_folder} ${cwd_disp}${reset}"
fi

# ── cost segment ───────────────────────────────────────────────────────────────
cost_seg=""
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$cost" ]; then
  cost_fmt=$(printf "%.4f" "$cost")
  cost_seg="${green}${icon_dollar} \$${cost_fmt}${reset}"
fi

# ── assemble ───────────────────────────────────────────────────────────────────
parts=()
[ -n "$model_seg" ] && parts+=("$model_seg")
[ -n "$ctx_seg" ]   && parts+=("$ctx_seg")
[ -n "$token_seg" ] && parts+=("$token_seg")
[ -n "$git_seg" ]   && parts+=("$git_seg")
[ -n "$dir_seg" ]   && parts+=("$dir_seg")
[ -n "$cost_seg" ]  && parts+=("$cost_seg")

out=""
for part in "${parts[@]}"; do
  if [ -n "$out" ]; then
    out="${out} ${reset}${sep} "
  fi
  out="${out}${part}"
done

printf "%b\n" "$out"
