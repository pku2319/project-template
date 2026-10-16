---
name: install
description: Set up {{PROJECT_NAME}} for local development by running bin/setup, fixing anything that goes wrong, and folding every fix back into the script so it keeps working. Use when someone has just cloned the repo, asks how to install or set up the project, hits missing tool, version or dependency errors, pulls changes that touch {{DEPENDENCY_FILES}}, or changes how the project is set up (new tool, new dependency, new environment variable, version bump).
---

# Install {{PROJECT_NAME}}

`bin/setup` does the installing. This skill exists to run it and, more importantly, to keep it correct: the script is the single source of truth for setup, so any step you have to do by hand belongs in the script before you finish.

## Run it

From the repository root: `bin/setup`.

- **Exit 0**: done. Report what it did.
- **Exit 2**: a system prerequisite is missing, and the message includes the install command. Ask the user before running it, since it changes their machine, then rerun `bin/setup`.
- **Any other failure**: diagnose and fix it, then go on to "Keep the script current".

## Keep the script current

Whenever setup needed something the script did not do, change the script so the next person does not hit the same problem:

1. Add the fix to `bin/setup` in the right section (prerequisite check, dependency install or verify). Keep it idempotent: check before acting so a rerun skips finished work. System level tools get a `require` check with an install hint, never an automatic install.
2. Rerun `bin/setup` from the start and confirm it passes.
3. If the fix cannot be scripted (an account to request, a secret to obtain), add it to "Manual steps" below and to the Installation section of `README.md`.
4. If the failure was confusing, add the symptom and the fix to "Troubleshooting" below.
5. If the fix involved a choice (a version, a tool, a workaround over the obvious approach), add a dated entry to `decision_log.txt` next to this file saying what was chosen and why.
6. Commit the script and doc changes together.

Apply the same steps when setup changes on purpose: a new dependency, tool, environment variable or version bump is not done until `bin/setup` handles it.

## Manual steps

{{MANUAL_STEPS_OR_NONE}}

## Troubleshooting

None recorded yet.

## Decision log

`decision_log.txt` next to this file records why setup is the way it is, starting with how the project was created. Read it before changing a version or swapping a tool, so you do not undo a deliberate choice.
