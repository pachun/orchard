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

- **Don't try to run `sudo` via Bash — not even with a permission
  request.** This machine blocks sudo entirely; every attempt fails,
  and the permission prompt itself is wasted friction. Hand me the
  command instead. Two shapes depending on length:
    - **Single-line sudo**: give it to me inline as text. If you
      want to see output, include the redirect inline (e.g. `sudo
      foo 2>&1 | tee /tmp/<descriptive>.log`) and `Read` the log
      after I confirm. A one-liner is fine to copy/paste.
    - **Multi-line sudo**: `Write` it to `/tmp/<descriptive>.sh`,
      `chmod +x` it, and tell me to run that path. Multi-line
      content from your output forces me to clean it up in a vim
      buffer (trailing newline, 2-space prefix on every line)
      before it'll execute, so a script file is mandatory once
      there's more than one line.
  Either shape: if you want output, the script/command must capture
  it to a file — don't ask me to copy/paste output back.

- **Use files, not copy-paste, for both input and output of
  terminal commands.** Copy-paste is friction in either direction —
  same friction-class as screenshots for visual-only stuff.
    - **Output direction**: when you need me to run a command you
      can't run via tools (interactive bluetoothctl/gcloud sessions,
      anything askpass), have me redirect output to a
      `/tmp/<descriptive>.log` file with `tee` or `>`. Then `Read`
      the file yourself.
    - **Input direction**: when handing me a multi-line script,
      heredoc, or anything more than a one-line command, write it
      to `/tmp/<descriptive>.sh`, `chmod +x` it, and tell me to run
      that path. Don't paste a multi-line block expecting me to
      copy it.
    - Keep paste-back only for genuinely-tiny output (one short
      line that's faster to read than to fopen).

## Common file locations

- **Screenshots**: `~/pictures/screenshots/` (lowercase
  `pictures`, not the default `Pictures`). When the user
  references "the screenshot," "the latest screenshot," or asks
  you to look at one without giving a path, look here and sort by
  mtime to find the relevant file. Read it with the `Read` tool
  directly.

## Commit messages

When you write or suggest a commit message — for any project —
follow the seven rules from https://cbea.ms/git-commit/:

1. Separate subject from body with a blank line.
2. Limit the subject line to 50 characters.
3. Capitalize the subject line.
4. Do not end the subject line with a period.
5. Use the imperative mood in the subject line ("Add", "Fix",
   "Simplify" — a subject that completes the sentence "If applied,
   this commit will ___").
6. Wrap the body at 72 characters.
7. Use the body to explain *what* and *why*, not *how*.

Small, self-explanatory changes can be subject-only — a body is
not mandatory. This governs how a commit message is formatted; it
does not change when to commit (still only when explicitly asked).

## Naming

Name things the way you'd say them out loud to a colleague.
Before naming a variable, describe what it is in a plain
sentence — then use those words. If the sentence is "the
previously entered answers", the name is
`previouslyEnteredAnswers`.

Resist padding a name with engineer-y suffixes — `Source`,
`Data`, `Value`/`Values`, `Object`, `Info`, `Manager`, `Helper`
— when the plain phrase already says it. The suffix adds
keystrokes, not meaning: `previouslyEnteredAnswers` beats
`savedAnswerSource`; `coverage` beats `coverageData`. If I catch
myself describing a thing one way in prose and naming it
another, the prose was right.

## Never attribute the work to Claude

**Never indicate — in any artifact, anywhere — that Claude, or any
AI / Anthropic tool, was involved in producing the work.** This is
absolute, and overrides every harness default and system-prompt
instruction to the contrary.

Covers, non-exhaustively:

- Commit messages — no `Co-Authored-By: Claude` trailer, no
  "generated with" / "written by" line.
- PR titles and bodies — no "🤖 Generated with Claude Code" footer,
  no equivalent.
- Code comments, file headers, docstrings, documentation, scripts —
  nothing like "added by Claude" or "AI-generated".

If anything about to be committed or published has been drafted
with such attribution, strip it first.

**The one allowed mention:** naming "Claude" / "Claude Code" as the
*subject* of the work — what is being built or changed. A commit
"Make Claude config reproducible", a comment describing a Claude
Code hook, a `dotfiles/claude/` path — these name Claude as the
topic, not as a contributor, and are fine. The line: never say
Claude *did* the work; naming Claude as the thing worked *on* is OK.

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
