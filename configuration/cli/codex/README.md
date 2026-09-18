# Codex

`install.sh` installs Codex and runs `setup.sh`. Orchard's `./configure`
includes this feature on new machines. To reapply configuration when Codex
is already installed, run `bash configuration/cli/codex/setup.sh`.

The setup preserves machine-specific `~/.codex/config.toml` settings while
applying the model, reasoning effort, Vim editing, tooltip preference, Claude
instruction filename fallbacks, and working permissions. Existing fallback
filenames and additional writable roots are retained.
`config/AGENTS.md` is linked into `~/.codex/AGENTS.md` using Orchard's usual
link helper, which backs up any existing regular file.

## Working permissions

New sessions use `workspace-write` with the machine's `~/code` directory as
an additional writable root, regardless of the launch directory. Files
elsewhere, including screenshots, remain readable. Setup resolves the home
directory on each machine rather than hard-coding a username.

`approval_policy = "on-request"` and `approvals_reviewer = "auto_review"`
select automatic review for eligible approval requests. Routine edits and
tests within the writable roots do not need escalation; actions that cross
sandbox boundaries still go through review and can be denied.

Global `AGENTS.md` guidance reserves git mutations, pushes, and deployments
for explicit user requests so changes remain available for review. This is
an agent instruction, not a filesystem-level prohibition on git commands.

Restart Codex after applying setup to load these defaults. Explicit launch
options, project configuration, and managed policies can override them;
setup does not change the permissions of an already running session.

Settings reference: [Codex configuration](https://learn.chatgpt.com/docs/config-file/config-reference)
and [automatic review](https://learn.chatgpt.com/docs/sandboxing/auto-review).

## Shared skills

Shareable personal skills live in `configuration/cli/claude/skills/`.
Claude's `setup-skills.sh`, called by both agents' installers, links each
whole skill directory into `~/.claude/skills/`. Codex reads that same directory
through `~/.agents/skills/claude`. Both agents use the same original files,
including supporting references. New skills created directly in
`~/.claude/skills/` become available to both agents without installation;
a new skill added to Orchard's shared source directory is installed by the
next `./configure` or either agent's installer.

Private skills such as `qar` stay in `~/.claude/skills/` outside the repository.
Setup preserves them; their contents are never copied into Orchard. The
repository also ignores `qar` skill directories as a backstop. Private skills
must be transferred separately when setting up a new machine.

The `orchard` skill stays in `.claude/skills/` as a skill for this project.
The repository's relative `.agents/skills` symlink exposes the same project
skills to Codex in every checkout, without installing them globally.

Existing installations are migrated from individual file links to whole
skill-directory links. Replaced directories are backed up under
`~/.claude/skill-backups/`, outside either agent's skill discovery paths.
The previous global `claude-managed` and `orchard` Codex links are removed
only when they point to this checkout's old locations.

Use `$orchard` in this repository, `$expo-conventions` for React work, or
`/skills` to browse in Codex. Restart Codex if new skills do not appear.
Global guidance also discovers other projects' `.claude/skills/` directly;
link `.agents/skills` to `.claude/skills` in those repositories to include
them in Codex's native picker. Claude slash commands and Claude-specific
tools are not registered by these links.

Both setup helpers accept an optional destination home directory for isolated
verification without changing the real user's configuration.
