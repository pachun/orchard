# Codex

`install.sh` installs Codex and runs `setup.sh`. Orchard's `./configure`
includes this feature on new machines. To reapply configuration when Codex
is already installed, run `bash configuration/cli/codex/setup.sh`.

The setup preserves machine-specific `~/.codex/config.toml` settings while
applying the model, reasoning effort, tooltip preference, and Claude
instruction filename fallbacks. Existing fallback filenames are retained.
`config/AGENTS.md` is linked into `~/.codex/AGENTS.md` using Orchard's usual
link helper, which backs up any existing regular file.

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
