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
