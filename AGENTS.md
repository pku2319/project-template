## Communication Style

Do not coin hyphenated compound modifiers or compress feature descriptions into hyphen-chained tokens. Phrases like "off-by-default telemetry" or "sync-ready schema" are prohibited. Unpack them into ordinary prose instead.

# About this repo

This repo holds the `new-project` skill in `skills/new-project/`. The files in `skills/new-project/templates/` are copied into new projects, so they contain only text meant for those projects. Instructions about the process of creating a project belong in `skills/new-project/SKILL.md`, never in the templates.

The README section "What the template decides for you" summarizes the template's choices for people deciding whether to use it. Whenever a change to `SKILL.md`, `references/stacks.md`, the templates or the reference lint configs adds, removes or alters one of those choices (a default tool, a new stack, a new rule, changed phases or commits), update that README section in the same change. Keep it brief and written for readers who have not seen the skill; `SKILL.md` and `stacks.md` remain the source of truth.

# Versioning

The skill's version is in `skills/new-project/VERSION` and its history is in `CHANGELOG.md`.

- Every change to the skill, its references or its templates adds a line under "Unreleased" in `CHANGELOG.md` in the same change, written for someone who uses the skill. Changes to this repo's own tests and tooling do not need one.
- Start the line with **Breaking:** when someone who relied on what the skill did before would now get something different or be refused. Examples: a stack, supported version, generated file, script or skill is removed or renamed; a default tool changes; a phase or commit is dropped or reordered; a question is added with no default. Adding a stack, tool, rule, file or optional step is not breaking, and neither is fixing something so it does what it already claimed to do.
- Leave `VERSION` alone between releases. At a release, pick the version from the most serious change under "Unreleased": while below 1.0, any breaking change bumps the minor number and everything else bumps the patch number. Update `VERSION`, rename "Unreleased" to the version and date, add a new empty "Unreleased" above it, and tag the release commit (`v0.4.0`).
