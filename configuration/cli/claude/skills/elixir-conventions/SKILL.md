---
name: elixir-conventions
description: Create, develop, and review Elixir/Phoenix projects using emma_api as the house reference, outside-in BDD, checked setup commits, GitHub CI, and deployment appropriate to the host.
---

# Elixir conventions

Apply throughout Elixir and Phoenix development, including initial setup.
Read the shared personal `~/.claude/CLAUDE.md` and `.MD` when present for
naming, comments, working permissions, and commit messages. Keep those
instructions as the source of truth.

## Emma API is the reference

Read `~/code/emma_api/CLAUDE.md` and analogous implementation and tests
before making an unresolved style, structure, or testing decision. Nick
manually developed that project and wants its decisions carried forward.
Clone `pachun/emma_api` when the reference is missing, preserving existing
checkouts. Do not substitute mobile Emma for the backend reference.

Match intent, not historical dependency versions, application names,
credentials, or unrelated infrastructure. Confirm material departures
from Emma API's conventions before adopting them; explicit instructions
in the current task take precedence. A project explicitly deployed on a
local runner does not need an unrelated cloud application.

Use immutable data, pattern matching, small modules named for the action
they perform, and the reference project's command organization. Do not
force TypeScript-specific syntax rules onto Elixir. Prefer meaningful
names over explanatory comments and unnamed constants. Read current
official documentation for the versions in use.

## Test-first development

Read [BDD](../bdd/SKILL.md) and the relevant [testing notes](../bdd/notes.md)
before writing application behavior or tests. Frame the user-visible
requirement first, write one failing scenario, read the actual failure,
and make only the change it demands. Refactor under green.

Use Emma API's `test/support/` vocabulary and analogous tests as the
reference. Identify seams before writing the scenario: web handlers
delegate to commands; business commands exercise their real subtree and
mock genuine external I/O. Follow its serializer and TestSeam conventions
where applicable. Do not import its entire test framework or database
fixtures into a project that does not need them.

Keep application coverage at 100%, with justified exclusions for specific
generated infrastructure. Collect all application modules; never whitelist
only those already tested. Do not exclude new business behavior to make
the coverage gate pass. Preserve product behavior when repairing tests.

When using Ecto, follow Emma API's database constraints, changeset
translation, constraint names, and behavioral insert/association tests.
Do not add a database solely because Phoenix supports one.

## New project setup

1. Choose a minimal generator matching the requested application. For a
   JSON/WebSocket server, omit HTML/assets and other unneeded features;
   omit Ecto when persistence is explicitly unnecessary. Record the exact
   successful generator command and resolved generator version in the
   first commit body. Pin compatible Elixir and OTP versions through
   `.tool-versions`, following Emma API's runtime reproducibility intent.
2. Validate and commit the minimal scaffold before layering on house
   setup. The generated scaffold is the bootstrap exception to BDD.
3. Add project `CLAUDE.md` and `AGENTS.md` references to these conventions
   and BDD. Configure formatting, compilation warnings as errors,
   dependency validation, ExUnit, coverage, and a single `mix check`.
   Run quick checks first, stop on failure, and run tests with coverage
   last. Use that same command locally and in CI. Add static analysis
   only where it is supported and useful.
4. Create a GitHub repository under the selected owner, add its remote,
   commit the checked setup, and push. Reuse an existing remote. Resolve
   visibility from explicit preference or comparable repositories; use
   private when uncertain rather than publishing code by assumption.
5. Add GitHub Actions checks before deployment. Follow
   [deployment conventions](references/deployment.md) for the actual host.
   Secrets belong in private runtime configuration and GitHub secrets,
   never the repository.

Nick authorizes these new-project setup commits, repository creation,
pushes, and the requested deployment workflow setup. This does not
authorize unrelated changes, rewriting history, provisioning paid
infrastructure, or changing another project's production configuration.
Run all checks available at each stage before every commit. Explicit
session instructions that narrow this authorization take precedence.

Record missing credentials rather than claiming an unconfigured workflow
works. Leave product features outside the initial setup commits and
develop them test-first.
