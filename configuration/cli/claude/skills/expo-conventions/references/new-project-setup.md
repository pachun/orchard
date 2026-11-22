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
- [First native build](https://docs.expo.dev/build/setup/)
- [Internal distribution](https://docs.expo.dev/build/internal-distribution/)
- [App variants](https://docs.expo.dev/build-reference/variants/)
- [Development builds](https://docs.expo.dev/develop/development-builds/introduction/)
- [Using a development build](https://docs.expo.dev/develop/development-builds/use-development-builds/)

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
committing unrelated work, rewriting history, or deploying other projects. Nick
also requests GitHub repository creation and initial pushes, plus an
Emma-style workflow for authorized release-branch deployments: build and
submit when the app version changes; otherwise publish a compatible OTA.
Submission uploads to App Store Connect/TestFlight; it does not authorize
making an App Store listing public. Nick
also requests initial development and release iPhone builds and necessary
Expo/Apple Developer setup as part of new-project initialization, as
described below. For later setup and convention changes, follow the
shared guidance's end-to-end completion authorization, including scoped
commits, pushes to existing remotes, Orchard sync, and development build
delivery when needed.
A session's explicit instruction
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

Follow the parent skill's outside-in testing section and linked BDD
discipline. Start with the user's situation, action, and observable
result through the real app; use Emma's examples. Narrow seam tests
need a concrete reason, not just convenience. Write one failing test, run it and read
the failure, make the minimum change to advance it, then refactor under
green. Use Emma's 100% lines/branches/functions/statements standard for
application source; include all application source and explicitly
justify exclusions. Do not inherit its `src/untested` escape hatch or
exclude future files by only collecting already-tested modules.

Make `expo-doctor` a repeatable script and a required check, including
in CI and before commits. Keep dependency compatibility checks too.
Do not copy Emma's Doctor exclusions or reinstall/delete dependencies
as a generic Doctor fix. Resolve reported problems individually.

Provide a single `check` package script, such as `bun run check`, that
runs formatting, lint, typecheck, Expo dependency compatibility, Doctor,
and finally tests with coverage. Run sequentially and stop at the first
failure; do not start slow checks or tests while earlier checks are
still running. Adjust the earlier order using actual timings while
keeping tests last. A shell `&&` chain of package scripts is sufficient;
do not add a custom runner just to sequence commands. If using an
existing `checks.config.json`, verify that its runner supports this
ordering and fail-fast behavior rather than assuming parallel execution
meets the requirement. Wire pre-commit and CI to the same complete gate
and arrange hook setup for fresh checkouts. Agents still run the full
gate before commits rather than assuming a hook ran. No tests in watch
mode, automatic formatter fixes, or hidden skipped checks in this gate.

### 5. Separate development and release apps

Configure two installable variants before adding OTA behavior:

- **Development:** a clearly labeled app such as `App Dev`, with its own
  iOS bundle ID (for example, the release ID plus `.dev`). Install the
  SDK-compatible `expo-dev-client`; use a `development` EAS profile with
  `developmentClient: true` and internal distribution.
- **Release:** the normal app name and stable production bundle ID,
  compiled without development mode. An internal `preview` profile can
  install this variant during setup; the `production` profile is for
  store distribution. Those profiles share the release identity, so
  they replace each other, while the development app remains installed.

Use dynamic Expo configuration with an explicit variant selector such
as `APP_VARIANT`. Set it consistently for EAS builds and local Metro
commands. Give Android variants distinct package names when configuring
Android. Keep custom URL schemes distinct and enable the dev client's
generated scheme only for the development variant so its QR codes open
the correct app. Preserve an existing app's release identity.

Provide a `dev` package command that selects the development variant
and runs `expo start --dev-client`. Expose explicit build commands for
each profile. Evaluate the resolved Expo configuration for both variants
and check their names, identifiers, schemes, and profile selections
before committing. Run the full check command too.

The daily prompting loop is: start Metro on the runner, open the
development app on the phone, and review edits through Fast Refresh.
Verify the phone can reach the advertised Metro address over the local
network or tailnet; use Expo's tunnel option when needed. Share the
actual connection link or QR code. Metro must remain running and
reachable; this is not an offline preview. Native module, native config,
or SDK changes require a new development build.

All configuration/tooling setup is complete before the final OTA commit.

### GitHub remote and deployment workflow

Include this configuration before the final OTA behavior commit. Read
mobile Emma's current `.github/workflows/main.yml` and build, submission,
and OTA scripts. Preserve the behavior, not outdated tooling or fragile
implementation details.

Create a GitHub repository under the selected owner, add its remote, and
push the checked setup. Reuse existing remotes. Infer visibility from an
explicit preference or comparable repositories; choose private when
uncertain. Do not overwrite an existing repository or change visibility.

Pull requests run the aggregate checks. Pushes to the configured release
branch, normally `main`, check before deploying the exact checked revision.
A new Expo app version builds a production iOS binary and submits that
exact build to App Store Connect. An unchanged version with a compatible
production binary publishes an OTA to the explicit production channel
and environment. First deployments need a binary.

Evaluate resolved release Expo config, not `package.json` or the dev
variant. Handle first pushes, multi-commit pushes, and failed deployments:
an immediate-parent comparison alone does not establish which version
was successfully built/deployed. Verify the native runtime baseline;
native dependency/configuration changes require a version bump and build,
even if someone forgot to update the version.

Pin tooling consistently with local setup. Serialize deployments without
canceling submissions. Prefer build-specific submission or EAS auto-submit
over `--latest`, which could select an unrelated concurrent build. Keep
credentials in supported secret stores. Configure the real Expo project,
Apple team, bundle ID, and App Store Connect app ID; never copy Emma's.

Repository creation, initial push, and configuration of this release
workflow are part of Nick's setup request. Routine prompting still uses
Metro in the development app; do not publish just to preview an edit.
Report missing CI credentials, signing, or submission setup as unfinished.

- https://docs.expo.dev/build/building-on-ci/
- https://docs.expo.dev/build/automate-submissions/
- https://docs.expo.dev/eas-update/github-actions/

### 6. OTA updates — always the final setup commit

This is the first added product behavior. Drive it with failing
behavioral tests, one scenario at a time, using the tooling above.
Install the SDK-compatible `expo-updates`, configure actual EAS project
identity, channels, and runtime compatibility, and provide the project's
update command. Never copy Emma's identifiers or credentials. Resolve
missing account/project details through available context, then ask for
what is still needed; do not invent values or claim OTA is configured
with placeholders. The initial native phone builds are authorized as part
of this workflow. Release publication and binary submission run through
the authorized deployment workflow above; manual publications outside
that workflow need separate authorization.

Keep OTA channels and publication environments explicit for release
profiles. Bundle IDs alone do not isolate update delivery. Select the
matching app variant when publishing, and never publish an OTA merely
to preview an edit during prompting. The development command uses
Metro; release update checks must not interrupt that development session.

The requested behavior is:

- Check on cold start and return to the foreground. Ask permission
  before downloading and restarting, regardless of sign-in state.
- Acceptance downloads and applies the compatible update. Declining
  leaves the current session running; a later launch or foreground can
  offer it again. Do not pre-download a declined update that Expo would
  silently apply on the next cold launch. Configure native automatic
  checks consistently with this policy.
- Prompts feel friendly, personal, warm, and encouraging without
  pressure. Name the app, make the restart clear, and offer an equally
  clear "Not now" choice. Avoid technical jargon, urgency, invented
  release benefits, or promises about saved work and restart duration.

Never poll for updates. Do not add intervals, recurring checks, or an
OS-scheduled background polling task. Check on lifecycle events and
respond to actual native update events. Trace Emma's implementation
before proposing additional mechanisms. An EAS publication is not
itself a push notification; do not promise instant discovery during
uninterrupted foreground use without an actual delivery signal.

Coordinate launch, foreground, download, and prompt handling so an
in-flight operation cannot cause duplicate prompts or restart loops.
Use lifecycle events, not arbitrary delays, to decide when to check.
Handle unavailable networks and update
failures without trapping the user at startup; never claim that a newly
published update is instantly available on an offline device. Use a
non-blocking check so the installed working bundle remains usable.

Read Emma's update integration and existing helper packages before
choosing an implementation; reuse them if they satisfy the requested
behavior and current SDK. Do not blindly copy its sign-in-based restart
policy. Test launch/foreground invitations, accept/decline,
failures, and overlapping lifecycle events at the relevant boundary.
Verify real delivery/reload behavior in an authorized preview/release
build; Expo Go and mocked tests cannot prove OTA delivery. Report that
device verification as pending if a build/account/device is unavailable.

Run the full gate and commit the OTA implementation last. If verification
finds an earlier tooling problem, fix and commit that before the OTA
commit rather than adding a setup-only follow-up after it. Never publish
an update merely to finish this workflow without authorization.

## Finish with both apps installed on the iPhone

New-project setup includes getting both native variants onto Nick's
phone, not stopping at a local scaffold or Expo Go. Configure the real
Expo owner/project and Apple Developer team, both bundle identifiers,
signing credentials, and device provisioning through EAS. Reuse the
session's selected accounts; when multiple Apple teams exist, resolve
ownership before creating identifiers or credentials. Do not copy
another app's identity or revoke existing signing certificates.

Prepare both build profiles before the final OTA commit. Build the
development client and an internal preview of the release variant with
an explicit update channel. Use store distribution for the release
variant instead only when separately authorized. Register the phone
through `eas device:create` if it is not already registered, and ensure
both provisioning profiles include it. Give Nick the actual device
registration URL when phone interaction is required. If Apple sign-in
or two-factor authentication is required, arrange an interactive CLI on
the machine Nick is driving; keep credentials out of chat and logs.

After checks and the final OTA setup commit, start both iOS builds,
follow each to completion, and provide clearly labeled installation
links or QR codes. Confirm both apps coexist: the release app opens
without Metro, and the development app loads Metro and displays a small
edit through Fast Refresh without an OTA publication. Remove any
temporary verification edit afterward and rerun affected checks. Report
device verification as pending until confirmed. Creating both initial
builds and necessary Expo/Apple records is part of the standing setup
request. The release workflow above covers subsequent authorized
deployments and binary submissions. Paid plan changes and making an
App Store listing public require separate authorization.
Do not mark setup finished if authentication, provisioning, the build,
or installation is still blocked. Preserve progress and name the exact
remaining step.

### Text the initial installation links

Nick requests one text per initial internal iPhone build with its
installation link, labeled with the variant's app name (`App Dev` or
`App`). On the Framework runner, save each finished build record with
`eas build:view BUILD_ID --json`, then call
`notify-build --app APP_NAME /path/to/completed-build.json`. Run this from
the successful completion step, never from a polling loop. The CLI
verifies the build is finished and records attempts to prevent duplicate
texts. Report provider acceptance separately from confirmed delivery.

The reusable notifier lives in `~/code/notifications`; Orchard installs
a command wrapper when configuring its build-notifications feature.
Personal opt-in, recipient, Messaging Service, and dedicated Twilio key
are stored only in `~/.config/orchard-private/notifications.json` on the
runner (directory 0700, file 0600). Never put actual phone numbers or
credentials in skills, project code, public examples, command arguments,
or logs. Other users supply their own configuration; missing configuration
means texting is disabled, with no fallback recipient. Do not read Emma's
production configuration during normal build notifications.

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
  permission-prompt policy above applies regardless of sign-in state.
- `src/untested/localDependencies/downloadAndApplyOtaUpdatesInTheBackground/index.ts`:
  background update task; its scheduling is not a guarantee of prompt
  delivery. Do not copy it: Nick explicitly prohibits OTA polling.
- Emma's first commit, `4a67334fe1b7e7c8cae99ce79c2cd636eca609e1`,
  recorded a Bun `blank-typescript` scaffold. Separate lint, formatting,
  and Jest commits followed. Preserve the useful sequence, not old
  SDK versions or historic workarounds.

Read current examples from `~/code/emma` or authenticated
[`pachun/emma`](https://github.com/pachun/emma). OTA helpers are
[`simple-expo-update`](https://github.com/pachun/simple-expo-update) and
[`react-native-use-app-lifecycle`](https://github.com/pachun/react-native-use-app-lifecycle).
