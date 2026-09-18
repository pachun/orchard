#!/usr/bin/env bash
# Codex, OpenAI's terminal coding agent, set up to run GPT-6 Astra on the
# ChatGPT Pro plan. Arch packages it in extra, so it rides system-update like
# everything else, and `codex` opens on Astra without a /model step.
#
# ~/.codex/config.toml is Codex's own file, not a link into this repo: Codex
# writes per-machine state into it as you work (which projects you've trusted,
# which model notices you've seen), so linking it would dirty the repo on
# every session. Instead our choices are patched in — the model and effort at
# top level, and no startup tips under [tui] — and everything else is left as
# Codex keeps it, so configure re-asserts them on every run.
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
TOP_LEVEL = None
chosen = [
    (TOP_LEVEL, "model", '"gpt-6-astra"'),
    (TOP_LEVEL, "model_reasoning_effort", '"high"'),
    ("tui", "show_tooltips", "false"),
]


def table_named_by(line):
    stripped = line.strip()
    if stripped.startswith("[[") or not (stripped.startswith("[") and stripped.endswith("]")):
        return None
    return stripped[1:-1].strip()


def split_into_tables(lines):
    tables = [(TOP_LEVEL, [])]
    for line in lines:
        name = table_named_by(line)
        if name is not None or line.strip().startswith("[["):
            tables.append((name if name is not None else line.strip(), [line]))
        else:
            tables[-1][1].append(line)
    return tables


def with_key_set(body, key, value):
    assignment = f"{key} = {value}"
    is_this_key = re.compile(rf"^\s*{re.escape(key)}\s*=").match
    if any(is_this_key(line) for line in body):
        return [assignment if is_this_key(line) else line for line in body]
    return body + [assignment]


tables = split_into_tables(config.read_text().splitlines())
for table, key, value in chosen:
    if not any(name == table for name, _ in tables):
        tables.append((table, [f"[{table}]"]))
    tables = [(name, with_key_set(body, key, value) if name == table else body) for name, body in tables]

blocks = ["\n".join(line for line in body).strip("\n") for _, body in tables]
wanted = "\n\n".join(block for block in blocks if block) + "\n"
if config.read_text() != wanted:
    config.write_text(wanted)
PY
}

sudo pacman -S --needed --noconfirm openai-codex

open_on_astra_by_default
