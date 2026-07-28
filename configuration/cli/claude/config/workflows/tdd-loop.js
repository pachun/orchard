export const meta = {
  name: 'tdd-loop',
  description:
    'Drive failing tests to green one minimal change at a time: a runner finds the first failure, an implementer makes the smallest fix, a critic gates it for minimality, repeat until green, then verify the whole suite',
  whenToUse:
    'You have a red test (or a list/target of red tests) and want them driven to green under strict TDD — one failure message at a time, the minimal change per message, each change reviewed for minimality before moving on.',
  phases: [
    { title: 'Triage', detail: 'runner runs the target and reports the first failure' },
    { title: 'Advance', detail: 'implementer makes the minimal fix, critic gates minimality, until the test is green' },
    { title: 'Verify', detail: 'runner reruns the target and the full suite to confirm nothing regressed' },
  ],
}

// ---- inputs -------------------------------------------------------------
// args may be:
//   "path/to_test.exs"                     -> target, autodetect the runner
//   "path/a.exs path/b.exs"                -> multiple targets
//   { target: "...", testCommand: "..." }  -> explicit runner command
//   undefined / ""                         -> the whole suite
const initialTarget = (typeof args === 'string' ? args : args?.target) || ''
const givenCommand = (typeof args === 'object' && args ? args.testCommand : null) || null

// ---- safety caps --------------------------------------------------------
const MAX_ROUNDS = 10 // group -> full-suite passes before giving up
const MAX_ADVANCES = 25 // red -> green steps allowed per single test
const MAX_IMPL_ATTEMPTS = 5 // implementer tries per advance (same-error retries + critic redos)

// ---- structured outputs -------------------------------------------------
const RUNNER_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['green', 'test_command', 'failing_tests', 'first_failure'],
  properties: {
    green: { type: 'boolean', description: 'true iff every targeted test passed' },
    test_command: { type: 'string', description: 'the exact command used to run tests, without the target' },
    failing_tests: { type: 'array', items: { type: 'string' }, description: 'failing test ids, in reported order' },
    first_failure: {
      anyOf: [
        { type: 'null' },
        {
          type: 'object',
          additionalProperties: false,
          required: ['test_id', 'message'],
          properties: {
            test_id: { type: 'string', description: 'exact id to run ONLY this test, e.g. path/to_test.exs:42' },
            message: { type: 'string', description: 'the complete failure output for this test' },
          },
        },
      ],
    },
  },
}

const IMPL_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['diff', 'outcome', 'new_message'],
  properties: {
    diff: { type: 'string', description: 'the precise change made — actual patch text of only what you touched' },
    outcome: { type: 'string', enum: ['green', 'new_error', 'same_error'], description: 'result of running only the target test after the change' },
    new_message: { type: 'string', description: 'the failure message after the change; empty if green' },
  },
}

const CRITIC_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['minimal', 'reasoning', 'reduction'],
  properties: {
    minimal: { type: 'boolean', description: 'true only if every added line is demanded by this one failure' },
    reasoning: { type: 'string' },
    reduction: { type: 'string', description: 'if not minimal, exactly what to remove/simplify; empty if minimal' },
  },
}

// ---- prompts ------------------------------------------------------------
const runnerPrompt = (target, testCommand) => `
You are the RUNNER in a strict-TDD loop. Do NOT edit any code — only run tests and report exactly what happened.

${
  testCommand
    ? `Run: ${testCommand} ${target}`.trim()
    : `Detect this repo's test runner (mix.exs -> \`mise exec -- mix test\`, package.json -> its test script, etc.) and run it against: ${target || '(the whole suite)'}`
}

Report per the schema:
- green: did everything pass?
- test_command: the exact command you used, WITHOUT the target, so later runs match.
- failing_tests: the failing test ids in the order printed.
- first_failure: for the FIRST failing test only, give test_id (the exact "<path>:<line>" to run just that one) and message (its FULL failure output — error, assertion, stacktrace). null if green.
Report what the runner printed; invent nothing; fix nothing.
`

const implementerPrompt = (testId, error, testCommand, feedback) => `
You are the IMPLEMENTER in a strict-TDD loop. Write the MINIMAL production code to advance PAST exactly this one failure — nothing more. No extra fields, no speculative branches, no handling for errors you have not literally seen, no fuller implementation than THIS message demands. A compiler/undefined error counts as a failure; a placeholder is often the right minimal step.

Run ONLY this test: ${testId}
Current failure message:
---
${error}
---
${feedback ? `A reviewer rejected your previous attempt. Revert any excess and redo it minimally, applying:\n${feedback}\n` : ''}
Do:
1. Read the failure and find the single smallest change that moves past it.
2. Make that change — the least code possible.
3. Run only that test: ${testCommand} ${testId}
4. Report per the schema: diff (the exact patch of what you touched), outcome (green | new_error | same_error), new_message (the failure after your change, empty if green).

If you are adding more than the message requires, stop and add less.
`

const criticPrompt = (error, impl) => `
You are the CRITIC in a strict-TDD loop. Do NOT run any tests and do NOT edit code. Judge by reading only.

You get (a) the failure the implementer was told to advance past, and (b) the change they made. Decide whether that change is the MINIMAL amount necessary to advance this failure or reach green — no extra lines, no un-driven code, no speculative handling, no over-broad implementation.

Failure to be advanced:
---
${error}
---
Change the implementer made:
---
${impl.diff}
---
Implementer's reported outcome: ${impl.outcome}${impl.new_message ? ` — new message: ${impl.new_message}` : ''}

Read the change (Read the surrounding file if it helps) and decide:
- minimal: true ONLY if every added line is demanded by THIS failure. If they added a field, branch, guard for an unseen case, or a fuller implementation than the message required — it is NOT minimal.
- reasoning: why.
- reduction: if not minimal, name exactly what to remove or simplify (empty string if minimal).
Look adversarially for over-implementation. When genuinely unsure, reject.
`

// ---- orchestration ------------------------------------------------------
// Run the target, get the authoritative first failure (or green).
const runTarget = (target, testCommand, label) =>
  agent(runnerPrompt(target, testCommand), { label, phase: 'Triage', schema: RUNNER_SCHEMA })

// One advance = get from `error` to a NEW error or green: implementer retries
// on same-error, critic gates minimality on progress. Returns true if the
// implementer produced a change the critic accepted (caller then reruns).
async function makeAcceptedChange(testId, error, testCommand) {
  let feedback = null
  for (let attempt = 0; attempt < MAX_IMPL_ATTEMPTS; attempt++) {
    const impl = await agent(implementerPrompt(testId, error, testCommand, feedback), {
      label: `implement:${testId}`,
      phase: 'Advance',
      schema: IMPL_SCHEMA,
    })
    if (impl.outcome === 'same_error') {
      feedback = 'Your change did not move the error. Revert it and try a different, still-minimal change.'
      continue
    }
    const critique = await agent(criticPrompt(error, impl), {
      label: `critique:${testId}`,
      phase: 'Advance',
      schema: CRITIC_SCHEMA,
    })
    if (critique.minimal) return true
    log(`Critic rejected (${testId}): ${critique.reasoning}`)
    feedback = critique.reduction || 'Do less — only what the failure message requires.'
  }
  return false
}

// Drive ONE test id to green: the runner runs only this test to get its current
// failure, the implementer makes the minimal fix, the critic gates it, repeat
// until this test passes. Returns true on green.
async function driveToGreen(testId, testCommand) {
  for (let step = 0; step <= MAX_ADVANCES; step++) {
    const run = await runTarget(testId, testCommand, `run:${testId}`)
    if (run.green) {
      log(`GREEN: ${testId}`)
      return true
    }
    if (step === MAX_ADVANCES) return false
    const error = run.first_failure ? run.first_failure.message : run.failing_tests.join('\n')
    await makeAcceptedChange(testId, error, testCommand)
  }
  return false
}

phase('Triage')
const firstRun = await runTarget(initialTarget, givenCommand, 'runner:initial')
const testCommand = givenCommand || firstRun.test_command

// If the tests we were given already pass, we're done — do NOT touch the rest
// of the suite. The full suite only comes into play after we've had to change
// code to green a failing group.
if (firstRun.green) {
  log('Target already green — nothing to do.')
  return { status: 'green', groupsDriven: 0, target: initialTarget }
}

// The FIXED original failing group. We drive exactly these to green, one at a
// time, running ONLY that test. Any collateral breakage of tests OUTSIDE this
// group is deliberately ignored until the whole group is green — only THEN do
// we "consider everything" by running the full suite. If that surfaces failures
// (regressions or otherwise), they become the next group and we repeat.
let group = firstRun.failing_tests
let groupsDriven = 0

for (let round = 0; round < MAX_ROUNDS; round++) {
  phase('Advance')
  log(`Group ${round + 1}: ${group.length} failing test(s) to green — collateral breakage ignored until the group is done: ${group.join(', ')}`)

  for (const testId of group) {
    const greened = await driveToGreen(testId, testCommand)
    if (!greened) {
      log(`Could not green ${testId} within ${MAX_ADVANCES} advances — stopping.`)
      return { status: 'stuck', stuck_on: testId, groupsDriven }
    }
  }
  groupsDriven++

  // The final test in the group is green — now, and only now, consider everything.
  phase('Verify')
  log('Group green — running the full suite.')
  const full = await runTarget('', testCommand, 'runner:full-suite')
  if (full.green) {
    log(`Done: ${groupsDriven} group(s) driven, full suite green.`)
    return { status: 'green', groupsDriven }
  }
  log(`Full suite has ${full.failing_tests.length} failure(s) after greening the group — that's the next group.`)
  group = full.failing_tests
}

log(`Hit the ${MAX_ROUNDS}-round cap without full-suite green.`)
return { status: 'capped', groupsDriven, remaining: group }
