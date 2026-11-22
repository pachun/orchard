# New Expo project setup

Use this workflow before creating any new Expo application. Finish the
foundation before product features. "Bare" means Expo's minimal
`blank-typescript` template, not an ejected app or generated native
directories. Do not add routing, screens, a server, or other product
architecture merely because they may be needed later.

## Choose supported tooling each time

Check the current official Expo docs and the exact stable SDK being
created. Resolve compatible versions with Expo's installer; do not
copy Emma's dependency versions or assume `latest` tags align.

- [Scaffolding](https://docs.expo.dev/more/create-expo/)
- [Bun](https://docs.expo.dev/guides/using-bun/)
- [TypeScript](https://docs.expo.dev/guides/typescript/)
- [ESLint and Prettier](https://docs.expo.dev/guides/using-eslint/)
- [Testing](https://docs.expo.dev/develop/unit-testing/)
- [Expo Doctor](https://docs.expo.dev/develop/tools/#expo-doctor)
- [Update setup](https://docs.expo.dev/eas-update/getting-started/)
- [Update runtime compatibility](https://docs.expo.dev/eas-update/runtime-versions/)
- [Update download and application](https://docs.expo.dev/eas-update/download-updates/)

Prefer Expo's explicit current recommendation if it favors a package
manager. Otherwise use Bun, Nick's preference among supported options.
Examples using npm are not by themselves a recommendation against Bun.
Keep one lockfile and record the package-manager version. Install the
Node version required by the selected Expo tools even when using Bun.

As verified on 2026-11-22, Expo documents Bun support, ESLint with
`eslint-config-expo`, Prettier, and Jest with `jest-expo` and React Native
Testing Library. Bun as package manager does not mean `bun test` replaces
Jest: use the package script that runs Jest with its supported runtime.
Recheck these choices when executing this workflow. Do not switch to
Biome, Oxlint, Oxfmt, or another stack solely for speed. If Expo changes
its recommendation, evaluate the supported option against the house
conventions; confirm material style departures with Nick.

## Commit and validation contract

Nick requests the local repository initialization, staging, and ordered
setup commits below whenever creating a new Expo app. That standing
instruction is limited to the new project's setup; it does not authorize
committing unrelated work, rewriting history, pushing, publishing an
update, submitting a build, or deploying. A session's explicit instruction
not to commit takes precedence. Do not ask again for already-authorized
local setup commits.

Before **every** commit, run every applicable check available at that
stage and require a clean pass. Before the aggregate runner exists,
run the individual commands directly. From the first scaffold onward,
include TypeScript, Expo dependency compatibility (`expo install --check`),
and Expo Doctor, plus any checks supplied by the template. Add lint,
format, and tests as soon as those tools are configured. An unavailable
network-dependent Doctor check is not a passing check; report the
blocker and leave the commit pending. Never bypass hooks or weaken a
check to finish a commit. Review the diff and stage only the intended
step. Any subsequent edit requires rerunning affected checks and the
full pre-commit gate before committing.

Commit messages follow the personal CLAUDE.md guidelines: imperative,
capitalized subject at most 50 characters, no period; optional body
separated by a blank line and wrapped at 72 columns. Setup chores may
have technical subjects. The final OTA commit describes the user-visible
outcome. No tool attribution trailers or generated-by footers.

## Ordered commits

### 1. Minimal TypeScript Expo scaffold

Resolve and record the generator package's exact version before running
it. Prefer an invocation pinned to that version with `blank-typescript`.
Record the literal successful command, including flags and relevant
environment assignments, its working directory, the resolved template
version and SDK, and the package-manager version.

Prevent the generator from making an unchecked initial commit. The
current create-expo implementation skips git setup inside an existing
repository: initialize the empty target repository before scaffolding
into it, after verifying the selected CLI accepts an otherwise empty
directory containing `.git`. Recheck this behavior for the selected
generator version. Do not let an automatic commit slip through and
then amend it; the checks must precede the first commit.

Validate and commit the minimal generated app and lockfile immediately,
before house-style edits, test infrastructure, or OTA code. Only fix
actual scaffold compatibility failures needed to pass its baseline
checks; describe any such fix in the body.

The first commit body **must** include the exact successful CLI command
and the generator's package name and resolved version, even if the
command used `@latest`. Also include the working directory, template/SDK,
and package-manager version. Preserve the exact command's tokens and
quoting; do not invent a prettier reconstruction. Record a lengthy
command with valid shell line continuations to honor the body width.

### 2. TypeScript and shared conventions

Extend `expo/tsconfig.base`. Explicitly enable `strict` and
`noUncheckedIndexedAccess`, as Emma does. Add other strictness options
only when they have a concrete benefit and fit the selected SDK; do
not add flags, aliases, platform suffixes, or exclusions just because
Emma's larger app needs them. Include application and test code in
typechecking once the tests exist.

Wire project guidance so both agents keep loading the same conventions:
the project's `CLAUDE.md` directs readers to the personal Claude guidance
and `~/.claude/skills/expo-conventions/SKILL.md`; its `AGENTS.md` tells
Codex to read that project `CLAUDE.md` too. Preserve relevant generated
Expo guidance, particularly links to the selected SDK's versioned docs.
Do not duplicate the whole shared skill into either project file.

Reference the shared naming, functional components, `const`-only,
immutability, type design, and comment conventions. Record test-first
development as the project's working method. The scaffold is the
bootstrap exception; new behavior starts with a failing test.

### 3. Linting and Emma's formatting

Use Expo's supported ESLint configuration format for the selected SDK
and integrate Prettier without conflicting style rules. Start from
[the Emma-derived formatter baseline](../assets/prettierrc.json), copied
into the project's Prettier config. Its provenance is below. Keep the
current Emma style if it has intentionally evolved; ask about meaningful
departures rather than silently changing the formatting policy.

Provide format-write, format-check, and lint scripts. Lint fails on
warnings. Enforce house rules with compatible lint rules where practical:
`prefer-const` alone does not prohibit `let`, and `const` alone does not
prevent object or array mutation. Keep naming and style review in the
workflow even where lint cannot decide intent. Format the scaffold in
this commit so the first commit remains recognizable generated output.

### 4. TDD tooling, Expo Doctor, and checks

Install compatible Jest, `jest-expo`, and React Native Testing Library
versions from Expo's current testing guide. Do not copy Emma's legacy
testing-library versions or deprecated renderer setup. Provide watch
mode for TDD and a non-watching test/coverage command for verification.
Exercise the scaffold's rendered behavior to verify the harness; prove
that a failing assertion fails the command. Do not retain placeholder
tests or use `passWithNoTests` to manufacture a green gate.

Keep tests behavior-oriented. Write one failing test, run it and read
the failure, make the minimum change to advance it, then refactor under
green. Use Emma's 100% lines/branches/functions/statements standard for
application source; include all application source and explicitly
justify exclusions. Do not inherit its `src/untested` escape hatch or
exclude future files by only collecting already-tested modules.

Make `expo-doctor` a repeatable script and a required check, including
in CI and before commits. Keep dependency compatibility checks too.
Do not copy Emma's Doctor exclusions or reinstall/delete dependencies
as a generic Doctor fix. Resolve reported problems individually.

Create `checks.config.json` for the existing checks runner, covering
typecheck, lint, format-check, tests with coverage, Expo dependency
compatibility, and Doctor. Provide one project script for that full
gate; install/resolve the runner reproducibly for a fresh checkout.
On Nick's configured machines, use `mise exec -- checks` when appropriate
to the shared guidance. Wire pre-commit and CI to the same complete gate
and arrange hook setup for fresh checkouts. Agents still run the full
gate before commits rather than assuming a hook ran. No tests in watch
mode, automatic formatter fixes, or hidden skipped checks in this gate.

All configuration/tooling setup is complete before the next commit.

### 5. OTA updates — always the final setup commit

This is the first added product behavior. Drive it with failing
behavioral tests, one scenario at a time, using the tooling above.
Install the SDK-compatible `expo-updates`, configure actual EAS project
identity, channels, and runtime compatibility, and provide the project's
update command. Never copy Emma's identifiers or credentials. Resolve
missing account/project details through available context, then ask for
what is still needed; do not invent values or claim OTA is configured
with placeholders. Publishing and native builds need their own user
authorization; setup commits alone do not authorize them.

The requested behavior is:

- On cold start, check/download and automatically apply an available
  compatible update without a permission prompt.
- On returning from the background, do the same automatically.
- When an update is found while the user remains in the open app,
  ask before restarting. Acceptance applies it; declining keeps the
  current session running. The next cold start or foreground is still
  eligible for automatic application.

Define an explicit mechanism for discovering updates during continuous
active use, using supported Expo APIs. An EAS publication is not itself
a push notification. If periodic checks are needed, use a documented
cadence with a named duration and test the behavior; ask Nick about a
material interaction tradeoff instead of inventing one silently.

Coordinate launch, foreground, download, and prompt handling so an
in-flight operation cannot cause duplicate prompts or restart loops.
Use lifecycle events, not arbitrary delays, to decide whether an update
is part of entry or active use. Handle unavailable networks and update
failures without trapping the user at startup; never claim that a newly
published update is instantly available on an offline device. Use a
bounded startup wait and fall back to the installed working bundle.

Read Emma's update integration and existing helper packages before
choosing an implementation; reuse them if they satisfy the requested
behavior and current SDK. Do not blindly copy its sign-in-based restart
policy. Test automatic entry updates, active-use accept/decline,
failures, and overlapping lifecycle events at the relevant boundary.
Verify real delivery/reload behavior in an authorized preview/release
build; Expo Go and mocked tests cannot prove OTA delivery. Report that
device verification as pending if a build/account/device is unavailable.

Run the full gate and commit the OTA implementation last. If verification
finds an earlier tooling problem, fix and commit that before the OTA
commit rather than adding a setup-only follow-up after it. Never publish
an update merely to finish this workflow without authorization.

## Emma reference and formatter provenance

The baseline was read from mobile Emma on 2026-11-22 at revision
`56eef44240e65f792cdb001d052f36b9fe6173a1`:

- `.prettierrc`: the bundled asset preserves all general options and
  omits only the email-injected-JavaScript-specific semicolon override.
- `tsconfig.json`: extends Expo's base with `strict` and
  `noUncheckedIndexedAccess`.
- `CLAUDE.md` and `jest.config.ts`: functional style, outside-in TDD,
  and full application coverage.
- `src/layouts/app/hooks/useOverTheAirUpdates.ts` and
  `src/layouts/app/functions/askPermissionToApplyUpdate.ts`: check at
  launch/focus, but ask before restarting when signed in. Nick's
  explicit entry-versus-active-use policy above supersedes that detail.
- `src/untested/localDependencies/downloadAndApplyOtaUpdatesInTheBackground/index.ts`:
  background update task; its scheduling is not a guarantee of prompt
  delivery and is not mandatory setup for every new app.
- Emma's first commit, `4a67334fe1b7e7c8cae99ce79c2cd636eca609e1`,
  recorded a Bun `blank-typescript` scaffold. Separate lint, formatting,
  and Jest commits followed. Preserve the useful sequence, not old
  SDK versions or historic workarounds.

Read current examples from `~/code/emma` or authenticated
[`pachun/emma`](https://github.com/pachun/emma). OTA helpers are
[`simple-expo-update`](https://github.com/pachun/simple-expo-update) and
[`react-native-use-app-lifecycle`](https://github.com/pachun/react-native-use-app-lifecycle).
