---
name: dependencies
description: Add, upgrade, pin or remove a library in {{PROJECT_NAME}}. Reuses what is already installed when it covers the need, picks libraries that are maintained and widely used, and installs the newest stable release that is at least 3 days old and works with the rest of the stack. Use whenever you add, upgrade, pin or remove a dependency, change a version or constraint, run {{ADD_COMMANDS}}, or edit {{DEPENDENCY_FILES}}.
---

# Dependencies for {{PROJECT_NAME}}

## Rules

Every library in this project, including the indirect dependencies the package manager resolves, follows three rules:

1. **Stable releases only.** Never a release candidate, beta, alpha, nightly, canary, dev build or any other prerelease. A registry's `latest` tag is not proof of a stable release (npm's `latest` for `prisma` has pointed at an `8.0.0-rc`), so check the version string itself.
2. **At least 3 days old.** Compromised releases are usually reported and pulled within a few days, so waiting that long avoids most of them.
3. **The newest release that meets both rules and works with the stack.** Do not write a version from memory: what you remember may be several releases old.

Every direct dependency also follows two more:

4. **A stable release in the last year**, unless it has a finished library note (see Finished libraries).
5. **Enough history of use:**
   - its first stable release was at least 2 years ago;
   - it has at least 5 stable releases;
   - it is published by an organization, or by more than one maintainer;
   - when choosing between libraries that do the same job, its weekly downloads are at least 10% of the most downloaded candidate's. Where the registry has no weekly count, the report uses the closest measure it has.

## The scripts

`bin/dependency-report <package>` gathers the facts every step below needs: publish dates, the newest eligible release, release history, publisher, usage, security findings, what holds a version back, and what is already installed. Run it rather than looking these up by hand, and read its output before deciding. A result marked "check by hand" means the registry does not say, so look at the package's registry page or repository.

`bin/check-dependencies` fails on any break of rules 1 and 2 and warns about rule 4. It runs as part of `{{CHECK_COMMAND}}`, and as a Claude Code hook after any command or edit that changes dependencies. {{ENFORCEMENT}}

Never lower, remove or bypass these settings or checks yourself.

## Adding a library

1. **Check for overlap.** Before adding anything, check whether the standard library or something already installed covers the exact use case the library is being added for. `bin/dependency-report <package>` lists the direct and indirect dependencies.
   - A direct dependency or the standard library fully covers it: use that, and do not add the library.
   - An indirect dependency fully covers it: add that one as a direct dependency instead, following the steps below, so the project no longer relies on another package keeping it.
   - Something covers only part of it: ask the user what to do.
   - The user asked for this library by name: tell them what already covers it and let them choose.
   - What already covers it fails rule 4 or 5: tell the user, list where the project uses it (the code a switch would touch), and offer installing the new library alongside it as an option.
2. **Check that it is maintained and used.** If `bin/dependency-report <package>` shows it failing rule 4 or 5, find libraries that do the same job, compare them with `bin/dependency-report <package> --candidates <a>,<b>`, and use the best one that passes. Note the switch for the final report. Stop and ask only if no candidate passes.
3. **Install it.** Add it without a version or constraint, so the package manager resolves the newest release the settings allow: {{ADD_EXAMPLE}}. {{PRERELEASE_CHECK}}
4. **Handle a release under 3 days old.** When the newest release is under 3 days old, the settings install the newest eligible one instead, and the report shows whether the newer one fixes anything:
   - advisories from the OSV database that affect the installed version and not the newer one;
   - release notes for the newer one that mention security. A compromised release can make the same claim, so this is information only unless an advisory backs it.

   Give the user these findings and let them decide whether to make an exception. Never decide it yourself.
5. **Clear what holds it back.** Run the report again. If the installed version is not the newest eligible release, the report shows what holds it back. Work through it:
   - A constraint in this project's own files that nothing needs: loosen it.
   - Another library: upgrade that library the same way (see Upgrading), going at most 3 levels deep, for example a blocker of a blocker of a blocker.
   - Patch and minor upgrades of libraries go ahead without asking. Make one commit per library, and run `{{CHECK_COMMAND}}` before each one.
   - Major upgrades, the language runtime and the framework need the user to agree. Finish the patch and minor upgrades first, then ask about all of these together at the end.
   - Anything still held back after that goes in the decision log (see Records).
6. **Write code for the installed version.** Read that version's documentation or changelog rather than relying on memory, since APIs change between major releases.
7. **Finish the setup change.** Follow the install skill so `bin/setup` handles the new library, then run `{{CHECK_COMMAND}}`.

## Upgrading a library

Follow steps 2 to 7 above, without the overlap check. {{UPGRADE_EXAMPLE}} `{{OUTDATED_COMMAND}}` lists the direct dependencies that are behind. {{OUTDATED_NOTES}}

If a library fails rule 4 or 5 during an upgrade, do not stop: flag it in the final report with alternatives worth considering.

## Removing a library

Before removing it, run `bin/dependency-report <package> --removing`. It lists direct dependencies whose chain of dependencies includes this library, which may be able to move up once it is gone. Remove it with {{REMOVE_EXAMPLE}}, run `{{CHECK_COMMAND}}`, and report which libraries can now move up. Do not upgrade them unless the user asks.

## Finished libraries

Some libraries are complete and rarely need a release. Rule 4 does not apply to a library with a finished library note. {{FINISHED_NOTE}} `bin/check-dependencies` and the report read the note, so keep its wording. Add one only with the user's agreement, and whenever such a library would otherwise fail rule 4, give the note as the reason in the final report.

## Records

Add a dated entry to `.agents/skills/install/decision_log.txt` for:
- each direct dependency left behind the newest eligible release: the version used, the newer one, what holds it back, and what would let it move up. An older version with no entry is a mistake to fix;
- each library replaced by an alternative, and why;
- each exception the user approved, with the date it can be removed.

An approved exception needs two changes. {{EXCEPTION_NOTE}} Then add a line to `bin/check-dependencies.allow`: `<name>@<version>  <reason>  <YYYY-MM-DD it can be removed>`. The first lets the package manager install it, and the second lets `bin/check-dependencies` accept it.

## Final report

When done, tell the user:
- what was added, upgraded or removed, and at which versions;
- any alternative used instead of what was asked for, and why;
- libraries that pass rule 4 only because of a finished library note, with the note;
- libraries that failed rule 4 or 5 during an upgrade, with alternatives worth considering;
- versions held back, and what holds them;
- major, runtime or framework upgrades waiting for approval;
- security findings for any release under 3 days old;
- after a removal, the libraries that can now move up.

## Stop and ask

Ask the user before going further when:
- no release of the library is both stable and at least 3 days old;
- no candidate passes rules 4 and 5;
- something installed covers only part of the use case;
- the user named a library that something installed already covers;
- what already covers the use case fails rule 4 or 5;
- a release under 3 days old may fix a security problem;
- major, runtime or framework upgrades are pending. Ask about these together, at the end.
