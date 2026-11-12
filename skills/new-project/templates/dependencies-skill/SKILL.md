---
name: dependencies
description: Choose the version when adding, upgrading or pinning a library in {{PROJECT_NAME}}, so it is the newest stable release that is at least 3 days old and works with the rest of the stack. Use whenever you add or upgrade a dependency, change a version or constraint, run {{ADD_COMMANDS}}, or edit {{DEPENDENCY_FILES}}.
---

# Dependencies for {{PROJECT_NAME}}

Every library in this project, including the indirect dependencies the package manager resolves, follows three rules:

1. **Stable releases only.** Never a release candidate, beta, alpha, nightly, canary, dev build or any other prerelease. A registry's `latest` tag is not proof of a stable release (npm's `latest` for `prisma` has pointed at an `8.0.0-rc`), so check the version string itself.
2. **At least 3 days old.** Compromised releases are usually reported and pulled within a few days, so waiting that long avoids most of them.
3. **The newest release that meets both rules and works with the stack.** Do not write a version from memory: what you remember may be several releases old.

## How this project enforces them

{{ENFORCEMENT}}

Never lower, remove or bypass these settings yourself.

## Adding or upgrading a library

1. **Let the package manager choose.** Add the library without a version or constraint, so it resolves the newest release the settings allow: {{ADD_EXAMPLE}}.
2. **Check that it is stable.** Read the version that was installed. {{PRERELEASE_CHECK}}
3. **Check that it is the newest eligible release.** Run `{{OUTDATED_COMMAND}}`. {{OUTDATED_NOTES}}
4. **Explain anything older.** If a direct dependency is behind the newest eligible release, find the constraint that holds it back: a peer dependency, the language version, or another library's upper bound. Remove the constraint if nothing needs it. Otherwise keep the older version and add a dated entry to `.agents/skills/install/decision_log.txt` naming the version used, the newer one, the constraint, and what would let the project move up. An older version with no entry is a mistake to fix.
5. **Write code for the installed version.** Read that version's documentation or changelog rather than relying on memory, since APIs change between major releases.
6. **Finish the setup change.** Follow the install skill so `bin/setup` handles the new library, then run the checks.

## Stop and ask

Ask the user before going further when:

- no release of the library is both stable and at least 3 days old;
- the newest eligible release needs another part of the stack upgraded or downgraded;
- a newer release fixes a security problem the project is exposed to. {{EXCEPTION_NOTE}} Record an approved exception in the decision log, with the date it can be removed.
