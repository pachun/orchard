# Aliases that require a graphical session or desktop-only tools.
alias nord_connect="nordvpn connect --group Dedicated_IP"
alias nord_disconnect="nordvpn disconnect"
alias battery="cat /sys/class/power_supply/macsmc-battery/capacity"

# Open the current repo's GitHub/GitLab page in the default browser.
function gh {
  remote_url=$(git remote get-url origin 2>/dev/null)

  if [[ -z "$remote_url" ]]; then
    echo "No remote URL found." >&2
    return 1
  fi

  remote_url=${remote_url%.git}

  if [[ "$remote_url" =~ "github.com" ]]; then
    xdg-open "${remote_url/git@github.com:/https://github.com/}"
  elif [[ "$remote_url" =~ "gitlab.com" ]]; then
    xdg-open "${remote_url/git@gitlab.com:/https://gitlab.com/}"
  else
    echo "Unknown remote host: $remote_url" >&2
    return 1
  fi
}
