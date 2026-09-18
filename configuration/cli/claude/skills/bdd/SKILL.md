---
name: BDD
description: The strict outside-in BDD discipline for the emma (React Native/Expo) and emma_api (backend) codebases — Pivotal Labs / XP style. Invoke before writing or modifying ANY test or production code in these repos. It governs how we work (one failing test at a time; no production code without a failing message; write only enough code to advance the current failure; refactor only under green) and how we keep coverage at a true 100% (blacklist omissions only, never whitelist). It is also the running notebook of worked examples and lessons learned — keep it current as we work.
---

# BDD — how we work in emma and emma_api

Strict, outside-in behavior-driven development in the Pivotal Labs / XP
tradition. Nick has no human pair; Claude is the pair. This file is the
doctrine and the operating manual. The running log of concrete lessons
and boundary calls lives in [notes.md](notes.md) — read it too, and
append to it as we learn.

## The core belief

The test suite is the executable product specification. Kept at a true
100% coverage, it is the invariant that makes refactoring fearless: if
every line is genuinely *exercised* by a test asserting a real product
outcome, then a green suite at 100% means every product requirement
still holds. That is the whole point — the freedom to restructure
internals without fear comes entirely from trusting the suite.

## The rules (non-negotiable)

1. **No production code without a failing test.** A failing message is
   the license to write code. If there is no red, we do not write
   production code — we write the test that demands it.
2. **Only enough code to advance the current failure message.** Not the
   whole feature. The next red→green step, and nothing more.
3. **One test at a time.**
4. **Refactor only under green.** Outside-in tests couple to behavior,
   not internals, so they give total freedom to restructure. If the
   tests stay green and coverage stays at 100%, the product still
   satisfies every requirement.
5. **Coverage stays *at* 100%** — lines, branches, functions,
   statements. Not "about 100%". An arbitrary number like 87.5% is
   nearly worthless: coverage could rise in one area and fall in
   another and the number wouldn't tell you which 12.5% went dark. The
   number is the invariant.
6. **Omissions are blacklisted, never whitelisted.** The only uncovered
   code is code we have *explicitly* denoted as uncovered: the
   `collectCoverageFrom` exclusions in `jest.config.ts`
   (`!src/types/**`, `!src/untested/**`) and each individual
   `/* istanbul ignore … */`. Everything not on that blacklist is
   known-covered — really exercised, not merely run by the suite.
7. **Every line must be justified by a failing test.** If you cannot say
   why a line exists, delete it and run the suite. A red test names its
   purpose (the English `it` title) and demonstrates its use (the body).
   If deleting the line breaks nothing, the line should not exist. This
   forces the product decision to be made up front — before any code is
   written — because you cannot add code without first having a test
   that demands it.

## Tests drive the addition of code, never its removal

A failing test is a license to *add* code. It is never a license to
*remove* code. You do not write a test that asserts something is gone,
absent, or no-longer-sent in order to justify deleting it. A
"prove it's not there" test — a `refute`, a "does not call", an
asserted-absence — is not a product requirement; it is a tombstone you
now have to maintain forever, and it inverts the entire value of the
suite.

Removal is the mirror image of rule 7's documentation benefit. Every
line worth keeping is *defended* by a test: delete the line and some
test reddens, and that red is the English name of the requirement the
line serves. So you remove code by making it defended by nothing, then
deleting it and watching the suite **stay green**. Green-after-deletion
*is* the proof the line served no product requirement — under faithful
BDD, exactly the signal that it should go.

When a line exists only because a test *asserts* it, and that assertion
turns out to codify something that was never a real requirement — an
over-specified request shape, a guessed implementation detail, a wrong
contract — the path is:

1. Delete the assertion that props the line up. Not because we are
   "testing removal," but because that assertion never named a real
   product requirement in the first place.
2. Delete the now-undefended production line.
3. Run the suite. It stays green. That green is the proof.

The anti-pattern to catch yourself doing: reaching for `refute` /
`assert absent` / "flip the assertion so deleting the code makes it
pass." That is a test written to drive a removal. Stop, and instead find
what defends the line and ask whether *that* was ever a real
requirement.

**Coverage is not drivenness — and prefer "driven" to "defended."** A
line can be *executed* by the suite (100% covered) and still be required
by no assertion: remove it and the suite stays green. Coverage tells you
a line *ran*; only delete-it-and-watch-for-red tells you a test *drives*
it. So a line is either **driven** — remove it, something reds, and that
red is the English name of its requirement — or it is **cruft** — remove
it, green holds, delete it. There is no third "covered but fine" state.
Say a line is *driven*, not *defended*: "defend" frames the line as
primary and the test as its bodyguard; "driven" keeps the real order —
the test comes first and demands the line. Watch for the scaffold that
hides the difference: a persistent network mock that silently answers a
duplicate request keeps the suite green when a driven-looking line is
pulled, making cruft read as covered. (See notes.md, 2026-07-25 —
coverage is not drivenness.)

## Never bend product behavior to make a test pass

The test serves the product, never the reverse. When a test is hard to
satisfy — an `act()` warning, a stubborn async-timing issue, an awkward
seam — that is a signal about the *test* or the *code structure*, not a
license to change what the product does for the user. Moving *when a
spinner appears*, *what a button navigates to*, *which fields get sent*,
in order to get green, is the tail wagging the dog: it ships a worse
product to dodge a test-harness problem.

*Proposing* a behavior change is different, and welcome. If the current
behavior genuinely seems wrong, say so and suggest the alternative with
its rationale, then let the product decision be made explicitly (rule 7).
What is never OK is *silently* changing behavior because you couldn't
find the technical fix — doubly so when the honest fix was a conventional
one you hadn't found yet. A working sibling almost always shows it: when
one feature's test is clean and yours isn't with identical test
structure, the difference is in the *production code* (a thin
button-delegates-to-command vs inlined logic, say), not the harness, and
"luck" is never the explanation. Match the sibling's structure. The
forcing check: if the reason for a behavior change is "so the test
passes," stop.

## A branch the type-checker forces is not a branch to test

The inverse of "coverage is not drivenness": a conditional can exist only
to satisfy the type-checker, its untaken side holding no code and no
requirement. The canonical case is narrowing a discriminated union to
reach a field —

    const result = await launchPhotoPicker()
    // { canceled: true } | { canceled: false, assets: [...] }
    /* istanbul ignore else */
    if (!result.canceled) {
      attach(result.assets)
    }

The `if` is there so TypeScript will let us touch `result.assets`; there
is no else, because we have speced no cancel behavior. Branch coverage
still flags the missing else — but that is the tool demanding a test for
a path that does not exist. Writing one tests the coverage tool, not the
product, and it tends to produce nonsense: a contrived "cancel, then
pick, then assert the pick showed" that reads like it was
reverse-engineered from a coverage report, because it was.

This is the legitimate use of rule 6's blacklist: mark the phantom else
`/* istanbul ignore else */` and move on. Keep the bar high — *only* for
a branch whose other side is empty by construction (a type guard, an
exhaustiveness fallback the types prove unreachable), never a real branch
you have not driven yet. If the else would ever hold behavior, it is a
product branch and needs its own red. Adding the guard itself is fine:
writing code to make the compiler pass is normal — a compiler error is a
failing message like any other — and the guard earns its place the moment
TypeScript demands it.

\* `istanbul ignore else` is istanbul syntax — these repos' coverage
provider. The principle is general; the incantation is per-tool.

## An assertion on a call must pin the values, not a wildcard

Asserting a collaborator was *called with* a wildcard — `_`, an
unconstrained arg, `[_]` ("called with one of anything") — cannot drive
behavior. Whatever you leave as `_` is the argument you've declared the
test doesn't care about, and that is precisely where the real work lives.
The tell is concrete: you can satisfy the assertion by making the
implementation pass `""`, `nil`, or a hardcoded literal in that slot, and
the test stays green while the fetch/serialize/build it was meant to force
never runs. A test you can pass with `""` drove nothing.

Pin the values that flow from the test's input through to the call — the
sender and subject the notification will show, the id that routes it —
chosen so the only way to produce them is the real work.
`called_with([_])` is worthless; `called_with([%{id: conversation_id,
messages: [%{from: %{name: "Sender"}, subject: "Subject"}]}])` forces the
code to actually fetch and serialize the message. Partial-matching to
ignore incidental fields is fine — pin the fields the behavior yields,
skip the rest — but pin *something only the behavior produces*, never the
whole argument as `_`. (See notes.md, 2026-07-30.)

## Outside-in is also your feasibility probe — start there

Always write the outermost, user-facing failing test *first* — even when
the change looks like "just a model tweak" or "just a schema field." The
outer test is not only where the story lives; it is a **feasibility probe
you run before building anything**. Its Arrange step forces you to name
every observable the feature needs, so if the scenario *can't even be set
up*, you have found the blocker for the price of a test stub — not a
model, a migration, and a passing inner test you then have to unwind.

Inner layers lie to you here. A model, a schema, a pure function compose
and pass green in isolation *precisely because* they don't know whether
anything above them can use them — so green at the model tells you nothing
about whether the feature is buildable. (Worked case: a read-receipt model
built bottom-up went green, then the integration revealed the provider
returned no stable id to correlate on — the outermost test could never
have been arranged, and would have said so first. See notes.md,
2026-08-02.)

So: if the model is really needed, the outer red reaches down and demands
it — you build the same model, now driven and proven reachable. If the
outer test can't be arranged, stop; you've found a blocker before touching
the schema. The only reasons to start below the top are the named
exceptions — a pure refactor under green, or a transitive-seam contract
restated one seam at a time — and you say which one and why.

## Outside-in: tests speak the user's language

A test is a roughly 1:1 translation of a user story. The `it` title is
the product requirement in plain English; the body is a worked example
in product terminology, abstracted to the right level by the shared
helper vocabulary. Most tests should read this way. Implementation
detail must not leak in.

**Only the detail the story needs.** The body carries exactly the setup
its assertions depend on — no more. Every extra field, unused factory
override, or bit of fixture the test never reads is noise: it buries the
one thing the test is about, and it makes the reader wonder whether it
matters. If trimming a value changes nothing the test proves, it was
never part of the story — cut it. A reactor test that only checks *that*
new inbox mail is handed to the 2FA sender needs one inbox thread; a
realistic from/subject/body it never asserts on is decoration — and
decoration reads as load-bearing to the next person, a quiet lie about
what the behavior actually depends on. This is the setup-side twin of
"a line is driven or it's cruft": a fixture value is asserted-on or it's
noise.

**This starts before the test — at the backlog.** Frame every unit of
work as a user story: something a person can or can't do, or an
experience they have. If you catch yourself writing a work item as a
technical fact ("the mmkv migration isn't set up," "the push ticket only
sets `gmail_account_id`"), stop and ask *why does the user care* — the
honest answer is the story ("when I update the app I stay signed in";
"new mail in my inbox notifies my phone"), and the technical fact is just
supporting detail for it. The forcing function: a work item you cannot
phrase from the user's side is one you do not yet understand well enough
to build, and it is exactly the one that turns out to be murky. The story
is also what you translate ~1:1 into the outermost failing test — so
naming it well up front *is* the first step of the test. ("Roughly" 1:1:
some behavior is pinned by transitive / seam tests rather than one
feature test — see the transitive exception below — but the story is
still the unit of work.) Two technical-sounding steps can belong to one
story (a webhook reactor and a push-ticket insert are both just "new
Outlook mail notifies me"); split by *user-visible outcome*, not by
module.

Structure is Arrange → Act → Assert, expressed through the vocabulary in
`emma/tests/helpers/`:

- **Arrange** — `app/signin({ … })` plus `factories/` (e.g.
  `gmailAccountFactory`, `gmailThreadFactory`, `gmailMessageFactory`)
  build the app's state as the user would actually have it.
- **Act** — `actions/` are the user's verbs: `pressText`,
  `touchTestId`, `typeIntoTestId`, `swipeLeftOnGestureTestId`,
  `pullToRefreshTestId`. The user does things; the test says so.
- **Assert** — `expectations/` are observable outcomes:
  `expectPathname` / `toHavePathnameWithParams`, `expectTextToBeVisible`,
  `expectTestIdToBeVisible`, `expectFlashMessage`,
  `expectRequestToHaveBeenMade`, and reading a field's actual
  `.props.value`. Assert on what the user observes — and on the
  observable that actually *changes*, not a proxy blind to it: read a
  field's `.props.value` to catch a stale value, not `queryByText`,
  which never sees a `TextInput`'s contents. A red that names the true
  symptom cannot pass for the wrong reason.
- **Network seams** — `mocks/` hold one `mock…Request` per API
  endpoint, set up right before the action that triggers it.

Naming: `describe` names the subject or context (nest for sub-contexts);
`it` states the observable behavior in **declarative present tense** —
"returns to the inbox screen", "shows the next thread",
"opens the compose screen with the correct prefilled information".
**No "should".** (Generic BDD advice says `it("should …")`; this
codebase does not — declarative present tense matches the house naming
style. A handful of legacy `should` titles exist; they are the
exception, not the pattern to copy.)

## Starting from a production error (Sentry, logs, or otherwise)

When a defect surfaces from the outside — a Sentry issue, a log line, a
report — it is the same outside-in loop, but the entry point is a real
incident. How we get from "an error we noticed" to "a failing test":

1. **Frame it as the user's experience, not the stack trace.** The
   exception class and stack are evidence, not the story. Translate them
   into what the person actually experienced. The Emma example: a user
   CC'd `11`, the send crashed on the backend, and *to them it looked
   like the email sent when it never did.* That sentence — not
   "`MatchError` on a strict `status_code: 200` match" — is the defect.
   Start there.

2. **Decide the intended experience first.** What *should* the user have
   seen or been able to do? A product decision, made up front, before any
   code — exactly as rule 7 demands. Get assent on it.

3. **BDD that one scenario, outside-in, from where the user sits.** The
   outermost failing test lives where the experience lives (usually a
   frontend `features/` test in emma) and drives down into the backend
   only as far as the scenario needs.

4. **One incident, one scenario at a time.** A single issue often exposes
   several things at once — the real crash, other *latent* crashes
   nearby, noise in the logs, a leaked secret. Do not fix them in one
   pass. Name them separately, take the user-facing one first; the rest
   become their own scenarios (or their own decisions to ignore).

5. **Fix only what actually broke — no speculative hardening.** The other
   happy-path assumptions sitting next to the bug are not defects until a
   real scenario makes one fail. We do not defend against inputs we
   cannot show will occur; unused defensive logic is a smell, not
   prudence. Rule 1 already says it: no red, no code. A production
   incident *is* a red waiting to be written — the untouched lines around
   it are not.

6. **Investigate the error space before generalizing.** When the failure
   is one of a family (e.g. a Gmail 4xx), look at what the family
   actually is before assuming one test covers it: is the information
   always in the same place, the same shape? Generalize a single
   test/handler over the class only when reality — not assumption — says
   the class is uniform. Where it isn't, the variants that differ are
   separate scenarios.

## The pragmatic seams (where unit-style tests are legitimate)

**Name the seams before you write the test.** What gets mocked vs exercised is
the test's design, and it follows the layer under test — decide it up front, don't
discover it mid-write. The layer→seam mapping is per-repo (see the repo's
CLAUDE.md): in emma_api, a controller test mocks the command it calls; a
business-logic test exercises the whole command subtree and mocks only external
I/O — serializers being the standing exception, always mocked via the DSL rather
than run. An explicit seam list is what stops a test from mocking the wrong layer
— over-mock and it hollows out, under-mock and it quietly becomes an integration
test.

Do not exhaustively re-test generic infrastructure per feature. A
standard network request's failure-shows-a-message behavior is
generalized once, not re-asserted for every request.

Do write a per-scenario test when a request has a **unique
product-facing consequence that cannot be generalized**. The canonical
shape: an optimistic update plus undo-on-failure (tap a heart → fill it
immediately → unfill it if the request fails). That is a distinct
product consequence for that specific scenario, so it needs its own
test. Real example in this repo: archiving a thread's consequence is
*navigation* — return to the inbox when it was the last thread, show the
next thread otherwise (see
`tests/features/archiving-a-thread-in-a-particular-inbox.test.tsx`, two
named contexts each asserting the resulting pathname). The ~12
`hooks/` and `functions/` tests are these seams; the ~40 `features/`
tests are the outside-in core.

## The transitive/implementation-coupled exception (rare)

Occasionally a more unit-ish, implementation-detail-coupled test earns
its place (a = b and b = c, therefore a = c). This is rare. Default to
outside-in. When we take this exception, log why in
[notes.md](notes.md) so the boundary stays empirical.

## Lint is red

A lint failure counts as a failing test — a step is not green while lint
problems stand (warnings included), and you resolve them before moving
on, exactly as a red assertion. React/Expo-flavored, but it earns its
place. The sharpest example is `react-hooks/exhaustive-deps`: it forces
a hook's dependency array to be honest, and an honest dep array often
drives the rest of the implementation. Adding `[onLaunch]` instead of
`[]` to satisfy the linter re-fires the callback whenever its identity
changes — so a "fires once even when the prop changes" test then drives
out the ref guard. Lint and tests together pin the design.

## Advance one failure message at a time — and a compiler error is a failure

Rule 2 in the small: the loop is not "write the test, then write the
feature." It is **write the test → run it → read the *actual* message it
prints → make the single smallest change that moves *that* message
forward → run again → repeat** until it goes green. You do not skip to
the finished implementation because you can see where it's going. Reading
the real message each iteration is the discipline; predicting it is the
trap. This is slow on purpose, and the slowness is the point — it is what
produces a codebase where every line is there because a message demanded
it, with no cruft.

A **compiler error counts as a failing message** — the same as a red
assertion. So the sequence is genuinely granular:

- Test fails "expected `foo` to have been called" → so *call* `foo`.
- Compiler: "`foo/3` undefined / wrong arity" → so define `foo/3`, or
  pass it three *placeholder* args (`1, 1, 1` / `"", "", ""`) — whatever
  makes *this* message go away and nothing more.
- Run again; take the next message; repeat.

Placeholder args feel silly, and that is fine — a later assertion will
demand the real value and you'll replace them then, driven by *that*
message. Filling them in "correctly" up front is guessing ahead of the
red, which is how cruft and untested branches sneak in.

**If you get stuck — cannot find the next minimal step, or two messages
seem to demand contradictory things — stop and ask.** Do not paper over
it by jumping to the full solution. The whole value of the suite is that
every line traces back to a message that required it; one intuited leap
breaks that chain silently.

The failure mode to catch in yourself: describing step 2 as "write the
code" and step 3 as "test-drive it." That ordering *is* test-last with a
TDD label on it. Test-driven means test first — the message exists before
the line that answers it.

## Working method with Claude as the pair

- Claude proposes the next failing test in product terms and gets Nick's
  assent on the product decision it encodes, then writes only enough
  code to make it green.
- Claude keeps this skill current: when we discover a pattern, a seam, a
  naming call, or a subtle defect the discipline caught, append a dated
  case study to [notes.md](notes.md), and edit this file when doctrine
  itself changes.

## Pointers

- Running notes and worked examples: [notes.md](notes.md)
- Testing library (ERTL/RNTL) finders, matchers, and gotchas:
  [references/testing-library.md](references/testing-library.md)
- Coverage config and the exact blacklist: `emma/jest.config.ts`
- The helper vocabulary:
  `emma/tests/helpers/{actions,expectations,app,mocks,factories}`
