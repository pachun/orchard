function use_custom_prompt {
  # defined in your iterm colors profile (the ansi colors)
  COLOR_BLACK=0
  COLOR_RED=1
  COLOR_GREEN=2
  COLOR_YELLOW=3
  COLOR_BLUE=4
  COLOR_MAGENTA=5
  COLOR_CYAN=6
  COLOR_WHITE=7

  COLOR_BRIGHT_BLACK=8
  COLOR_BRIGHT_RED=9
  COLOR_BRIGHT_GREEN=10
  COLOR_BRIGHT_YELLOW=11
  COLOR_BRIGHT_BLUE=12
  COLOR_BRIGHT_MAGENTA=13
  COLOR_BRIGHT_CYAN=14
  COLOR_BRIGHT_WHITE=15

  # Set prompt components
  # %1~ shows the current directory's last segment, with $HOME rendered
  # as ~ — so there's always something on the prompt line, never a
  # naked cursor without context.
  function directory {
    echo "%F{$COLOR_BRIGHT_WHITE}%1~%f"
  }

  # The cursor itself is the mode indicator — see set_cursor_color_for_mode
  # below. No prompt glyph, no symbol; just the cursor's color carries
  # the signal. Insert = bright (ready to type), command = dim grey.
  CURSOR_INSERT_COLOR='#c6d0f5'
  CURSOR_COMMAND_COLOR='#737994'
  function set_cursor_color_for_mode {
    if [[ $KEYMAP == vicmd ]]; then
      printf '\e]12;%s\e\\' "$CURSOR_COMMAND_COLOR"
    else
      printf '\e]12;%s\e\\' "$CURSOR_INSERT_COLOR"
    fi
  }

  # When SSH'd into a remote machine, prepend the short hostname in
  # bright yellow so it's obvious which box this prompt belongs to.
  # Empty string in local sessions — the prompt stays minimal at home.
  function ssh_prefix {
    if [[ -n "$SSH_CONNECTION" ]]; then
      echo "%F{$COLOR_BRIGHT_YELLOW}%m%f "
    fi
  }

  function status_colored_git_branch {
    if $(git rev-parse --is-inside-work-tree > /dev/null 2>&1); then
      # Handle repos with no commits yet
      if ! git rev-parse HEAD > /dev/null 2>&1; then
        echo "%F{$COLOR_BRIGHT_CYAN}(no commits)%f"
        return
      fi
      git_branch=$(git rev-parse --abbrev-ref HEAD)
      git_status=$(git status)
      if [[ -n "$(echo $git_status | grep 'Changes not staged')" ]]; then
        echo "%F{$COLOR_BRIGHT_MAGENTA}$git_branch%f"
      elif [[ -n "$(echo $git_status | grep 'rebasing')" ]]; then
        echo "%F{$COLOR_BRIGHT_MAGENTA}(rebase in progress)%f"
      elif [[ -n "$(echo $git_status | grep 'Changes to be committed')" ]]; then
        echo "%F{$COLOR_BRIGHT_YELLOW}$git_branch%f"
      elif [[ -n "$(echo $git_status | grep 'Untracked files')" ]]; then
        echo "%F{$COLOR_BRIGHT_CYAN}$git_branch%f"
      else
        echo "%F{$COLOR_GREEN}$git_branch%f"
      fi
    fi
  }

  function allow_prompt_string_interpolation {
    setopt promptsubst
  }

  function keep_vim_mode_current {
    function zle-line-init zle-keymap-select {
      VIMODE=$KEYMAP
      set_cursor_color_for_mode
      zle reset-prompt
    }

    zle -N zle-line-init
    zle -N zle-keymap-select
  }

  # Reset cursor color to whatever ghostty's default is when the shell
  # exits — otherwise OSC 12 colors stick around in the terminal session
  # for any subsequent program (vim, etc.).
  function reset_cursor_color_on_exit {
    trap 'printf "\e]112\e\\"' EXIT
  }

  # Apply the settings
  allow_prompt_string_interpolation
  keep_vim_mode_current
  reset_cursor_color_on_exit

  # Combine the prompt components — no trailing glyph; the cursor
  # following the trailing space IS the mode indicator.
  # Conditional spacing: include a leading space only if directory is
  # non-empty (i.e., not in $HOME). Same trick for the trailing space
  # after git branch — only included when git branch is non-empty.
  PROMPT='$(ssh_prefix)${$(directory):+$(directory) }$(status_colored_git_branch)${$(status_colored_git_branch):+ }'
}

use_custom_prompt
