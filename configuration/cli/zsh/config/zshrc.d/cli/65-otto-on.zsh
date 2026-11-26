_otto_on() {
  if (( CURRENT == 2 )); then
    _hosts
  elif (( CURRENT == 3 )); then
    compadd -- ${(f)"$(otto-on $words[2] --names 2>/dev/null)"}
  fi
}
compdef _otto_on otto-on
