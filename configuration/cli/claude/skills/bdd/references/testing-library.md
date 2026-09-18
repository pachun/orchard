# Testing library reference — ERTL & RNTL

The tools underneath the `emma` / `emma_api` test suites, and the
finder/matcher facts worth having at hand.

## The stack

- Tests import from **`expo-router/testing-library`** (ERTL) — Expo
  Router's testing utilities: `renderRouter`, `screen`, and router
  assertions (`toHavePathname`, `toHavePathnameWithParams`).
- ERTL wraps **`@testing-library/react-native`** (RNTL) and re-exports
  its queries and matchers.
- RNTL renders through react-test-renderer — there is no DOM.
- Docs: ERTL — https://docs.expo.dev/router/reference/testing/ ·
  RNTL — https://oss.callstack.com/react-native-testing-library/
  (queries: `/docs/api/queries`).

## Finders — the three variants (internalize this)

For every query (`ByTestId`, `ByText`, `ByDisplayValue`, `ByRole`, …):

- **`getBy*`** — synchronous. Throws immediately if it finds 0 or >1.
  Good message (`Unable to find an element with testID: X`). Use when
  the element is already present.
- **`queryBy*`** — synchronous. Returns `null` for 0 (still throws for
  >1). Use to assert **absence**: `expect(queryBy…).toBeNull()`.
- **`findBy*`** — asynchronous. Retries (via `waitFor`) until present or
  timeout, then throws the same good message. Use when the element
  appears after a transition or async render. `await` it.
- `*All*` variants return arrays; 0 matches is allowed (empty array).

Rule of thumb: a helper in `tests/helpers/expectations/` is `async`
because it **waits** (`findBy` / `waitFor`) — not for uniformity. Make a
helper async only when it needs to wait for what it asserts.

## The value-prop gotcha (learned the hard way — see notes.md)

`getByText` / `queryByText` match **`<Text>` nodes only**. They do NOT
see a `<TextInput>`'s `value`. So "the field shows +12125551234" is
invisible to `queryByText` — which is why an `expectTextNotToBeVisible`
assertion passed while the field was full of digits.

- To assert what is **in a field**, read its value:
  `getByTestId(id).props.value`, or query the rendered value with
  `getByDisplayValue` / `queryByDisplayValue`.
- House helpers: `expectTestIdToHaveValue` (baseline, any input's
  `value`) and `expectTextFieldToHaveValue` (text-field wrapper that
  reads nicely). Wrap the baseline again per input type as new ones need
  it (e.g. a `<Switch>`'s boolean `value`).

## testID as a query

RNTL's own guidance ranks `getByTestId` last, behind
role/label/text/displayValue, because testIDs don't resemble how a user
interacts. This codebase deliberately leans on `testID` for stable
targeting — a house choice, not the library default.
