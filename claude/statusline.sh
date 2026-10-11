#!/bin/bash
# Claude Code status line (Catppuccin Macchiato palette)
export PATH="/opt/homebrew/bin:/usr/bin:/bin:$PATH"

input=$(cat)

IFS=$'\t' read -r model dir used_pct tokens size < <(
  echo "$input" | jq -r '[
    (.model.display_name // .model.id // "Claude"),
    (.workspace.current_dir // .cwd // ""),
    (.context_window.used_percentage // "" | tostring),
    (.context_window.total_input_tokens // "" | tostring),
    (.context_window.context_window_size // "" | tostring)
  ] | @tsv' 2>/dev/null
)

fmt_k() {
  awk -v n="$1" 'BEGIN{
    if (n>=1000000) {s=sprintf("%.1f",n/1000000); sub(/\.0$/,"",s); print s "M"}
    else if (n>=1000) {s=sprintf("%.1f",n/1000); sub(/\.0$/,"",s); print s "k"}
    else print n }'
}

C_MODEL=$'\e[38;2;198;160;246m'  # mauve
C_DIR=$'\e[38;2;138;173;244m'    # blue
C_GIT=$'\e[38;2;166;218;149m'    # green
C_TXT=$'\e[38;2;165;173;203m'    # subtext0
C_SEP=$'\e[38;2;110;115;141m'    # overlay0
C_OK=$'\e[38;2;166;218;149m'
C_WARN=$'\e[38;2;238;212;159m'
C_BAD=$'\e[38;2;237;135;150m'
RST=$'\e[0m'
SEP="${C_SEP} | ${RST}"

out="${C_MODEL}${model}${RST}"

if [ -n "$used_pct" ]; then
  pct_int=$(printf '%.0f' "$used_pct")
  if   [ "$pct_int" -ge 85 ]; then cc=$C_BAD
  elif [ "$pct_int" -ge 60 ]; then cc=$C_WARN
  else cc=$C_OK; fi
  ctx="${cc}${pct_int}%${RST}"
  if [ -n "$tokens" ] && [ -n "$size" ] && [ "$size" != "0" ]; then
    ctx="$ctx ${C_TXT}($(fmt_k "$tokens")/$(fmt_k "$size"))${RST}"
  fi
  out="$out${SEP}${C_TXT}ctx ${RST}${ctx}"
else
  out="$out${SEP}${C_TXT}ctx --${RST}"
fi

if [ -n "$dir" ]; then
  out="$out${SEP}${C_DIR}$(basename "$dir")${RST}"
  branch=$(git -C "$dir" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null \
        || git -C "$dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  [ -n "$branch" ] && out="$out ${C_GIT}${branch}${RST}"
fi

printf '%s\n' "$out"
