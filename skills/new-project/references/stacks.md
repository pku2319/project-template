# Stack defaults

Starting points, not rules, read during phase 1 so every choice is settled before installing. If the user names a tool, use theirs. If a stack is missing here, pick the tool its official docs recommend and say so. Check current versions with endoflife.date or the tool's release page rather than trusting this file.

## Python
- **Build and env**: uv (`uv init .`, `uv python pin <version>`, `uv add`, `uv add --dev`). uv installs Python itself, so no separate version manager is needed.
- **Release age**: pass `--exclude-newer "3 days"` to `uv add` and `uv lock`. Older uv versions only accept a timestamp, so give the moment 3 days before now in RFC 3339 form.
- **Lint and format**: ruff (`ruff check`, `ruff format`), config in `pyproject.toml`.
- **Unit**: pytest, tests in `tests/`.
- **E2e**: Playwright for Python (`pytest-playwright`, then `uv run playwright install chromium`) for web apps; for CLIs, pytest driving the console script through `subprocess`.
- **Coverage**: pytest-cov (`pytest --cov`).
- **Task runner**: Makefile (`make lint`, `make fix`, `make test`, `make e2e`, `make coverage`, `make check`, `make check-all`).

## JavaScript and TypeScript
- **Build and env**: ask which package manager (npm, pnpm, bun). Node version via whatever manager they use (asdf `.tool-versions`, mise, nvm `.nvmrc`), plus `engines` in `package.json`. Prefer TypeScript unless told otherwise.
- **Release age**: npm 11.10 or later takes `--min-release-age=3` (days). pnpm 10.16 or later takes `minimumReleaseAge: 4320` (minutes) in `pnpm-workspace.yaml`. Bun 1.3 or later takes `minimumReleaseAge = 259200` (seconds) under `[install]` in `bunfig.toml`. On older versions, upgrade the package manager first or check publish dates with `npm view <package> time`.
- **SQL database**: Prisma, with Prisma Migrate for schema changes (`prisma migrate dev` creates a migration, `prisma migrate deploy` applies pending ones). The migrations requirement is a rule, not a starting point: never pick an ORM or query builder that doesn't come with migrations. If the user names one without them, say so and suggest Prisma. If they want a different ORM that does have migrations (such as Drizzle with drizzle-kit), use theirs. In `bin/setup`, the database step runs `prisma migrate deploy` and `prisma generate`, since both run without prompting and do nothing when everything is already up to date. Prisma's setup has changed between major versions, so follow the current docs for the installed version.
- **Lint and format**: ESLint (flat config) with Prettier, or Biome if they prefer one tool.
- **Unit**: Vitest (Jest only for an existing Jest ecosystem such as some React Native setups).
- **E2e**: Playwright (`@playwright/test`, `npx playwright install`).
- **Coverage**: Vitest coverage with `@vitest/coverage-v8`.
- **Task runner**: `package.json` scripts (`lint`, `fix`, `test`, `test:e2e`, `coverage`, `check`, `check:all`).

## Ruby and Rails
- **Build and env**: Bundler; Ruby via their manager (asdf, rbenv, mise) with `.ruby-version` or `.tool-versions`. Rails: `rails new .` plus the database flag they chose; omit `--skip-git`, which also skips `.gitignore`, and let it rerun `git init` harmlessly. Rails generates its own `bin/setup`; merge the template into it.
- **Release age**: Bundler 4.0.13 or later supports a cooldown; set `BUNDLE_COOLDOWN=3` for every Bundler command in the run, including the `bundle install` that `rails new` runs. On older Bundler, update it first (`gem update --system`). For the `rails` gem itself and anything installed with `gem install`, check `https://rubygems.org/api/v1/versions/<gem>.json` for `created_at` and pass `-v <version>`.
- **asdf and new Ruby releases**: the asdf ruby plugin keeps its own copy of ruby-build at `~/.asdf/plugins/ruby/ruby-build`. Homebrew does not manage it (`brew upgrade ruby-build` reports it is not installed), and `asdf plugin update ruby` alone may not make a new Ruby appear in `asdf list all ruby`. The fix that works is `asdf plugin remove ruby && asdf plugin add ruby`, then `asdf install ruby <version>`. Warn first: removing the plugin uninstalls every Ruby it installed, so other projects need `asdf install` afterwards. When the project uses asdf for Ruby, generate `bin/update-ruby` in phase 3 (see SKILL.md) and mention this in `bin/setup`, the install skill and the README.
- **Lint and format**: RuboCop (`rubocop-rails-omakase` comes with Rails 7.2 and later), plus `rubocop-rspec` when the project uses RSpec. Whatever else is chosen, `.rubocop.yml` must include the rules in "RuboCop rules for every Ruby project" below.
- **Unit**: Minitest for Rails by default; RSpec if they prefer.
- **E2e**: Capybara system tests (Rails includes them) with Selenium or Cuprite.
- **Coverage**: SimpleCov.
- **Task runner**: Rails apps use `bin/rails`, which also runs every Rake task (`bin/rails test`, `bin/rails lint`, `bin/rails check`); define custom tasks in `lib/tasks/*.rake` and invoke them through `bin/rails`, not `rake`. Plain Ruby projects without Rails have no `rails` command, so they use Rake (`bundle exec rake <task>`) or `bin/` scripts.

### RuboCop rules for every Ruby project
Unlike the rest of this file, these are not starting points: add them to every Ruby project's `.rubocop.yml`, after any `inherit_gem` entry (such as `rubocop-rails-omakase`) so they take precedence. Leave one out only if the user explicitly asks for a different style.

```yaml
Style/Documentation:
  Enabled: false

Style/TrailingCommaInArrayLiteral:
  EnforcedStyleForMultiline: consistent_comma

Style/TrailingCommaInHashLiteral:
  EnforcedStyleForMultiline: consistent_comma

Style/TrailingCommaInArguments:
  EnforcedStyleForMultiline: consistent_comma
```

When the project uses RSpec, also add `rubocop-rspec` to the `Gemfile`'s development group and load it at the top of `.rubocop.yml`:

```yaml
plugins:
  - rubocop-rspec
```

Run `rubocop --autocorrect-all` after adding them so the generated code already follows them before the testing suite commit.

## Go
- **Build and env**: Go modules (`go mod init <module path>`), Go version in `go.mod` and `toolchain` directive.
- **Release age**: Go has no setting for this. After `go get`, read each new module's publish time from `https://proxy.golang.org/<module>/@v/<version>.info` and pin back with `go get <module>@<version>` where it is under 3 days old.
- **Lint and format**: golangci-lint, gofmt.
- **Unit**: `go test ./...` with the standard library.
- **E2e**: `go test` with a build tag (`//go:build e2e`) that drives the built binary or HTTP server; Playwright if there is a web UI.
- **Coverage**: `go test -coverprofile=coverage.out ./...` and `go tool cover`.
- **Task runner**: Makefile.

## Rust
- **Build and env**: Cargo, toolchain pinned in `rust-toolchain.toml`.
- **Release age**: Cargo has no stable setting for this. Check `https://crates.io/api/v1/crates/<crate>/versions` for `created_at` and pin back with `cargo add <crate>@=<version>` or `cargo update -p <crate> --precise <version>`.
- **Lint and format**: clippy, rustfmt.
- **Unit**: `cargo test`.
- **E2e**: integration tests in `tests/` with `assert_cmd` for CLIs.
- **Coverage**: cargo-llvm-cov.
- **Task runner**: Makefile or cargo aliases in `.cargo/config.toml`.
