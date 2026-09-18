# BDD working notes

The running log of concrete lessons, worked examples, and boundary
calls, for the emma / emma_api BDD discipline. Newest first. Each entry:
what happened, what it taught, how to apply it next time. Keep it
current — this is the empirical record behind the doctrine in
[SKILL.md](SKILL.md).

---

## 2026-07-17 — Transitive assertions, ambiguous red, and the seam

**Context.** Testing OTA updates surfaced a chain of three tests: (1)
the app calls `useOverTheAirUpdates` on launch, (2) that calls
`simpleExpoUpdate({ whenPresent: askPermissionToApplyUpdate })`, (3)
`askPermissionToApplyUpdate` shows the prompt and applies on "Yes".
None is a black-box statement about the product; together they
*transitively* assert it works.

**What it taught.** A test only passes or fails, so what each verdict
*means* is the whole game. Black-box: green = "works", red = "broken" —
clean both ways. An implementation-coupled test (a transitive
assertion — what most people just call a unit test) carries *more* in
green: "works **and** works this way." The cost lands on red, which now
means "broken, **or** just works differently now (and may be fine)."
The green is richer; the **red is the ambiguous one** — and since the
point of a 100%-covered suite is fearless refactoring, ambiguous red is
the exact tax you're trying not to pay. Want red to mean "a requirement
broke," full stop. (A green chain still *proves* the product works —
grey-box, not worthless. Grey reds just cost you on every restructure.)

**How to apply.** The seam is not the unit test — it's the *boundary the
test asserts at*, where the contract lives. Split into transitive tests
at a seam when the end-to-end space is a *product* of independent
dimensions (triggers × conditions × outcomes) too big to enumerate
black-box, and the seam is a *stable contract*: then "reaches the seam
with the right info" (once per upstream path) plus "given that info, the
right outcome" (once per downstream case) turns N×M into N+M. The tell
you drew the seam in the wrong place: product-meaningful behavior lives
on the *far* side of it — then the seam splits a requirement, not
mechanism, and red goes ambiguous for a real reason. That was the OTA
case: `whenPresent: askPermissionToApplyUpdate` is a callback the
package invokes, so the prompt UX sat across the boundary. A
data-returning edge — `const update = await checkForExpoUpdate(); if
(update.isAvailable) askPermissionToApplyUpdate(update.apply)` — keeps
all product behavior on your side (black-box) and leaves the package a
clean seam you assume works. Optimizing an API to read like an English
sentence is what pulled the edge through the product behavior.

---

## 2026-07-15 — A proxy assertion is a red that can pass for the wrong reason

Removing a phone number left the parent's `phoneNumber` state holding
the old value, so the input came back pre-filled. The test asserted with
`queryByText`, which never sees a `TextInput`'s `value` — so it passed
whether or not the value was cleared: "100% covered," green, and blind
to the bug.

The lesson: assert the observable that actually *changes*. Here that's
the field's value —
`expect(screen.getByTestId("Phone Number Field").props.value).toEqual("")`
— not visible text that can't observe it. Written first, that red fails
on the exact stale value and drives the `setPhoneNumber("")` fix. A red
that names the true symptom can't pass for the wrong reason.

---

## 2026-07-15 — A test-env bypass is a missing test in disguise

**Context.** `PhoneNumberInput` computed the Save button's disabled
state by reading a ref during render
(`phoneInputRef.current?.isValidNumber(phoneNumber)`), wrapped in
`env.current() !== "test"` and `/* istanbul ignore next */`. So the real
validation was skipped under test and hidden from coverage. It masked a
genuine bug: changing the country didn't re-validate (a ref read during
render doesn't re-run when the library's internal state changes), and
the remove-then-re-add path could submit a doubled-prefix number.

**What it taught.** Bypassing a check under test and istanbul-ignoring it
is whitelist-thinking — it hides an untested product requirement behind
a green suite. The React Compiler lint rule (`react-hooks/refs`) flagged
the ref-during-render as the smell even though the compiler isn't
enabled; the rule was pointing at a real defect.

**How to apply.** When you see a test-env bypass, treat it as a missing
test, not a quirk. Prefer deriving UI from tracked state (props/state)
via pure functions — here, the library's pure
`isValidNumber(number, countryCode)` — so the behavior runs identically
in tests and production and the coverage hole closes instead of being
papered over. Never read a ref during render to produce rendered output.

---

## 2026-07-25 — Don't write a test to drive a removal

**Context.** Outlook token refresh was sending a `client_secret` to
Microsoft; real Microsoft returns `AADSTS90023: Public clients can't send
a client secret` (the app is a public / PKCE client — sign-in already
uses `code_verifier` and no secret). A Bypass helper
(`refresh_access_token` in `test/support/outlook_api_requests.ex`)
*asserted* the secret was sent, so the suite was green while production
was broken — the test enforced the bug.

**The slip.** Claude proposed: "flip the helper's assertion to
`refute decoded_body["client_secret"]`, watch it go red, then delete the
`client_secret` line to make it green." That is a test written to drive a
*removal* — the anti-pattern.

**The correction (Nick).** Tests drive the *addition* of code, never its
removal. You never assert absence to justify deleting something. The
documentation benefit only works one direction: delete a line, see which
test reddens = the English requirement it serves. To remove code, make it
defended by no test, then delete it and confirm the suite **stays green** —
that green is the proof the line served no requirement.

**How to apply here.** The `client_secret` line was propped up only by a
helper assertion that codified a *wrong guess* about Microsoft's contract
(never a real product requirement). So: (1) delete that assertion, (2)
delete the `client_secret` line, (3) run — stays green. Then
`OUTLOOK_CLIENT_SECRET` is referenced nowhere and leaves the code and the
Azure registration entirely. Doctrine added to SKILL.md under
"Tests drive the addition of code, never its removal."

---

## 2026-07-25 — A behavior-preserving refactor across transitive seams is driven by changing existing tests

**Context.** Emma's "next page" cursor had a half-normalized contract:
the client sent Google's request-param name `pageToken` (leaky — the app
is meant to be provider-neutral), while the response field was already
Emma's snake_case `next_page_token`. We normalized the request to
`page_token` too and moved the Google translation into the Gmail adapter.
At the product level this changes nothing — same screens, same behavior.
But the app has intentional transitive test seams, and a
behavior-preserving rename still breaks the tests that pin them. (Per the
blog: seam/unit tests are a concession; their known cost is breaking on a
refactor.)

**What it taught.** When a refactor crosses transitive seams you do NOT
"refactor under green." There is real red -> green work: you change the
*existing* seam tests to the new contract (you rarely add new ones). The
red is honest — it is the seam contract being restated — even though the
product is unchanged. Do it one seam at a time.

Which seams broke, and the tell for each:
- **FE<->BE** (the FE test asserts what it *sends*): the request params
  moved `pageToken` -> `page_token`. Red, then green when the client
  production line changed to match.
- **web<->business** (controller test): the controller forwards query
  params opaquely, so it is *name-agnostic* — changing the param name is a
  consistency edit, it never goes red. Not every seam breaks; only the
  ones that actually name the thing.
- **business<->provider-API** (Gmail): see the trick.
- **Outlook token-parser unit**: the reader's incoming param name changed.

**The trick worth remembering.** The Gmail command's test already pinned
*both* ends of a translation independently — what comes in, and what goes
out to Google:

```elixir
# incoming to the command:
Gmail.GetThreads.get(account, %{"pageToken" => "TOKEN"})
# outgoing to Google (asserted inside the Bypass helper):
assert google_request_params["pageToken"] == "TOKEN"
```

They matched because Gmail was a pass-through. Changing *only the
incoming* to `page_token` turned the existing test red — Google now
received `page_token` but the helper still demanded `pageToken` — and
that red *drove* the new adapter translation (`page_token -> pageToken`,
added beside the existing `resolve_label_ids` Emma->Google mapping). No
new test: an existing seam test, with one input changed, demanded the new
code. When a test pins both sides of a translation, changing one side is
how you drive the translator into existence.

**On unit-testing the token parser.** Outlook's token *reader*
(`ParseParams`) and *creator* (`BuildNextPageToken`) are unit-tested
directly, unlike Gmail's (whose token is opaque — nothing to parse). That
is a legitimate concession: the Outlook token is intricate JSON
(`{next_link, seen_conversation_ids}`) with real encode/decode logic worth
pinning at the seam. We kept the convention; only the *reader's* incoming
param name changed. The creator was untouched because the response name
(`next_page_token`) did not change — so know which of the pair your
change actually touches before assuming both move.

**How to apply.** Before a "pure refactor," ask which transitive seams it
crosses. If any, plan red -> green on the *existing* seam tests, one seam
at a time — never refactor-under-green. Snippets in skill notes are
inlined (not `file:line`) on purpose: the repo will not always be here,
so the lesson has to stand on its own.

## 2026-07-25 — Coverage is not drivenness; a line is driven or it's cruft

`loadFirstPageOfThreads` skips accounts whose inbox is already loaded
(`status !== "Not Started" -> return "Single Account Update Skipped"`).
The skip sat at 100% coverage, so it *looked* required. It was not.

Deleting the line and running the whole suite: **278 green.** Making it
`throw` instead named the one test that even *reaches* it —
`email_accounts.test.tsx "adds accounts"`, and only *incidentally*. That
test signs in as one account (its inbox loads -> Success), adds a second
(Not Started), returns to the inbox; the focus loader fires because the
new account is Not Started, fans out over both accounts, and the
already-loaded one trips the skip. But the test only asserts the *new*
account's thread appears — nothing asserts the loaded account isn't
re-fetched. So the line *ran* under test while no assertion *required*
it.

Why removal stayed green — the scaffold hid it. `signin()` leaves a
**persistent** msw mock for the signed-in account's inbox (mocks here are
not `.once()` by default). With the skip gone, the already-loaded account
was re-fetched and that redundant request silently reused the still-live
mock: no unhandled request, no failure. (Flipping `.once()` on by default
reds 114/278 — genuine same-endpoint-twice patterns plus a
shared-path/different-query consumption bug — so it's tech-debt, not a
now-fix. Logged in emma `TECH_DEBT.md`.)

**The distinction.** *Covered* = executed. *Driven* = remove it and a
test reds, and that red is the English name of the requirement. Coverage
can't tell them apart; only delete-and-watch can. A line that runs but
reds nothing on removal is **cruft**, even at 100%. Don't call the line
"defended" — that makes the line primary and the test its guard; it's the
reverse.

**How to apply.** When a line looks untested-but-covered — often after a
"refactor" that quietly grew a behavior no test asked for — classify it:
delete it (or make it `throw`) and run. Green -> cruft; either delete it
or make it *driven* by a test that reds on its removal (for the skip:
"the already-loaded account's inbox request is not made" — assert the
duplicate request never happens, via a fresh mock registered after the
initial load so it can only be hit by the duplicate). Red -> already
driven; put it back. Distrust a green-on-removal whenever a persistent
mock could be absorbing the very request the line prevents.

## 2026-07-30 — assert the values, not a wildcard (`[_]` drove nothing)

Building the outlook reactor's push dispatch, the first cut asserted
`SendInboxEmailPushNotifications` was called with `[%{id:
"conversation_1"}]` — the thread's `messages` left unpinned (effectively
`_`). Nick's catch: "I can adjust the call that satisfies that test to
pass `''` as the argument and the test passes." Exactly right: the reactor
could hand the command a thread with no messages — or a hardcoded stub —
and stay green. The serialization (fetch the Graph message, run
`MessageSerializer`, wrap it in the thread) — the whole real job — was
covered (it ran) but driven by nothing.

Fix: pin the values that exist only if the reactor did the work —
`[%{id: "conversation_1", messages: [%{from: %{name: "Sender"}, subject:
"Subject", preview_text: "Preview"}]}]`. Those fields come from
serializing the fetched message; tear `messages: [serialize(...)]` out of
the reactor and the assertion reds. Now the dispatch test drives the
serialize.

Rule (promoted to SKILL.md): never assert a call with a wildcard arg. `_`
marks the argument you claim not to care about, and that's where the
behavior lives. Pin what the behavior alone yields; partial-map matching
to skip incidental fields is fine, a whole-arg `_` never is.

## 2026-08-02 — Start at the outermost test; it's your feasibility probe

**Context.** Building Outlook read-receipt tracking, Claude started at the
*model* — gave `ReadReceiptPixel` the exactly-one-account treatment, wrote
its test, generated a migration, ran it green — and only *then*, reaching
toward the integration, discovered the feature couldn't be built as
imagined: Graph's `sendMail` returns no message id, the draft id changes
when the message moves Drafts -> Sent Items, and `internetMessageId` is
client-dependent. Half the model work was done before the wall appeared.
(It turned out buildable via the `Prefer: IdType="ImmutableId"` header —
but that's luck, not method. It could as easily have been a dead end.)

**Nick's catch.** "If you had started outside-in you would have realized
you couldn't even set up a test for that and wouldn't have done half the
implementation work before realizing it couldn't be done."

**What it taught.** The outermost test isn't just where the story lives —
it's a **feasibility probe you run before building anything**. Its Arrange
step forces you to name every observable the feature needs; if you can't
even *set up* the scenario (here: "the read receipt shows on the sent
Outlook message in the thread" — which demands a stable id to correlate
on, the exact thing that doesn't exist by default), you've found the
blocker for the price of a test stub, not a model + migration + test.
Starting at an inner layer (a model, a schema) skips that probe: inner
layers compose and pass in isolation precisely because they don't know
whether anything above them can use them. Green at the model tells you
nothing about whether the feature is buildable.

**How to apply.** Always write the outermost, user-facing failing test
*first* — even when the change looks like "just a model tweak." If the
model is really needed, the outer test's red will reach down and demand
it; you'll build the same model, but now driven and proven reachable. If
the outer test *can't be set up*, stop — you've found a blocker, and you
found it before touching the schema. Only skip outside-in for a genuine
reason (a pure refactor under green; a transitive-seam contract restated
one seam at a time), and name the reason. Promoted to SKILL.md under
"Outside-in is also your feasibility probe — start there."

---

## 2026-08-04 — Duplicate-inbox stacking: reproduce via nav-state, assert via `canGoBack` (transitive exception)

**Symptom (from the user).** Swiping the inbox right (iOS back gesture)
revealed another identical inbox beneath it — piling up 5-10 deep and
slowing the app. A real production nav bug with no obvious cause.

**Diagnosis by experiment, not by reading.** Every navigation to
`/inbox` in the codebase used `router.replace` (never `push`), so on
paper nothing could stack. Rather than keep theorizing about
expo-router's `replace`/`navigate` semantics, I wrote a *throwaway*
`zzz-*.test.tsx` that drove the real router (`renderRouter` via the
`signin` helper) and dumped the live navigation tree from
`store.state` (imported from `expo-router/build/global-state/router-store`)
after each action. Tapping the notification handler repeatedly showed the
nested inbox stack growing one `index` per tap:
`[index] → [index,*thread] → [index,index,*thread] → …`. That *is* the
bug, reproduced deterministically in jest. Lesson: when a nav bug defies
static reading, dump `store.state` in a scratch test and drive the
suspected trigger — the tree tells you immediately.

**Root cause.** `useInboxEmailNotifications`' tap handler did
`router.replace('/inbox'); router.push(thread)`. When you're *already*
inside the inbox stack, `replace('/inbox')` doesn't return to the
existing base index — it swaps the focused screen for a fresh index, then
push re-adds the thread. `navigate('/inbox')` was worse (pushed index +
thread pairs). `router.dismissTo('/inbox')` (expo-router v57) is the right
primitive: pop back to the existing inbox base, then push the thread.
Stack stays `[index, thread]` no matter how many taps. The other
`replace('/inbox')` sites (index redirect, sign-in buttons) are fine —
they replace a *non*-inbox route, so there's nothing to duplicate.

**The regression test is a transitive/implementation-coupled exception.**
The user-observable symptom (swipe reveals a duplicate inbox) can't be
told apart from the fixed state by visible text — both show the inbox
list. The distinguishing signal is "is there another screen beneath the
inbox to go back to," i.e. `router.canGoBack()` from the inbox list:
`false` when fixed, `true` when stacked. So the test taps three
notifications, presses back once, asserts `/inbox` and
`router.canGoBack() === false`. `canGoBack` is a public expo-router API
and maps directly to the user's swipe-back, but it's still a
nav-structure assertion rather than a pure observable — logged here per
the transitive-exception rule. Verified red with `replace`, green with
`dismissTo`.

## 2026-08-21 — Diagnose unwanted UI by deleting it; the red names what actually drove it

The inbox-zero screen bounced on every app foreground: `EmptyList` drove
its `RefreshControl` from the shared `someAccountsRefreshing` store flag,
so a foreground-triggered refresh programmatically inserted the pull
spinner and shoved the art down and back up. Nick's call: don't reason
about which test covers the jank — *delete the suspect loading state and
run the suite*.

The red was informative precisely because it wasn't the predicted one.
No foreground-spinner test existed; the only test that reddened was
"pulling down to refresh the inbox zero screen," which asserts the
spinner during a *user pull*. So the foreground spinner was never a
driven behavior — it was cruft riding along because the component reused
the shared flag for the pull spinner instead of local pull state. The
red licensed the re-implementation: mirror the sibling `ThreadList`'s
local `isRefreshing` pull state, and the jank's cause is gone with zero
tombstone tests.

The replacement behavior (foregrounding covers the inbox with a
full-screen fading cover until refreshed threads arrive, so stale mail
can't be mis-tapped) was driven outside-in in
`foregrounding-the-application.test.tsx` with `waitToRespond` +
`.respond()` to hold the refresh in flight. Implementation notes: the
in-flight state lives in `useRefreshInboxWhenAppForegrounds` (set at the
focus event, cleared after `await Email.refreshThreads` — which resolves
on success, error, *and* skip, so no branch); the cover overlays
`ThreadListContent` rather than replacing it, so the FlatList keeps its
scroll position.

**A second scenario that arrives green gets deleted, not kept.** The
inbox-zero variant of the cover test passed the moment it was written —
the cover renders above the branch switch, so one mechanism serves every
branch and the first test had already driven all of it. Nick's ruling:
delete it — a test that never had a red drove nothing and isn't TDD.
One story, one mechanism, one test; "it would catch a hypothetical
future regression" doesn't earn an unverified detector a place in the
suite.

**Vocabulary lesson from the same session:** the foregrounding tests all
hand-rolled their arrange (manual `mockSignInWithGoogle` + thread mocks +
`launchTheApp(() => renderRouter(...))`) only because `signin` owned
`renderRouter` with no lifecycle seam. `launchTheApp` just needs its
AppState spy installed before render and ignores the callback's return —
so `signin` now wraps its own render in `launchTheApp` and returns the
`{ backgroundTheApp, foregroundTheApp }` handles (all prior callers
ignore the return value; pure refactor under green). Tests needing
lifecycle control use `signin` like everyone else and keep only their
story-specific mocks manual. When a feature file's arrange is
boilerplate-heavy compared to its siblings, suspect a missing seam in
the helper vocabulary before accepting the boilerplate.

## 2026-08-22 — "Refactor under green" pins the refactored behavior, not a zero-red suite

Nick's correction after I claimed a pending red had to be resolved
before an extraction: wrong. "Under green" means the behavior being
restructured is pinned by green tests — it does not mean the suite has
zero reds. A red that specs an *unimplemented* feature is fine sitting
red through a refactor; deleting it first would be silly. The check
that the refactor changed nothing: every green stays green, and the
pending red still fails *for the same reason* it failed before the
move. (Worked case: extracting RecipientSuggestionsBar out of
BarAboveComposeKeyboard while the empty-recents red sat unimplemented —
4 greens held, the red's failure message was unchanged.)

## 2026-08-31 — Log wording is infrastructure; log *noise* is still red

Two rulings from moving the provider-outage log line into the retry
helper (`RetryWithExponentialBackoff` gained `request_name:` and became
the single reporter of a request that gave up):

- **Don't test the helper's log wording.** The helper is coverage-
  blacklisted infrastructure, and what a give-up line *says* is not a
  behavior a user observes. Nick: "we haven't been testing that — this
  isn't a product change." The two helper tests I'd written came out,
  and so did a product test's assertion on the helper's wording — pinning
  infrastructure by proxy through a product test is the same thing in
  disguise. Tests that *already* assert a log line (receipt job, failed
  Oban jobs, the account plug) stay: assume they crossed the line for a
  reason, and update them when wording changes.
- **A test that drives a give-up path wraps its act in `capture_log`.**
  Five attempt-count tests (Bypass answering 503) were printing the
  helper's warning and error lines into the suite output. Cruft in test
  output is not acceptable, regardless of whether the log is asserted —
  `import ExUnit.CaptureLog` + `capture_log(fn -> ... end)` around the
  act, as `failed_oban_jobs_test` does.

## 2026-08-31 — Sentry `before_send_log`: drive the config wiring, not the async pipeline

Dropping the shutdown-time `Writer crashed (epipe)` log line from Sentry
Logs reused the existing `drop_log_pipe_closing_while_shutting_down`
callback, wired a second time as `before_send_log`. The event-side
sibling test drives its config line by calling `Sentry.capture_message`
under `Sentry.Test` (synchronous). The log side can't be driven the same
way: `enable_logs` is prod-only, and log events flow through the SDK's
async `TelemetryProcessor`, so a real `Logger.error` in test neither
reaches the callback nor can be awaited cleanly.

Transitive exception taken: the test reads the configured callback back
out of the SDK — `{module, function} = Sentry.Config.before_send_log()`
— and applies it to a `%Sentry.LogEvent{}` built from the real line.
That still reds on the missing config line (MatchError on `nil`) and
then on the missing `LogEvent` clause, so both the wiring and the
behavior are driven; only the SDK's own dispatch is trusted. Don't
enable Sentry Logs suite-wide just to integration-test one filter.

## 2026-09-05 — Suppress an offline give-up: drive the decision at the hook seam, trust the vendored retry

**Context.** Sentry EMMA-S4: on a genuinely offline device
`getExpoPushTokenAsync` threw `ERR_NOTIFICATIONS_NETWORK_ERROR` ("…fetch
failed: …The Internet connection appears to be offline"). The push-
registration hook wraps the work in `retryWithExponentialBackoff` (in
`src/untested/localDependencies/`, coverage-blacklisted), which reported
*every* exhausted give-up to `Sentry.captureException`. So an
unactionable, self-healing offline blip became a daily alert. Nick:
"I'd love to never get useless errors daily — prevent it."

**The design call — policy in tested code, not the blacklisted helper.**
The report lived *inside* the vendored retry. Adding an "is this offline?"
branch there and leaving it coverage-excluded is whitelist-thinking (see
2026-07-15, the test-env bypass). So: the retry now just re-throws on
give-up (pure generic retry, no Sentry coupling), and the hook wires
`.catch(reportPushRegistrationFailure)` — a *tested* function that skips
Sentry when `isOffline(error)`. `isOffline` was extracted verbatim from
`safeFetch` (it already matched "fetch failed") so there's one definition
of offline, not two — safeFetch stayed green through the extraction
(refactor under green), and its `a || b || c` short-circuit branches were
already 100% without needing "Failed to fetch"/"fetch failed" as *true*.

**The seam call.** The honest end-to-end test — offline error reaches the
real retry's give-up → no report — needs six recursive backoff `await`s
pumped through legacy fake timers, and this repo's timer tests only ever
advance a single `setInterval` (`automatic-thread-refreshing`), never a
recursive-await-between-timers chain. So I drove the product behavior at
the **hook seam**: `jest.mock` the retry, `mockRejectedValue(error)` (its
reject-on-give-up contract), `renderHook`, flush with
`await act(async () => await new Promise(setImmediate))`, assert
`captureException` was / wasn't called. Two reds: real error → reported;
offline error → silent. This exercises the real
`reportPushRegistrationFailure` + `isOffline` and mocks only the vendored
retry.

**What stays trusted.** The helper's actual `throw error` on give-up is
*not* driven by a test — the hook tests mock it per its contract, and it's
blacklisted infra. This mirrors emma_api 2026-08-31: the retry helper's
give-up *reporting* is infrastructure; the product change is the
*decision about which give-ups are worth reporting*. Risk accepted: if the
real helper stopped rejecting, no test would red. Kept the change to the
helper trivial and obvious to bound that risk.

**How to apply.** When a production error is "the retry gave up," the
product decision is "which give-ups deserve a report," and it belongs in
tested code. Mock the retry per its contract to drive that decision
without timer gymnastics; don't put the branch in the blacklisted helper,
and don't stand up fake-timer machinery the repo has no pattern for just
to integration-test trusted infra.

## 2026-09-07 — Webview email height: untested-by-design, verified on device

**The bug.** One email (DHH's "But Y" from hey.com) was cut off mid-image
on iOS; desktop was fine. Cause: the injected email JS measured height
once (`window load` OR a 1s `setTimeout`, whichever won, latched behind a
flag) and the RN `onMessage` accepted only the first report
(`if (isLoading && scrollHeight)`). A remote, dimensionless `<img>` that
finished after the 1s timer got measured at ~0 height → locked short →
clipped. Desktop won the `load` race, so it never showed.

**The fix.** Subscribe to the real signal, not the timer: a
`ResizeObserver` on `document.body` re-reports height whenever content
grows (image load, font, reflow); RN applies the latest height on every
report and gates the one-time reveal/splash/scroll behind the first. The
1s timer stays only to guarantee the *transforms* run.

**The boundary (why no test).** This whole path is untested-by-design and
that's correct here. The injected JS is a *string* — authored in
`devtools/.../javascript-with-syntax-highlighting-for-easier-editing.js`,
translated to `src/utils/javascriptInjectedIntoEmails.ts` by
`copy-javascript.rb` — and can't execute in jsdom (no WebView, no image
load, no ResizeObserver). `onMessage` is already `/* istanbul ignore next
*/` ("hard to test, we can't find a way"). So neither side moves the 100%
gate, and verification is on-device, not in-suite.

**How to apply.** When behavior lives entirely inside the webview
(height, layout, image loading), don't manufacture jsdom machinery to
fake it — that tests the fake, not the product. Edit the JS source, run
the copy script, keep the RN seam in the blacklisted handler, and verify
on device. And the general lesson from expo-conventions holds even in
DOM-land: a `setTimeout` standing in for "content is ready" is a race —
reach for the event (`ResizeObserver`, `load`) instead.

## 2026-09-08 — Assert value outcomes, not that an input prompt appeared

**The insight (Nick).** An alert/confirm/permission dialog is an *input* —
how we ask the person to confirm, grant, or cancel. Walking the flow
*through* those prompts is necessary plumbing, but "a question was shown"
is not a value outcome, so it must not be a test's assertion. The
outcomes that carry value are: a request goes out or it doesn't; the app
transitions to another screen or it doesn't (inbox / set-aside / next
thread); the deleted thread leaves the list or is restored to it. A test
whose only tail is `alerts.haveBeenShown()` is asserting the plumbing and
should not exist.

**The case.** Delete-forever's reauth flow. The "person cancels the
Google sign-in" test walked through the Delete-Forever and Permission
prompts and then asserted only that they'd been shown — the plumbing.

This arc flip-flopped several times before landing; the final synthesis,
not the intermediate turns, is what to keep.

**A button press is an input; assert the value it produces, not the
prompt.** `expectAlerts` presses "Delete Forever" / "Continue" because
that's how the flow advances — load-bearing input. But a test never
tails on "the prompts fired." Assert what the flow produces: a request
made, a navigation, a thread hidden or restored. When a prompt's
*message* is feedback the branch exists to deliver (which account to
sign in with), assert that message — it's value, and it lives in the
`expectAlerts` spec. Titles stay (a prompt should assert its title
somewhere), but a walk-through press in a test that isn't about that
prompt is press-only.

**The whole async cascade settles inside `await pressTestId`.** So a
"wait until the alerts fired" helper is never needed. Proof: with the
wrong-account message deliberately wrong and *no* waiter, the test reds
on the message `toEqual` — the alert fired and was asserted during the
action's flush. So `haveBeenShown()` (a waiter I'd added) came back out
entirely; the helper is a pure presser/asserter again. A waiter whose
only job is "the prompts fired" must never be a test's last line.

**Coverage is not drivenness — the cancel test was the trap.** The
GoogleSignin-cancel branch was *covered* (expectAlerts pressed Continue
→ mocked `cancelled` → the `if (response.type === "success")` false side
ran → 100%), but its surviving-thread assertion rested entirely on the
403 restore. Confirmed by deleting the reauth from the test — Continue
never pressed, `signIn` never called — and it *stayed green*. Whatever
the mocked dep returns, there's a back button and the thread is
restored, so the assertion can't see the branch. Its only value (email
survives) is the 403 restore's, already owned by the delete-fails test.
So the cancel test drove nothing → **deleted**, and the guard is
`// istanbul ignore else`: it's a type-narrowing guard (needed to read
`response.data`) whose cancelled side has no observable. (My earlier
"the value test drives it" was wrong — the value test was vacuous.)

**Don't confuse a mocked dep with a native Alert.** GoogleSignin is
mocked whole (`mockResolvedValue`); its real popup never renders, so
"does the popup block the back button" is a non-question I wasted turns
on. The confirm/permission dialogs are RN `Alert` — also stubbed in
tests (a function call, not a blocking modal), so they never gate the
back button either.

**Mocks in story order, right before the action** — set each up just
before the press that triggers it, in the order the story hits them,
never parked above `signin()`. One tool-forced exception: MSW's
`server.use()` is LIFO, so for two responses to the *same* endpoint (a
`respondOnce` 403 then a persistent retry), the one that must fire first
is registered *last*. Group the pair and accept the inversion — it's a
library constraint, not a story choice.

## 2026-09-09 — Sentry `traces_sampler`: same config-wiring seam, but wire it as a capture

Cutting emma_api's span volume (4M of a 5M monthly quota in 15 days, ~95%
of it Oban's Stager/Pruner/Lifeline plugin spans and the queue-polling
queries they issue) followed the 2026-08-31 `before_send_log` pattern: the
test reads `Sentry.Config.traces_sampler()` back out of the SDK and applies
it to a hand-built `%SamplingContext{}`. Four tests, each one red→green:
a job trace is sent (`true`), Stager is dropped, Pruner/Lifeline are
dropped (drove the `"Elixir.Oban." <> _` generalization), a root-level
`emma_api.repo.query*` span is dropped. (Later the same day the function
was renamed `worth_sending?` once it also dropped the `/status` uptime
probe by `url.path` and had to `to_string/1` Bandit's atom span names.)

Postscript, same day: the `/status` test asserted a string `"url.path"`
key, went green, deployed, and the probe kept arriving — OTel semconv
keys are atoms (`:"url.path"`). A hand-built fixture is only as honest
as the shape you copied it from: when a test stands in for a library's
callback, read the library's source for the exact keys and types rather
than writing what looks plausible, and verify in prod after the deploy.

Two things the loop caught that a write-it-all-at-once pass would not:

- **Wire the callback as `&Mod.fun/1`, not `{Mod, :fun}`.** Sentry 13.5's
  `__validate_traces_sampler__` calls `function_exported?/3` without
  `Code.ensure_loaded/1`, so the tuple form passed on the run right after
  a compile (module already loaded) and failed on the next run (`function
  ... is not exported`). A release loads every module at boot, so prod
  would have been fine — but the suite would have been flaky forever. A
  capture validates as `is_function(fun, 1)` and loads lazily on first
  call. The `should_report_error_callback` line in the same config block
  already did this.
- **Don't reach for the sampler's `drop:` name list.** It returns
  `{:drop, [], []}` with an empty tracestate, so a dropped parent's
  children see no sampling decision and get sampled as their own root
  transactions — the noise moves, it doesn't go away. `traces_sampler`
  returning `false` propagates `sentry-sampled=false` to children.

## 2026-09-14 — Gmail search order: the outer test named the endpoint, the drafts test moved seams

Story: "searching lists threads newest message first, like Gmail's
website." Gmail's `threads.list?q=` returns threads ordered by each
conversation's *first* message; `threads.list?labelIds=` by the newest.
Measured straight from Gmail (39/39 pairs each way) before writing a test,
so the product decision was made on data: label views keep the thread
listing, searches list messages (newest first, ids only, 500 per call)
and collapse them to thread ids, Outlook-conversation style.

- **The outermost test lived in `Gmail.GetThreads`**, not the controller —
  the controller passes params through and its shape didn't change. Seams:
  Bypass for Gmail's HTTP (a new `get_messages` request helper next to
  `get_threads`), serializer mocked, everything else exercised.
- **An existing test changed seams, not meaning.** "omits threads whose
  only messages are drafts" was arranged through a search, so when search
  moved to the message listing it went red for the wrong reason. Its
  arrangement moved to `get_messages`; its title and assertion stayed. That
  is the 2026-07-25 rule in practice: a behavior-preserving refactor across
  a transitive seam is driven by changing existing tests.
- **Sequential-request expectations pin round trips.** `expect_sequential_
  requests` fails on any extra or reordered request, so "resumes on the
  page of messages it left off on" and "goes straight to Gmail's next page"
  are performance requirements pinned as tests, not comments.
- **A two-tuple `with` match swallowed a failure.** `{:ok, thread_ids} <-
  accrue(...)` also matched `{:ok, %HTTPoison.Response{status: 500}}`. It
  surfaced as a Protocol error inside the next red; returning a wider tuple
  fixed it and was needed for the next step anyway. Watch for `{:ok, _}`
  patterns that can match a collaborator's error shape.
- **Refactor under green removed cruft it had produced:** an `Enum.uniq`
  added mid-loop was undriven once the search path de-duplicated; deleting
  it kept green, so it went. Then the search listing was extracted into
  `Gmail.GetSearchedThreadIds` beside its Outlook sibling, with no new test
  and no `TestSeam`, since no layer mocks it.

## 2026-09-18 — Monitoring configuration is an explicit exception

Nick clarified the scope while adding database and memory diagnostics:
Emma and emma_api use BDD for product features. Performance-monitoring
configuration does not require test-first development or dedicated tests;
compilation, manual inspection, and checking the resulting telemetry are
appropriate verification. Do not build a test harness merely to configure
operator diagnostics. This exception does not extend to product behavior
or performance requirements that users experience.

Morning Telegraph is Nick's personal operations app, not a BDD codebase.
Do not add tests there. Verify changes pragmatically by compiling and
checking the integration. Existing monitoring tests do not establish a
requirement to add more.
