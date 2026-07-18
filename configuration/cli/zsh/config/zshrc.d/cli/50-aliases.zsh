alias e=exit
alias c=clear
alias vim=nvim
alias x=gitspine
alias p='git push origin $(git rev-parse --abbrev-ref HEAD)'
alias gs="git status"
alias gl="git log"
alias gco="git checkout"
alias gri="git rebase -i"
alias gm="git merge"
alias wip="git add .; git commit -am 'wip' --no-verify"
alias lanip="ip addr | grep 'inet ' | grep -v '127.0.0.1' | awk '{print \$2}' | cut -d/ -f1"
alias tls="tmux ls"
alias open="xdg-open"

function keep {
  if [[ -z "$1" ]]; then
    echo "Usage: keep <branch-name>"
    echo "Deletes all branches except the specified branch"
    return 1
  fi
  git branch | grep -vE "^\*? ?$1$" | xargs git branch -D
}

function trn {
  if [[ -z "$1" ]]; then
    echo "Usage: trn NEW_SESSION_NAME"
    return 1
  fi

  if [[ -z "$TMUX" ]]; then
    echo "Not in a tmux session!"
    return 1
  fi

  local current_session
  current_session=$(tmux display-message -p "#S")

  tmux rename-session -t "$current_session" "$1"
  echo "Renamed session '$current_session' → '$1'"
}

function t {
  if [[ -z "$1" ]]; then
    echo "Usage: t SESSION_NAME"
    echo "  If the session name exists, you'll attach (or switch, if already in tmux)"
    echo "  If the session name does not exist, you'll create a new named session"
    echo "  (You can list the current sessions with: \`tls\`)"
    return 1
  fi

  # Inside tmux already: use switch-client so we don't try to nest a
  # second tmux instance inside the current pane. Also garbage-collect
  # the session we're leaving if every pane in it is just an idle
  # shell prompt — keeps stray auto-numbered sessions from piling up
  # when you `t somewhere-else` out of a fresh ghostty.
  if [[ -n "$TMUX" ]]; then
    local current_session
    current_session=$(tmux display-message -p "#S")

    if [[ "$current_session" == "$1" ]]; then
      return 0
    fi

    # Count panes whose foreground command is something other than a
    # plain shell. If 0, the session has nothing running and is safe
    # to kill after we switch out of it.
    local non_idle_count
    non_idle_count=$(tmux list-panes -s -t "$current_session" \
      -F "#{pane_current_command}" 2>/dev/null \
      | grep -vxE "zsh|bash|sh|fish|dash" | wc -l)

    if ! tmux has-session -t "$1" 2>/dev/null; then
      tmux new-session -d -s "$1"
    fi
    tmux switch-client -t "$1"

    if [[ "$non_idle_count" == "0" ]]; then
      tmux kill-session -t "$current_session"
    fi
  else
    if tmux has-session -t "$1" 2>/dev/null; then
      tmux attach-session -t "$1"
    else
      tmux new-session -s "$1"
    fi
  fi
}
