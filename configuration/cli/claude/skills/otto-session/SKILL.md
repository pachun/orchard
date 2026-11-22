---
name: otto-session
description: Bootstrap an agent conversation started by the Otto voice runner. Apply the target project's guidance and keep its Expo development client usable automatically during prompting. Not specific to developing Otto itself.
---

# Conversations started by Otto

Apply this at the beginning of every agent conversation launched by the
Otto runner, regardless of the repository the request concerns. Otto is
the entry point; the target might be Emma, Perch, Otto, or another project.

Read the shared personal `~/.claude/CLAUDE.md` and `.MD` when present,
then the target project's applicable instructions before editing it.
Retain the project's working permissions and release policy. A voice
request does not bypass approval requirements.

When the target is an Expo app, load
[Expo conventions](../expo-conventions/SKILL.md) at the start of work and
follow its development-client workflow throughout the session. Native
changes require automatically checking and rebuilding that project's
development variant, keeping Metro reachable, and delivering the finished
install link through private notification settings. Do not wait until the
feature is finished or ask the user to remember the native build step.
Reuse a compatible completed or running build.

Use the target project's own identifiers, profiles, credentials, and
deployment workflow. Never substitute Otto's development app for the
target app. Production/TestFlight delivery follows the project's checked,
authorized commit and push at verified feature completion or a requested
checkpoint; intermediate previews stay in the development app.

Close the installation loop automatically for the target project. A
finished development build sends an SMS naming the app and linking its
installation page. The production release workflow also sends an SMS
when the new TestFlight build is available to the intended tester, linking
TestFlight. EAS completion or upload alone does not establish TestFlight
availability; distinguish Apple processing and external-test review from
an installable build. Preserve those delivery states when reporting progress.
Deduplicate notifications by project, variant, build, and delivery milestone.
Recipient numbers and messaging credentials stay in private runner
configuration, never a shared skill, repository, or app bundle. Report
disabled or unavailable notification setup rather than claiming a text
was sent. Verify delivery separately from provider acceptance.

The runner must explicitly name this skill in each new agent session's
startup instructions. Merely installing the skill does not load it into
an already-running conversation. Read the source file rather than copying
its rules into every prompt.
