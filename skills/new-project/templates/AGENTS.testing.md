# Testing

| What | Command |
|---|---|
| Lint and format check | `{{LINT_COMMAND}}` |
| Auto fix lint and formatting | `{{FIX_COMMAND}}` |
| Unit and integration tests | `{{UNIT_COMMAND}}` |
| End to end tests | `{{E2E_COMMAND}}` |
| Coverage report | `{{COVERAGE_COMMAND}}` |
| Everything except e2e | `{{CHECK_COMMAND}}` |
| Full suite including e2e | `{{CHECK_ALL_COMMAND}}` |

Run `{{CHECK_COMMAND}}` before every commit. Run `{{CHECK_ALL_COMMAND}}` before opening a pull request or after changing anything the e2e tests touch.

## Writing Tests

Confirm every new test fails without the change it covers. Run it before making the change, or revert the change and run it again. A test that passes either way proves nothing.

Cover the edge cases, not only the expected path:

- Empty values: nil or null, 0, empty strings and empty collections.
- The boundary of the change: the inputs just inside and just outside where the new behavior starts and stops.
- Unexpected input: the wrong type, malformed data and values out of range.

## Linting and Formatting

{{LINT_TOOL_AND_CONFIG}}

## Unit Testing

{{UNIT_TOOL_LOCATION_AND_CONVENTIONS}}

## E2e Testing

{{E2E_TOOL_LOCATION_AND_CONVENTIONS}}

Wait for the condition the next step depends on, such as an element appearing, text changing, a request finishing or a process exiting, using the waiting the e2e tool has built in. Do not pause for a fixed time with `sleep`, `wait` or a timeout call. A fixed pause is too short on a slow machine and wasted time on a fast one, so the test ends up both flaky and slow.

The one exception is a delay the app adds on purpose, such as a debounce or a deliberate wait written in the app's code. A test of that behavior may pause for that delay. Take the duration from the same constant the app uses rather than repeating the number, and add a comment pointing to the code that causes it.

{{E2E_WAITING}}

## Test Coverage

{{COVERAGE_TOOL_AND_REPORT_LOCATION}}
