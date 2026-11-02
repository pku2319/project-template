# project-template

An agent skill that scaffolds new projects: it asks for a name, stack and supported versions, installs the stack, writes AGENTS.md, README.md, a `bin/setup` script and an install skill that keeps the script current, then adds a testing suite, committing after each stage.

The skill follows the open [Agent Skills](https://agentskills.io) format, so it works in Claude Code and in any other agent that loads skills from a `SKILL.md` folder.

## Installation

Link the skill into your personal skills folder so it is available in every directory.

Claude Code:

```
ln -s "$(pwd)/skills/new-project" ~/.claude/skills/new-project
```

Other agents: link it into the folder your agent reads personal skills from. Many read the shared `~/.agents/skills/` folder:

```
mkdir -p ~/.agents/skills
ln -s "$(pwd)/skills/new-project" ~/.agents/skills/new-project
```

## Running

From the folder where the new project should live, start your agent and ask it to start a new project. In Claude Code you can also run:

```
/new-project
```

## What this skill does

### Current Flow

- It asks, as much as possible, all question up front, one at a time: name, location, stack, versions, build tools, testing tools and system tools. Then it gives you the summary of the plan which you can approve or refine.
- After that the rest runs on its own and makes three commits: the stack installed, then the docs and setup, then the testing suite.

Note: It does not create a remote, and it does not write into an existing folder that has files in it.

### Opinionated Parts

- Stable releases only. No release candidates, betas or nightlies unless you ask for one and confirm.
- Nothing published in the last 3 days, including indirect dependencies, because compromised releases are usually pulled within a few days. Where the package manager has a release age setting, it is switched on. It will note when a release is being gated by the 3 day rule during the QA phase and in the decision log.
- Only language and framework versions that are still officially supported will be given as options based on a search the time of the run.
- `AGENTS.md` for coding agents and `README.md` for people.
- A `bin/setup` script that checks system tools, installs project dependencies and verifies the result. It is safe to run again.
- An `install` skill that runs `bin/setup` and keeps it current, plus a decision log recording what was chosen and why.
- The same set of commands in every stack: lint, fix, unit tests, end to end tests, coverage, `check` (everything except end to end tests) and `check:all` (everything). Each has a working example test, and each testing component is run before being committed.

#### Stack defaults

Tools you name override these.

| Stack | Build and environment | Lint and format | Unit | End to end |
| --- | --- | --- | --- | --- |
| Python | uv | ruff | pytest | Playwright, or pytest driving the CLI |
| JavaScript and TypeScript | npm, pnpm or bun (you pick), TypeScript preferred | Prettier with oxlint (ESLint for Vue templates, Svelte and Angular) | Vitest | Playwright |
| Ruby and Rails | Bundler with your Ruby version manager | RuboCop | Minitest, or RSpec | Capybara system tests |
| Go | Go modules | golangci-lint and gofmt | `go test` | `go test` with a build tag |
| Rust | Cargo | clippy and rustfmt | `cargo test` | `assert_cmd` integration tests |

Task runners are a Makefile for Python and Go, `package.json` scripts for JavaScript, Rake tasks through `bin/rails` for Rails, and a Makefile or cargo aliases for Rust. Coverage uses pytest-cov, Vitest coverage, SimpleCov, `go tool cover` and cargo-llvm-cov respectively.

#### Firm rules

These are not defaults you can drift from; the skill applies them in every project they fit.

- SQL databases use a tool with migrations, Prisma by default for JavaScript and TypeScript.
- Projects with a UI get accessibility linting as part of the lint command, and its failures are errors to fix.
- End to end tests wait for conditions through the test tool's own waiting, never with sleeps or fixed pauses.
- Every new test must be confirmed to fail without the change it covers.
- Documentation is kept up to date with commands and setup  (a new command or setup change automatically updates the README, AGENTS.md and `bin/setup`).

For specific lint rules and formatting settings see `stacks.md` and the reference configs in `skills/new-project/references/` for them.

## Layout

- `skills/new-project/SKILL.md`: the process the agent follows
- `skills/new-project/templates/`: files copied into each new project, with `{{PLACEHOLDERS}}` the agent fills in
- `skills/new-project/references/stacks.md`: default build and test tools per stack

Projects created by the skill keep their install skill in `.agents/skills/install/`, with a link at `.claude/skills/install` so Claude Code finds it as well.
