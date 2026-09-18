#!/usr/bin/env bash
# Codex, OpenAI's terminal coding agent, set up to run GPT-6 Astra on the
# ChatGPT Pro plan. Arch packages it in extra, so it rides system-update like
# everything else, and `codex` opens on Astra without a /model step.
#
# ~/.codex/config.toml is Codex's own file, not a link into this repo: Codex
# writes per-machine state into it as you work (which projects you've trusted,
# which model notices you've seen), so linking it would dirty the repo on
# every session. Instead our choices are patched in — the model and effort at
# top level, Claude instruction filenames, working permissions across ~/code,
# automatic approval review, and no startup tips under [tui].
# Shared guidance links back to this feature. Whole-directory skill links
# keep Claude as the source of truth, including skills added after setup.
#
# Signing in is the one manual step, once per machine: `codex login` opens
# the browser for the ChatGPT sign-in and keeps the result under ~/.codex.
# `codex login status` says whether that's been done. The ai-usage panel
# reads that same login for the bar's usage numbers.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm openai-codex

bash "$HERE/setup.sh"
