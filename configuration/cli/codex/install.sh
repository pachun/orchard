#!/usr/bin/env bash
# Codex, OpenAI's terminal coding agent, set up to run GPT-6 Astra on the
# ChatGPT Pro plan. Arch packages it in extra, so it rides system-update like
# everything else; the config links in with the model and reasoning effort
# already chosen, so `codex` opens on Astra without a /model step.
#
# Signing in is the one manual step, once per machine: `codex login` opens
# the browser for the ChatGPT sign-in and keeps the result under ~/.codex.
# `codex login status` says whether that's been done. The ai-usage panel
# reads that same login for the bar's usage numbers.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm openai-codex

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.codex"
