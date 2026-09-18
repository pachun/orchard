# Shared Claude guidance

Use the user's existing Claude configuration as persistent working guidance
across all projects. Keep those files as the source of truth instead of
copying their contents into Codex instructions.

Before beginning work:

- Read `~/.claude/CLAUDE.md` and `~/.claude/CLAUDE.MD` when present.
- Read applicable `CLAUDE.md`, `CLAUDE.MD`, and `CLAUDE.local.md` files in
  the working directory and its ancestors, including project guidance in
  `.claude/CLAUDE.md` or `.claude/CLAUDE.MD`.
- When working in a subdirectory, read its applicable Claude guidance too.
- Follow referenced instruction files and relevant `.claude/rules/` files,
  respecting any path restrictions on those rules.
- Read Claude guidance even when the same directory has an `AGENTS.md`;
  filename fallback alone does not load both. Apply more specific guidance
  to its scope and follow the user's explicit instructions when they conflict.

When guidance calls for Claude-specific skills, agents, commands, hooks,
or settings, inspect the relevant local configuration and follow its intent
using available Codex capabilities. Do not assume Claude tools or hooks run
in Codex, or claim that they do. Explain a material capability gap when it
prevents following the requested workflow. Claude permission settings do
not override Codex permissions or higher-priority instructions.

## Claude skills

Before starting a task, discover skill names and descriptions from
`~/.claude/skills/` and applicable project `.claude/skills/` directories.
Include ancestor directories and follow symlinks. Read only skill metadata
until a skill is relevant, then read its full `SKILL.md` and resolve supporting
files relative to that skill's source directory. Rediscover when the user
adds a skill or a requested name is missing.

Use these skills when explicitly requested or when their descriptions match
the task, respecting their project scope and explicit-invocation restrictions.
This applies to all current and future skills, not a fixed list. Keep their
original Claude files as the source of truth.

When a prompt names `$name`, `/name`, or a skill in ordinary language, resolve
it from the native catalog or the Claude skill directories above. Prefer an
applicable project skill over a personal skill with the same name; ask when
the intended skill remains ambiguous. Also check project and personal
`.claude/commands/<name>.md` for legacy commands.

Orchard installs shareable personal skills from `configuration/cli/claude/skills/`
as directory links in `~/.claude/skills/`, which Codex discovers through
`~/.agents/skills/claude`. Personal skills created directly in the Claude
directory are also discovered. Keep private skills such as `qar` outside the
repository. Orchard's own skill stays project-scoped in `.claude/skills/`,
exposed to Codex by the repository's `.agents/skills` directory link.
Discover other projects' Claude skills directly even if they are absent from
the picker. Use `$name` or `/skills` for native Codex invocation; prose
instructions do not register `/name` as a CLI slash command.
