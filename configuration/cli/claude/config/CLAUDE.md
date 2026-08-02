# Personal Claude Code instructions

## Spelling

Use American English spelling everywhere — prose, commit messages, code,
comments, docs, artifacts. Never British spelling: `color` not `colour`,
`behavior` not `behaviour`, `canceled` not `cancelled`, `center` not
`centre`, `-ize` not `-ise` (`organize`, `serialize`). The one exception
is matching an identifier or API that is already spelled the British way
in the code being touched.

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

- **React / React Native / Expo / TypeScript code:** invoke the
  `expo-conventions` skill. It carries the functional, immutable
  house style — function components only, `const`-only, no mutation,
  make-impossible-states-impossible types, and a strict no-comments
  rule — that governs all RN/Expo/React work.

- **Custom-config slash commands the user types literally
  (`/foo`):** if the skill is in the available-skills list, call it
  via the Skill tool. Don't guess slash-command names from memory.

## The tdd-loop trigger

- **When I say `tdd-loop <which tests>` — with or without a leading
  slash:** run the `tdd-loop` workflow
  (`/home/nick/.claude/workflows/tdd-loop.js`) via the Workflow tool,
  targeting the tests the phrase refers to. The bare phrase is a
  colloquial alias for the `/tdd-loop` slash command, and saying it is
  an explicit opt-in to that multi-agent run. Resolve the description
  ("the failing tests we just created", a path, a `path:line`, a list)
  to concrete targets from context — ask only if genuinely ambiguous —
  and pass `{ target, testCommand }` (detect the repo's test command).
  The loop freezes the failing tests as a group and drives each to green
  one at a time (runner → minimal implementer → minimality critic),
  ignoring collateral breakage until the group is green, then verifies
  the full suite.

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

Both files are symlinked from
`~/code/orchard/configuration/cli/claude/config/`, so edits land in the
dotfiles automatically — just remember to commit.

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

- **Open browser previews as a tab, never a new window.** When you
  build something for me to look at — a generated gallery, a
  comparison page, any local HTML — run `chromium <url>` with no
  flags. Never `chromium --new-window <url>`.

  Hyprland has a global `windowrule = match:class .*, workspace
  empty`, so every *new window* gets sent to the lowest-numbered
  empty workspace. A preview opened with `--new-window` doesn't just
  open a window, it teleports me off the desktop I was working on.
  Plain `chromium <url>` reuses the running instance and opens a tab
  in the last-focused window, launching Chromium if nothing is up.

## Common file locations

- **Screenshots**: `~/pictures/screenshots/` (lowercase
  `pictures`, not the default `Pictures`). When the user
  references "the screenshot," "the latest screenshot," or asks
  you to look at one without giving a path, look here and sort by
  mtime to find the relevant file. Read it with the `Read` tool
  directly.

## Verifying changes

When a project has a `checks.config.json` at its root, a change isn't
done until `checks` passes. Run it (a parallel lint / typecheck / test
runner) and get a clean pass before calling the change complete — don't
substitute ad-hoc lint/typecheck commands for it. On this machine
`checks` runs through mise's Bun, so invoke it as `mise exec -- checks`.

## Don't project state onto me

Don't frame anything around my assumed state — time of day, mental
state, mood, level of fatigue, how the situation supposedly feels.
Just the work. Includes, non-exhaustively:

- **Time of day**: "for tonight," "in the morning," "before bed,"
  "tomorrow we'll …" — I work at all hours.
- **Mental / physical state**: "while you recover," "once you're
  rested," "after a break," "you're frustrated so…"
- **Mood projection**: "I know this is rough," "this must be
  frustrating," "hang in there"
- **Time-boxed deferral**: "come back to this later," "save it for
  next time" — name the next step, don't time-box it.

The framing reads as stock LLM filler that papers over actual
problems with empathy theater. I've called this out repeatedly.

When wrapping a unit of work, name the unit of work itself ("for the
base system bringup," "as the next step," "for that pass"). When
something fails, name the failure and the fix. Don't comment on how
the situation feels. If I explicitly say I'm stopping, acknowledge
briefly and stop. Otherwise stay in the work.

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

The subject line has an audience: usually the product's user, not
its developer. The subject is the **outcome**, not the action that
produced it. A commit that caches a result so the library opens in
200ms instead of 4s reads "Open the library instantly" — that's
the outcome; "Cache the library response in ETS" describes what we
did to deliver it. Same change, two framings — pick the outcome.
Implementation details belong in the body. The subject line is
what gets scanned years later when the product is remembered only
vaguely; it should help you re-orient there.

When the outcome is hard to phrase succinctly, that's usually a
hint to dig harder for the real value, not to fall back on
describing the action. "Reduce setup time" beats "Remove manual
onboarding steps"; "Increase aviary's uptime" beats "Auto-login on
restarts." The body has all the room you need for what + how.

Exception: chore commits — dependency bumps, build fixes, internal
refactors where nothing observable changes for any user — can be
technical ("Upgrade React to 19", "Drop the unused fixtures
helper"). In XP / Pivotal Labs terms: stories get user-experience
subjects, chores can get technical ones.

If the product itself targets developers (a library, dotfiles, an
internal tool), the audience IS a developer — but that doesn't
make every commit a chore. The developer-as-user still has an
experience that changes; frame around that. Adding paragraphs to
a config doc that change how Claude phrases commit subjects reads
"Improve Claude's commit subject line wording", not "Add subject-
line audience paragraphs to CLAUDE.md."

Never reference ticket numbers in the subject. Years later "Fix
the import flow stalling when qBit gives up mid-grab" helps you
scan git log; "PRJ-1421" doesn't.

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

For handlers and callbacks, name by what they do, not what
triggered them. `<Movie onClick={playMovie} />` reads at the call
site: the prop says it's a click, the function says what happens
on click. `<Movie onClick={handleClick} />` is lazy — it just
re-names the trigger and forces the reader to open the function
body to find out what it actually does. Same for `onChange`,
`onSubmit`, `onLoad`, any callback prop. The trigger lives in the
prop name; the consequence lives in the function name.

Avoid `should` in names. The condition itself is almost always
the cleaner name — `if (isPowerOff) turnOn()` reads what to do
without needing a `shouldRestart` intermediate. In tests
especially: declarative, present tense. `it "turns on"`, not
`it "should turn on"` — the test is asserting the behavior, not
editorializing about it.

When one value genuinely carries two meanings in two contexts,
give it two names and assign one to the other:

```
const allFollowers = await fetchFollowers(account);
// ...later, the digest goes out to every follower
const digestRecipients = allFollowers;
sendDigest(digestRecipients);
```

The compiler optimizes the indirection away; the call site reads
with intent. Cheaper than a comment, harder to ignore. Same for
intermediate values in a pipeline — name each step for what it
represents at that point, not for what it came from.

Succinct and clear at the same time is a skill — keep reaching
for it. When you can't have both, pick clear. A function or
variable named with a whole sentence beats a short cryptic one;
`notifyHouseholdMembersOfRemovedShow` is fine if that's genuinely
what it does. If you find yourself reaching for sentence-names
often, that's usually a hint that something else wants to change
— the abstraction is wrong, the thing is doing too much. But
"should change" doesn't beat "is clear right now"; being clear
first is cheap.

**No magic numbers.** A bare numeric literal buried in an
expression is a name waiting to happen — `div(len * 3, 4)` is
opaque; `div(len * bytesPerBase64Group, charsPerBase64Group)`
reads. Lift ratios, unit conversions, thresholds, and
API-mandated sizes into named constants (or named intermediate
values) that say what the number *is*, and where the value
itself is non-obvious let the name carry the *why*:
`graphRequiredChunkMultipleBytes` for `320 * 1024`,
`largeAttachmentThresholdMegabytes` for `3`. This goes further
than it first looks: even the literals that feel purely
definitional carry context worth naming — a `0` is the *byte
offset* a stream starts at (`firstByteOffset = 0`), and the
`- 1` in `offset + length - 1` is what makes a byte range
*inclusive* (`lastByteOffset = offset + length - 1`). If a
number means something, name it. The test: could a reader tell
what the number means without going to hunt for it? Applies in
every language.

## Comments

Default to **no comments**. Names carry the meaning — a
well-named variable, function, or intermediate value says what a
comment would, and can't drift out of sync the way a comment
does. This holds in every language, not just TS/React (where
`expo-conventions` already enforces it): Python, Go, Ruby, shell,
config files, all of it.

The bar is high: write a comment only when the code does
something genuinely unconventional that names alone can't
explain — and even then, prefer a **link to a GitHub issue /
ticket** over prose. The comment's job is to point at the *why*
(the constraint, the upstream bug, the "yes this looks wrong,
here's why it isn't") that can't live in the code. If you're
explaining *what* the code does, delete the comment and fix the
name instead.

Config files count too. A `rule: 'off'` line doesn't need a
comment saying which rule it replaced or why some version
flipped a default — that's archaeology, not a non-obvious
decision. If the "why" genuinely matters, file an issue and
link it.

**Shell is the one place the exception is tempting** — bash is
genuinely hard to read. But the answer is the same: extract
well-named functions and variables so the top-line,
orchestrating section reads as plain English to someone who
doesn't know bash. A reader should understand what the script
*does* from its main body without decoding flags, `${x%/*}`
expansions, or `[[ … ]]` tests — because those live inside
named helpers. Names over comments, even here.

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
Code hook, a `configuration/cli/claude/` path — these name Claude as the
topic, not as a contributor, and are fine. The line: never say
Claude *did* the work; naming Claude as the thing worked *on* is OK.

## Reproducibility prompts

- **Right after the user installs a Claude Code plugin** (`/plugin
  install <name>@<marketplace>`): remind them that for fresh installs
  to auto-pick-it-up, two things have to be true:
    1. The marketplace must be in
       `configuration/cli/claude/install.sh`'s `MARKETPLACES`
       array. If it's a new marketplace they haven't used before,
       offer to add it.
    2. The `enabledPlugins` entry in `~/.claude/settings.json`
       (symlinked from the dotfiles) must be committed. Suggest
       running `git -C ~/code/orchard status configuration/cli/claude/`
       and committing the change.
