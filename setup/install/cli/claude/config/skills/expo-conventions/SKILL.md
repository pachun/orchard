---
name: expo-conventions
description: React, React Native, and Expo coding conventions — a functional, immutable house style. Function components only, const-only and never mutate, and types that make impossible states impossible. Comments are disallowed except to flag a genuinely non-obvious decision (e.g. a link to a GitHub issue); names carry the meaning instead. Apply whenever writing, refactoring, or reviewing React / React Native / Expo / TypeScript code — components, hooks, state, and type definitions.
---

# React / React Native / Expo conventions

Apply these whenever writing, refactoring, or reviewing React / React
Native / Expo / TypeScript code. This is a living list — it grows as
more conventions are added; treat it as the source of truth for how
code in these projects should read.

## Functional & immutable

- **Function components only.** Never class components.
- **`const` only** — never `let` or `var`. Reaching for `let` is a
  smell: derive the value (`map` / `reduce` / `filter` / a helper)
  instead of accumulating into a mutable binding.
- **Never mutate.** Not props, state, function arguments, arrays,
  objects, or module-level state. Build new values (spread, `map`, …)
  rather than changing existing ones in place.
- **Functional-first.** Pure functions, expressions over statements,
  composition. Derive state from what you already have; don't
  store-and-sync duplicate state.

## Lead with the affirmative case

When a conditional picks between a real result and a fallback, write
the positive, un-negated condition first and return the real result
from it — let the fallback be the trailing return:

```
if (fontsLoaded) {
  return <App />
}
return <Splash />
```

Not `if (!fontsLoaded) return <Splash />` ahead of the app. The reader
meets what the component *is* before its degraded state, and there's
no negation to mentally flip. Keep the flat guard-clause shape — early
returns, no nested `else` — just order it so what's true comes first.

## No timers as control flow

- **`setTimeout` is not a synchronization primitive.** Reaching for a
  timer to wait out a render, a focus change, a layout pass, or any
  other framework-driven update is a smell — you're guessing at a
  delay instead of subscribing to the event that actually fires. There
  is almost always a real signal: an `onLayout`, an `onFocus`, an
  effect keyed on the value you're waiting for, a promise, a native
  callback. Find it. A timer that "works" only does so until the
  device is under load and the delay you guessed runs short — then
  it's a race, and it flashes or drops the update. If you genuinely
  can't find the signal, prefer not building the behavior at all over
  shipping a timer. (Real wall-clock timing — a debounce window, an
  animation duration, a poll interval — is fine; sequencing your own
  code against the framework's lifecycle is not.)

## `useEffect` is usually the wrong tool

- **Make something happen when the thing that causes it happens — not
  by watching state change from a lifecycle.** This is the same lesson
  as timers, one notch less strict: `setTimeout` has never once been
  the right answer, and `useEffect` rarely is. An effect that reads
  state every render and reacts "when X became true" is observing a
  value settle instead of running at the moment that decided it. The
  cause already has a home — the handler, the event, the promise that
  changed X. Put the work there. When a modal closes, restore focus
  *in the dismiss handler*, right before you tear the modal down; an
  effect keyed on `modalOpen` runs a beat late, after the framework
  has already picked its own focus fallback, and you watch it flash to
  the wrong element first.
- Syncing one piece of state to another, poking the imperative world
  after a render, running a callback "when some state flips" — those
  are the tells. The fix is almost always to move the logic into the
  event that flipped it. Genuinely effect-shaped work exists —
  subscribing to an external store, an imperative subscription that
  needs teardown on unmount, reconciling with something outside React
  — and there you do reach for it. But it's the exception. Default to
  event-driven; make every `useEffect` earn its place.

## `async`/`await` over `.then`

Write asynchronous code with `async`/`await`, not `.then`/`.catch`
chains. It reads top to bottom, errors are a plain `try`/`catch`, and
each awaited value gets a real name instead of living inside a
callback. Reach for `.then` only where `await` genuinely can't go.

## Type design

- **Make impossible states impossible.** Model data so invalid
  combinations can't be represented. Prefer discriminated unions over
  loose collections of booleans and optionals; a field that only has
  meaning in one variant lives *inside* that variant. If a comment or
  a runtime check is guarding against a state, ask whether the type
  could rule it out instead.

## Comments & naming

- **No comments unless explicitly permitted.** Code should speak for
  itself. The one exception: a genuinely non-obvious decision the code
  itself can't express — for example a link to a GitHub issue
  explaining why a workaround exists. If you find yourself wanting to
  comment *what* the code does, rename or restructure until the code
  says it.
- **Names carry the weight comments don't.** Say it the way you'd say
  it out loud to a colleague; no `Data` / `Manager` / `Helper` /
  `Info` padding; name handlers for what they do, not what triggered
  them. (This mirrors the naming guidance in the global CLAUDE.md —
  load-bearing here because comments are off the table.)

## Scope — build only what's asked

Build the current step, not the next one. Don't add screens, flows,
components, or abstractions that haven't been agreed to — even when a
later need looks obvious. Float ideas in conversation and they'll be
considered, but don't commit speculative work to the codebase ahead
of a decision. Propose the next step; don't pre-build it.
