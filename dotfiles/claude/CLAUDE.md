# Personal Claude Code instructions

## When to reach for specific tools

- **Claude Code features, plugins, configuration, MCP servers, hooks,
  settings, slash commands, IDE integrations, keybindings:** invoke
  the `claude-code-guide` agent. Do not guess from training-data
  knowledge — Claude Code evolves and that knowledge gets stale.

- **Frontend / CSS / visual design / layout / icon alignment / any
  task where aesthetics matter:** invoke the
  `frontend-design:frontend-design` skill before iterating from
  instinct. The skill carries design-thinking discipline that prevents
  the "throw fixes at the wall" failure mode.

- **Anthropic API / Claude SDK code (anthropic, @anthropic-ai/sdk):**
  invoke the `claude-api` skill. Make sure prompt caching is wired in
  for any new Claude API integration.

- **Custom-config slash commands the user types literally
  (`/foo`):** if the skill is in the available-skills list, call it
  via the Skill tool. Don't guess slash-command names from memory.

## Self-tightening permissions

After the user manually grants permission for a Bash command, ask
yourself: should this have auto-approved? It auto-approves when EITHER:

- The command's full pattern is in `~/.claude/settings.json`'s
  `permissions.allow` (e.g. `Bash(systemctl is-active *)`), OR
- Every segment of the pipeline/sequence is read-only AND every
  command's first word is in the ALLOWLIST set inside
  `~/.claude/hooks/auto-allow-read-pipelines.py`

If the command was clearly read-only (no writes, no network, no state
changes), figure out why it didn't auto-approve and propose the fix:

- Pure new command not in the hook's ALLOWLIST → add it to the
  ALLOWLIST set
- Specific patterned command we'd want pre-approved (e.g.
  `git stash list`, `pacman -Q *`) → append to `permissions.allow`
  in `~/.claude/settings.json`
- Unusual shell construct the hook doesn't recognize (subshell,
  command-substitution, etc.) → leave it; expanding the hook here
  risks letting through write operations

Both files are symlinked from `~/code/orchard/dotfiles/claude/`, so
edits land in the dotfiles automatically — just remember to commit.

## Workflow preferences

- **Use files, not copy-paste, for both input and output of
  terminal commands.** Copy-paste is friction in either direction —
  same friction-class as screenshots for visual-only stuff.
    - **Output direction**: when you need me to run a command you
      can't run via tools (sudo with prompt, interactive
      bluetoothctl/gcloud sessions, anything askpass), have me
      redirect output to a `/tmp/<descriptive>.log` file with `tee`
      or `>`. Then `Read` the file yourself.
    - **Input direction**: when handing me a multi-line script,
      heredoc, or anything more than a one-line command, write it
      to `/tmp/<descriptive>.sh`, `chmod +x` it, and tell me to run
      that path. Don't paste a multi-line block expecting me to
      copy it.
    - Keep paste-back only for genuinely-tiny output (one short
      line that's faster to read than to fopen).

## Reproducibility prompts

- **Right after the user installs a Claude Code plugin** (`/plugin
  install <name>@<marketplace>`): remind them that for fresh installs
  to auto-pick-it-up, two things have to be true:
    1. The marketplace must be in
       `setup/install/configure-claude-plugins.sh`'s `MARKETPLACES`
       dict. If it's a new marketplace they haven't used before,
       offer to add it.
    2. The `enabledPlugins` entry in `~/.claude/settings.json`
       (symlinked from the dotfiles) must be committed. Suggest
       running `git -C ~/code/orchard status dotfiles/claude/` and
       committing the change.
