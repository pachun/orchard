#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORCHARD="$(cd "$HERE/../../.." && pwd)"
TOOLS="${TOOLS:-$ORCHARD/tools}"
CODEX_SETUP_HOME="${1:-$HOME}"

apply_codex_defaults() {
  local config="$CODEX_SETUP_HOME/.codex/config.toml"
  mkdir -p "$CODEX_SETUP_HOME/.codex"
  [ -f "$config" ] || : > "$config"
  python3 - "$config" <<'PY'
import json
import re
import sys
import tomllib
from pathlib import Path

config = Path(sys.argv[1])
existing = tomllib.loads(config.read_text())
fallback_names = list(dict.fromkeys([
    *existing.get("project_doc_fallback_filenames", []),
    "CLAUDE.md",
    "CLAUDE.MD",
]))
TOP_LEVEL = None
chosen = [
    (TOP_LEVEL, "project_doc_fallback_filenames", json.dumps(fallback_names)),
    (TOP_LEVEL, "model", '"gpt-6-astra"'),
    (TOP_LEVEL, "model_reasoning_effort", '"high"'),
    ("tui", "show_tooltips", "false"),
    ("tui", "vim_mode_default", "true"),
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
    for start, line in enumerate(body):
        if not is_this_key(line):
            continue
        end = start + 1
        while True:
            try:
                tomllib.loads("\n".join(body[start:end]))
                return body[:start] + [assignment] + body[end:]
            except tomllib.TOMLDecodeError:
                if end == len(body):
                    raise
                end += 1
    return body + [assignment]


tables = split_into_tables(config.read_text().splitlines())
for table, key, value in chosen:
    if not any(name == table for name, _ in tables):
        tables.append((table, [f"[{table}]"]))
    tables = [(name, with_key_set(body, key, value) if name == table else body) for name, body in tables]

blocks = ["\n".join(line for line in body).strip("\n") for _, body in tables]
wanted = "\n\n".join(block for block in blocks if block) + "\n"
tomllib.loads(wanted)
if config.read_text() != wanted:
    config.write_text(wanted)
PY
}

share_skill_directory() {
  local source="$1"
  local destination="$2"
  if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source" ]; then
    return
  fi
  if [ -e "$destination" ] || [ -L "$destination" ]; then
    printf 'Cannot share skills: %s already exists and points elsewhere.\n' "$destination" >&2
    return 1
  fi
  ln -s "$source" "$destination"
}

retire_skill_link() {
  local destination="$1"
  local source="$2"
  if [ -L "$destination" ] && [ "$(realpath -m "$destination")" = "$(realpath -m "$source")" ]; then
    unlink "$destination"
  fi
}

bash "$HERE/../claude/setup-skills.sh" "$CODEX_SETUP_HOME"
mkdir -p "$CODEX_SETUP_HOME/.claude/skills" "$CODEX_SETUP_HOME/.agents/skills"
share_skill_directory "$CODEX_SETUP_HOME/.claude/skills" "$CODEX_SETUP_HOME/.agents/skills/claude"
retire_skill_link "$CODEX_SETUP_HOME/.agents/skills/claude-managed" "$HERE/../claude/config/skills"
retire_skill_link "$CODEX_SETUP_HOME/.agents/skills/orchard" "$ORCHARD/.claude/skills"
apply_codex_defaults
bash "$TOOLS/link.sh" "$HERE/config" "$CODEX_SETUP_HOME/.codex"
