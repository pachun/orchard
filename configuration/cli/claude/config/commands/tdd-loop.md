---
description: Drive a group of failing tests to green with the strict-TDD multi-agent loop (runner → implementer → critic)
argument-hint: [which tests — a path, path:line, or a description like "the failing tests we just created"]
---

Run the `tdd-loop` workflow on the tests described by: **$ARGUMENTS**

Steps:

1. Resolve **$ARGUMENTS** to concrete test target(s). It may be an explicit path
   or `path:line`, a space-separated list of them, or a description that refers
   to tests from our conversation (e.g. "the failing tests we just created").
   If you cannot tell which tests are meant, ask before running.
2. Detect this repo's test command (mix.exs → `mise exec -- mix test`,
   package.json → its test script, `bun test`, `npx jest`, etc.).
3. Invoke the Workflow tool (this command is an explicit opt-in to running it):

   ```
   Workflow({
     scriptPath: "/home/nick/.claude/workflows/tdd-loop.js",
     args: { target: "<resolved target(s)>", testCommand: "<the test command>" }
   })
   ```

4. When it returns, relay its summary — status, how many groups were driven to
   green, and anything it got stuck on.

What the workflow does: it freezes the currently-failing tests as a group and
drives each to green one at a time — a runner finds the first failure, an
implementer writes the minimal fix, a critic gates it for minimality — ignoring
any collateral breakage until the whole group is green. Only then does it run
the full suite, and any new failures there become the next group.
