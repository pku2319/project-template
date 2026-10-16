---
name: new-project
description: Scaffold a brand new software project from scratch. Asks for a name, stack and supported versions, creates the folder, runs git init, installs the stack with its build tools, writes AGENTS.md and README.md from templates, adds a `bin/setup` script with an `install` skill that keeps it current, then installs linting, unit, e2e and coverage tooling, committing after each stage. Use this whenever the user wants to start, bootstrap, scaffold, spin up or initialize a new project, app, service, library or repo, even if they only name a stack ("start a new FastAPI thing", "make me a fresh Rails app").
---

# New Project

This skill takes a user from nothing to a committed, documented, tested project in four phases. Each phase ends in a commit, so the history reads as: stack installed, then docs with `bin/setup` and the install skill, then the testing suite.

Templates live next to this file in `templates/`. Stack defaults (build tools, test tools, task runners) live in `references/stacks.md`; read it once the stack is known.

## Keeping the user oriented

The run is long, so the user should always know where they are and how much is left.

- **At the start**, before the first question, show the outline: phase 1 has 8 steps of questions, then phases 2 to 4 run on their own and each ends in a commit.
- **In phase 1**, prefix every question with its position, for example "Step 3 of 8: Stack". When a step has several questions, show both levels: "Step 6 of 8: Testing tools (2 of 4: unit and integration testing)". If an answer makes a step unnecessary, say it is skipped rather than silently renumbering.
- **In phases 2 to 4**, announce each phase as it starts ("Phase 3 of 4: AGENTS.md, bin/setup, install skill and README") and each commit as it lands, so the user can follow along without being asked anything.

## Placeholders

Templates contain `{{UPPER_SNAKE}}` placeholders. Fill every one with real, project specific content. A placeholder you cannot fill means phase 1 missed a question: ask rather than guess, then add that question to phase 1 of this skill so future runs gather it up front. Before each commit, run `grep -rn '{{' AGENTS.md README.md bin/setup .claude/` in the project (skip any file not created yet); it must return nothing.

Write all generated text in line with the Communication Style section of the AGENTS.md template: no coined hyphenated compound modifiers, plain prose instead.

## Phase 1: Gather requirements

Every question for the whole run is asked here, so that once the user approves the plan, phases 2 to 4 run to the end without waiting on them. Only stop later for something truly unexpected that the plan cannot answer, such as a generator failing in a way that forces a different choice.

Ask one step at a time, in the order below, and wait for the answer before moving on. Later steps depend on earlier answers (versions depend on the stack, testing defaults depend on the build tools), and a single question is easier to think about than a form. Use AskUserQuestion with one question per call where the options are knowable; use free text otherwise.

1. **Name.** Ask for the project name, then separately for a one sentence description (it seeds the README). Derive a folder name in the stack's convention (usually lowercase with hyphens or underscores) and confirm it.
2. **Location.** Default to creating the folder inside the current working directory. Show the full absolute path and confirm. If the folder already exists and is not empty, stop and ask; never write into an existing project.
3. **Stack.** Ask what language, framework and notable pieces (database, frontend framework, package manager) they want.
4. **Versions.** Only offer versions that are currently officially supported, because starting a project on something near end of life creates an upgrade chore on day one. Look them up rather than relying on memory:
   - `curl -s https://endoflife.date/api/<product>.json` (for example `python`, `nodejs`, `ruby`, `rails`, `django`, `go`, `react`, `postgresql`). A cycle is supported if its `eol` is `false` or a date after today.
   - If the product is not on endoflife.date, check its official release or download page.
   - Offer the newest stable cycle as the recommended option, plus the other supported cycles. Point out compatibility constraints between pieces (for example a framework release that needs a minimum language version) and anything brand new enough that libraries may lag.
5. **Build tools.** Read `references/stacks.md` for the stack. Ask any choice it leaves open (for example which JavaScript package manager).
6. **Testing tools.** Go through the categories one at a time: linting and formatting, then unit and integration testing, then e2e testing, then coverage. For each, propose the default from `references/stacks.md` marked as recommended. The user may skip a category (for example no e2e for a library); note the reason, since AGENTS.md records it later so nobody wonders whether it was forgotten.
7. **System tools.** Check which version managers and build tools already exist (`which uv asdf mise nvm rbenv pnpm bun`, `asdf current`, and so on) and plan to use what the user already has. List anything missing at the system level (for example `brew install uv`) and get approval to install it now, since that changes their machine rather than the project. Include tools that only the testing suite needs.
8. **Plan.** Summarize everything: path, stack, versions, build tools, testing tools, system installs, and the three commits that will be made. Get a single go ahead before touching the filesystem.

## Phase 2: Create and install the stack

1. `mkdir -p <path> && cd <path> && git init`. Work from this directory for everything after this point.
2. **Install the approved system tools** from the plan, if any.
3. **Install the stack in place.** Run the generator or init command inside the current folder (`uv init .`, `npm create vite@latest .`, `rails new . --skip-git`, and so on), because many generators otherwise create a nested folder or a nested git repo. Pin the chosen versions in the files the ecosystem expects (`.python-version`, `.tool-versions`, `.nvmrc`, `engines`, `.ruby-version`, `go.mod`).
4. **Make sure `.gitignore` exists** and covers dependency folders, virtual environments, build output, env files and OS files before the first commit. Use the generator's file if it made one and extend it if needed.
5. **Verify it runs.** Start the app or run the hello world entry point once and confirm the output. Fix problems now; a broken first commit poisons everything after it.
6. Keep a running log of every command you ran, every choice made and why. Phase 3 turns it into `bin/setup` and the install skill.
7. Commit: `git add -A && git commit -m "Install <stack summary>"`, listing the versions in the body.

## Phase 3: AGENTS.md, bin/setup, install skill and README

### AGENTS.md
Copy `templates/AGENTS.md` to the project root and fill it in:
- **Communication Style**: keep verbatim.
- **Installation**: toolchain with pinned versions and where each pin lives, plus the everyday setup and run commands.
- **Commenting**: rewrite the bad and good examples in the project's language, using the same ideas (a named constant instead of a "what" comment; a "why" comment about a real trade off).
- **Documentation**: list the ways a command becomes runnable in this stack (console scripts in `pyproject.toml`, `package.json` scripts, rake tasks, `cmd/` binaries, new flags on existing ones).

Do not add the Testing section yet; that happens in phase 4.

### bin/setup
The setup script does the actual installing; the install skill only wraps it. Putting the steps in a script means people without Claude get the same setup, and there is one place to fix when setup changes.

Copy `templates/bin/setup` to `bin/setup` (`chmod +x`) and fill it from the phase 2 log. If the generator already made a `bin/setup` (Rails does), merge the template's prerequisite checks and exit codes into it rather than replacing it.
- **Prerequisites**: one `require` line per system tool (version manager, build tool, database server), with the install command as the hint. Also check versions where a wrong one would break things. The script checks system tools but never installs them, so it is always safe to run.
- **Dependencies**: everything inside the project: language version through the version manager, packages, `.env` copied from `.env.example` if missing, database creation. Each step skips work that is already done.
- **Verify**: a fast command that proves the install works (import the package, run the CLI with `--help`, boot the app and hit it once).

Then prove it from a clean state: remove what the script creates (`.venv`, `node_modules`, and so on), run `bin/setup`, and confirm it passes. Run it a second time to confirm it is idempotent.

### Install skill
Copy `templates/install-skill/SKILL.md` to `.claude/skills/install/SKILL.md` and fill it in. Most of it is fixed text about running and maintaining `bin/setup`; fill the placeholders, and put the literal history from the phase 2 log in "How this project was created": the generator command, versions chosen and why.

### README.md
If the generator wrote a README, replace it with `templates/README.md` filled in (keep anything useful from the generated one). The Installation section must explain both routes: `/install` in Claude Code, and running `bin/setup` directly for people not using Claude.

Run the placeholder grep, then commit: `git commit -m "Add AGENTS.md, README, bin/setup and install skill"`.

## Phase 4: Testing suite

1. **Use the tools chosen in phase 1.** For any skipped category, write the reason in its AGENTS.md section instead of a tool.
2. **Install and configure** each tool as a development dependency, with config in the conventional place.
3. **Add one real example test per category** (a unit test of the hello world code, an e2e test that loads the app or runs the CLI) so every command proves it works. Fix any lint errors the linter reports in the generated code.
4. **Wire up commands** using the stack's task runner from `references/stacks.md`. The required set is: lint, auto fix, unit, e2e, coverage, `check` (everything except e2e) and `check:all` or equivalent (everything including e2e). Run every one of them and confirm each passes. Do not claim a command works without having run it.
5. **Update bin/setup and the install skill**: add anything the testing tools need to `bin/setup` (browser binaries for Playwright, for example), and make its verify step run `check`. Rerun it from a clean state as in phase 3. Record the testing choices in the install skill's "How this project was created".
6. **Update AGENTS.md**: append `templates/AGENTS.testing.md` filled in, between Installation and Commenting.
7. **Update README.md**: fill the Testing section with the commands.
8. Run the placeholder grep, then commit: `git commit -m "Add testing suite"`.

## Finish

Report the path, the three commits (`git log --oneline`), the commands to run the app and the checks, and anything skipped or left for the user (for example a tool they declined to install). Do not push or create a remote unless asked.
