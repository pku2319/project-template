# {{PROJECT_NAME}}

{{ONE_SENTENCE_DESCRIPTION}}

## Communication Style

Do not coin hyphenated compound modifiers or compress feature descriptions into hyphen-chained tokens. Phrases like "off-by-default telemetry" or "sync-ready schema" are prohibited. Unpack them into ordinary prose instead.

# Installation

`bin/setup` installs everything needed for local development and is safe to rerun. The install skill at `.agents/skills/install/SKILL.md` wraps it and keeps it current. `.claude/skills/install` is a link to the same folder so Claude Code finds it too; edit the files under `.agents/`. Whenever setup changes, such as a new tool, a dependency, a version bump or a new environment variable, update `bin/setup` in the same change, following the install skill, and rerun it to confirm it passes.

## Dependencies

Adding, upgrading or removing a library follows the dependencies skill at `.agents/skills/dependencies/SKILL.md` (linked from `.claude/skills/dependencies`). In short: use what is already installed when it covers the need; choose libraries with a release in the last year and enough history of use; install only stable releases published at least 3 days ago; and use the newest release that meets every rule and works with the stack. Never pick a version from memory. `bin/dependency-report` gathers the facts for each decision, and `bin/check-dependencies` enforces the release rules.

## Toolchain

{{TOOLCHAIN_LIST}}

## Everyday commands

{{EVERYDAY_COMMANDS}}

# Commenting

1. Do Not Write "What" Comments
Never explain what a line of code does. If the code is complex, refactor it into smaller, named helper functions instead of adding a comment.
- BAD: `{{BAD_WHAT_COMMENT_EXAMPLE}}`
- GOOD: `{{GOOD_NAMED_CONSTANT_EXAMPLE}}`

2. Document "Why" and "Context" Only
Write comments exclusively to explain business requirements, upstream API quirks, or non-obvious design trade-offs.
- EXAMPLE: `{{WHY_COMMENT_EXAMPLE}}`

# Documentation

- **A new command is not done until `README.md` documents it.** Whenever a command
  becomes runnable from the terminal ({{WAYS_A_COMMAND_BECOMES_RUNNABLE}}, or a new flag
  on one that already exists), add it to `README.md` in the same change, under the section
  that fits (`## Running`, `## Testing`, or `## Other Commands`), with the exact invocation
  and one line saying what it does.
- **A setup change is not done until `bin/setup` handles it.** See Installation above.
