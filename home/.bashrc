#
# ~/.bashrc
#

export EDITOR="nvim"
export VISUAL="nvim"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias agyd='agy --dangerously-skip-permissions'
PS1='[\u@\h \W]\$ '

# Prevent commands containing "ytplay" or "instagram-cli" from being saved to bash history
export HISTIGNORE="*ytplay*:*instagram-cli*${HISTIGNORE:+:$HISTIGNORE}"

# ytplay: Search & Stream YouTube Audio with Foot Terminal Sixel Previews & FZF
ytplay() {
  local query="$*"
  [ -z "$query" ] && echo "Usage: ytplay <search term>" && return 1

  local thumb_dir="/tmp/ytplay_thumbs_$$"
  mkdir -p "$thumb_dir"
  trap 'rm -rf "$thumb_dir" ~/.cache/yt-dlp 2>/dev/null' RETURN

  echo "Searching YouTube for: $query..."
  local results
  results=$(yt-dlp --no-cache-dir "ytsearch20:$query" \
    --flat-playlist \
    --skip-download \
    --print "%(title)s___%(channel)s___%(duration_string)s___%(id)s" 2>/dev/null | \
    awk -F'___' '{printf "%-50s | %-20s | [%s]\t%s\n", $1, $2, $3, $4}')

  if [ -z "$results" ]; then
    echo "No results found for: $query"
    return 0
  fi

  # Loop to allow returning to search results after stopping playback
  while true; do
    local selected
    selected=$(printf "%s\n" "$results" | \
      fzf --delimiter="\t" --with-nth=1 \
          --header="Select track (Enter: Play | Esc: Exit):" \
          --preview="
            id={2}
            thumb='$thumb_dir'/\$id.jpg
            if [ ! -f \"\$thumb\" ]; then
              curl -s \"https://img.youtube.com/vi/\$id/mqdefault.jpg\" -o \"\$thumb\"
            fi
            chafa -f sixels -s \"\${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES}\" \"\$thumb\" 2>/dev/null || chafa -s \"\${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES}\" \"\$thumb\"
          " \
          --preview-window=right:50%
    )

    # Break out of loop if Esc or Ctrl+C was pressed in fzf
    [ -z "$selected" ] && break

    local id
    id=$(echo "$selected" | awk -F'\t' '{print $2}')

    if [ -n "$id" ]; then
      mpv --no-video \
          --player-operation-mode=cplayer \
          --force-window=no \
          --terminal=yes \
          --ytdl-format="bestaudio/best" \
          --ytdl-raw-options=no-cache-dir= \
          "https://youtu.be/$id"
      # When mpv exits, loop continues back to fzf search window automatically
    fi
  done
}

