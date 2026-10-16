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

## Linting and Formatting

{{LINT_TOOL_AND_CONFIG}}

## Unit Testing

{{UNIT_TOOL_LOCATION_AND_CONVENTIONS}}

## E2e Testing

{{E2E_TOOL_LOCATION_AND_CONVENTIONS}}

## Test Coverage

{{COVERAGE_TOOL_AND_REPORT_LOCATION}}
