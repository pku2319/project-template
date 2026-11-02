## Communication Style

Do not coin hyphenated compound modifiers or compress feature descriptions into hyphen-chained tokens. Phrases like "off-by-default telemetry" or "sync-ready schema" are prohibited. Unpack them into ordinary prose instead.

# About this repo

This repo holds the `new-project` skill in `skills/new-project/`. The files in `skills/new-project/templates/` are copied into new projects, so they contain only text meant for those projects. Instructions about the process of creating a project belong in `skills/new-project/SKILL.md`, never in the templates.

The README section "What the template decides for you" summarizes the template's choices for people deciding whether to use it. Whenever a change to `SKILL.md`, `references/stacks.md`, the templates or the reference lint configs adds, removes or alters one of those choices (a default tool, a new stack, a new rule, changed phases or commits), update that README section in the same change. Keep it brief and written for readers who have not seen the skill; `SKILL.md` and `stacks.md` remain the source of truth.
