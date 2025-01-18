# Load fzf integration
source <(fzf --zsh)

# Check for bat or batcat command
if command -v bat >/dev/null 2>&1; then
    BAT_CMD="bat"
elif command -v batcat >/dev/null 2>&1; then
    BAT_CMD="batcat"
else
    echo "Neither 'bat' nor 'batcat' is installed. Please install one of them for better file preview functionality."
    BAT_CMD=""
fi

# CTRL-Y to copy the command into clipboard using pbcopy
export FZF_CTRL_R_OPTS="
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'
  --height 80% --layout reverse"

# Preview file content using bat or batcat
if [ -n "$BAT_CMD" ]; then
    export FZF_CTRL_T_OPTS="
      --walker-skip .git,node_modules,target
      --preview '$BAT_CMD -n --color=always {}'
      --bind 'ctrl-/:change-preview-window(down|hidden|)'
      --height 80% --layout reverse"
else
    export FZF_CTRL_T_OPTS="
      --walker-skip .git,node_modules,target
      --preview 'echo \"Please install 'bat' or 'batcat' for preview functionality.\"'
      --height 80% --layout reverse"
fi

# Print tree structure in the preview window
export FZF_ALT_C_OPTS="
  --walker-skip .git,node_modules,target
  --preview 'tree -C {}'
  --height 80% --layout reverse"

# ripgrep->fzf->vim [QUERY]
rfv() (
  RELOAD='reload:rg --column --color=always --smart-case {q} || :'
  OPENER='if [[ $FZF_SELECT_COUNT -eq 0 ]]; then
            vim {1} +{2}     # No selection. Open the current line in Vim.
          else
            vim +cw -q {+f}  # Build quickfix list for the selected items.
          fi'
  
  fzf --disabled --ansi --multi \
      --bind "start:$RELOAD" --bind "change:$RELOAD" \
      --bind "enter:become:$OPENER" \
      --bind "ctrl-o:execute:$OPENER" \
      --bind 'alt-a:select-all,alt-d:deselect-all,ctrl-/:toggle-preview' \
      --delimiter : \
      --preview '$BAT_CMD --style=full --color=always --highlight-line {2} {1}' \
      --preview-window '~4,+{2}+4/3,<80(up)' \
      --query "$*"
)


autoload -Uz add-zsh-hook
add-zsh-hook precmd auto_activate