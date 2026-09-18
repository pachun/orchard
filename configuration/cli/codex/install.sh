#!/usr/bin/env bash
# Codex, OpenAI's terminal coding agent, set up to run GPT-6 Astra on the
# ChatGPT Pro plan. Arch packages it in extra, so it rides system-update like
# everything else, and `codex` opens on Astra without a /model step.
#
# ~/.codex/config.toml is Codex's own file, not a link into this repo: Codex
# writes per-machine state into it as you work (which projects you've trusted,
# which model notices you've seen), so linking it would dirty the repo on
# every session. Instead the model choice is patched in — the two top-level
# keys below are set to these values and everything else is left as Codex
# keeps it — so configure re-asserts the choice on every run.
#
# Signing in is the one manual step, once per machine: `codex login` opens
# the browser for the ChatGPT sign-in and keeps the result under ~/.codex.
# `codex login status` says whether that's been done. The ai-usage panel
# reads that same login for the bar's usage numbers.
# Idempotent.
set -euo pipefail

open_on_astra_by_default() {
  local config="$HOME/.codex/config.toml"
  mkdir -p "$HOME/.codex"
  [ -f "$config" ] || : > "$config"
  python3 - "$config" <<'PY'
import re
import sys
from pathlib import Path

config = Path(sys.argv[1])
chosen = {"model": '"gpt-6-astra"', "model_reasoning_effort": '"high"'}

lines = config.read_text().splitlines()
first_table = next((i for i, line in enumerate(lines) if line.lstrip().startswith("[")), len(lines))
top_level, tables = lines[:first_table], lines[first_table:]

for key, value in chosen.items():
    assignment = f"{key} = {value}"
    is_this_key = re.compile(rf"^\s*{key}\s*=").match
    if any(is_this_key(line) for line in top_level):
        top_level = [assignment if is_this_key(line) else line for line in top_level]
    else:
        top_level.append(assignment)

if tables and top_level and top_level[-1].strip():
    top_level.append("")
wanted = "\n".join(top_level + tables) + "\n"
if config.read_text() != wanted:
    config.write_text(wanted)
PY
}

sudo pacman -S --needed --noconfirm openai-codex

open_on_astra_by_default
