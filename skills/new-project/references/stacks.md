# Stack defaults

Starting points, not rules, read during phase 1 so every choice is settled before installing. If the user names a tool, use theirs. If a stack is missing here, pick the tool its official docs recommend and say so. Check current versions with endoflife.date or the tool's release page rather than trusting this file.

## Python
- **Build and env**: uv (`uv init .`, `uv python pin <version>`, `uv add`, `uv add --dev`). uv installs Python itself, so no separate version manager is needed.
- **Release age**: pass `--exclude-newer "3 days"` to `uv add` and `uv lock`. Older uv versions only accept a timestamp, so give the moment 3 days before now in RFC 3339 form.
- **Lint and format**: ruff (`ruff check`, `ruff format`), config in `pyproject.toml`.
- **Accessibility**: ruff has no accessibility rules. For projects with Django or Jinja templates, add djLint (`uv add --dev djlint`) and set `profile = "django"` or `profile = "jinja"` under `[tool.djlint]` in `pyproject.toml`. Run `djlint <templates dir> --lint` as part of `make lint`. Its linter catches problems such as an `img` without `alt`. Projects without server rendered templates skip this.
- **Unit**: pytest, tests in `tests/`.
- **E2e**: Playwright for Python (`pytest-playwright`, then `uv run playwright install chromium`) for web apps; for CLIs, pytest driving the console script through `subprocess`.
- **E2e waiting**: Playwright locator actions wait for the element on their own, and `expect(locator).to_be_visible()`, `to_have_text()` and the other `expect` assertions retry until they pass. Use `page.expect_response()` to wait for a request. Never `time.sleep()` or `page.wait_for_timeout()`. For CLIs, `subprocess.run()` waits for the process to exit; for a long running process, read its output until the expected line appears.
- **Coverage**: pytest-cov (`pytest --cov`).
- **Task runner**: Makefile (`make lint`, `make fix`, `make test`, `make e2e`, `make coverage`, `make check`, `make check-all`).

## JavaScript and TypeScript
- **Build and env**: ask which package manager (npm, pnpm, bun). Node version via whatever manager they use (asdf `.tool-versions`, mise, nvm `.nvmrc`), plus `engines` in `package.json`. Prefer TypeScript unless told otherwise.
- **Release age**: npm 11.10 or later takes `--min-release-age=3` (days). pnpm 10.16 or later takes `minimumReleaseAge: 4320` (minutes) in `pnpm-workspace.yaml`. Bun 1.3 or later takes `minimumReleaseAge = 259200` (seconds) under `[install]` in `bunfig.toml`. On older versions, upgrade the package manager first or check publish dates with `npm view <package> time`.
- **SQL database**: Prisma, with Prisma Migrate for schema changes (`prisma migrate dev` creates a migration, `prisma migrate deploy` applies pending ones). The migrations requirement is a rule, not a starting point: never pick an ORM or query builder that doesn't come with migrations. If the user names one without them, say so and suggest Prisma. If they want a different ORM that does have migrations (such as Drizzle with drizzle-kit), use theirs. In `bin/setup`, the database step runs `prisma migrate deploy` and `prisma generate`, since both run without prompting and do nothing when everything is already up to date. Prisma's setup has changed between major versions, so follow the current docs for the installed version. Run `prisma init` with `--no-skills`, because otherwise it installs every Prisma agent skill for every agent it knows about. Then install only the skills this project needs, for the agent doing the setup, for example `npx skills@<version> add prisma/skills --skill prisma-cli --skill prisma-client-api --agent claude-code --copy -y` for Claude Code, with `--agent` set to whichever agent is running. Leave out skills for databases or services the project doesn't use (MongoDB, Prisma Postgres, Prisma Compute), upgrade guides (a new project starts on the current version), deprecated aliases, the guide to writing a driver adapter, and `prisma-orm-setup` while it steers new projects to a Prisma prerelease.
- **Lint and format**: ESLint (flat config) with Prettier, or Biome if they prefer one tool.
- **Accessibility**: for projects with a UI, add the framework's accessibility rules to the ESLint config so the `lint` script runs them. Use `eslint-plugin-jsx-a11y` with `jsxA11y.flatConfigs.recommended` for React and other JSX, `eslint-plugin-vuejs-accessibility` with `configs["flat/recommended"]` for Vue, and `angular.configs.templateAccessibility` from `angular-eslint` for Angular templates. Svelte needs no extra plugin, because `svelte.configs.recommended` from `eslint-plugin-svelte` reports the compiler's accessibility warnings through `svelte/valid-compile`. With Biome, keep the `a11y` rule group that `recommended` turns on, and never disable it.
- **Unit**: Vitest (Jest only for an existing Jest ecosystem such as some React Native setups).
- **E2e**: Playwright (`@playwright/test`, `npx playwright install`).
- **E2e waiting**: locator actions wait for the element on their own, and `await expect(locator).toBeVisible()`, `toHaveText()` and the other web first assertions retry until they pass. Use `page.waitForResponse()` to wait for a request. Never `page.waitForTimeout()` or a `setTimeout` promise.
- **Coverage**: Vitest coverage with `@vitest/coverage-v8`.
- **Task runner**: `package.json` scripts (`lint`, `fix`, `test`, `test:e2e`, `coverage`, `check`, `check:all`).

## Ruby and Rails
- **Build and env**: Bundler; Ruby via their manager (asdf, rbenv, mise) with `.ruby-version` or `.tool-versions`. Rails: `rails new .` plus the database flag they chose; omit `--skip-git`, which also skips `.gitignore`, and let it rerun `git init` harmlessly. Rails generates its own `bin/setup`; merge the template into it.
- **Release age**: Bundler 4.0.13 or later supports a cooldown; set `BUNDLE_COOLDOWN=3` for every Bundler command in the run, including the `bundle install` that `rails new` runs. On older Bundler, update it first (`gem update --system`). For the `rails` gem itself and anything installed with `gem install`, check `https://rubygems.org/api/v1/versions/<gem>.json` for `created_at` and pass `-v <version>`.
- **asdf and new Ruby releases**: the asdf ruby plugin keeps its own copy of ruby-build at `~/.asdf/plugins/ruby/ruby-build`. Homebrew does not manage it (`brew upgrade ruby-build` reports it is not installed), and `asdf plugin update ruby` alone may not make a new Ruby appear in `asdf list all ruby`. The fix that works is `asdf plugin remove ruby && asdf plugin add ruby`, then `asdf install ruby <version>`. Warn first: removing the plugin uninstalls every Ruby it installed, so other projects need `asdf install` afterwards. When the project uses asdf for Ruby, generate `bin/update-ruby` in phase 3 (see SKILL.md) and mention this in `bin/setup`, the install skill and the README.
- **Lint and format**: RuboCop (`rubocop-rails-omakase` comes with Rails 7.2 and later), plus `rubocop-rspec` when the project uses RSpec. Whatever else is chosen, `.rubocop.yml` must include the rules in "RuboCop rules for every Ruby project" below, and a Rails app's must also load the cops in "RuboCop accessibility rules for Rails apps".
- **Unit**: Minitest for Rails by default; RSpec if they prefer.
- **E2e**: Capybara system tests (Rails includes them) with Selenium or Cuprite.
- **E2e waiting**: Capybara finders and matchers (`find`, `click_on`, `assert_selector`, `assert_text`, or `have_css` and `have_content` in RSpec) retry until `Capybara.default_max_wait_time`. Check for absence with `assert_no_selector` or `have_no_content`, since `refute page.has_css?` checks once and gives up. Never `sleep`.
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

### RuboCop accessibility rules for Rails apps
This is a rule too, for every Rails app with views. Add `rubocop-rails-accessibility` to the `Gemfile`'s development group and load it in `.rubocop.yml`. Version 1.0.1 is not a RuboCop plugin, so it goes under `require:`, not `plugins:`. If a newer release says in its README that it supports `plugins:`, use that instead.

```yaml
require:
  - rubocop-rails-accessibility
```

Its cops check Ruby view helpers such as `image_tag` without `alt` and a positive `tabindex`. RuboCop does not read raw HTML in ERB, so an `<img>` tag written by hand is not checked.

To cover that HTML, offer the Herb linter (`@herb-tools/linter`) in phase 1 as an opt-in, not a default. Offer it only for Rails apps that already have a JavaScript package manager (jsbundling or Vite), since an importmap app would need one added just for this. It has about 25 accessibility rules, including alt text, ARIA roles and attributes, empty headings, iframe titles and positive `tabindex`. It has only existed since July 2025 and is still 0.x, so rules and config can change between minor releases. Say both of these things when offering it. If the user chooses it, add it as a development dependency pinned to an exact version, create `.herb.yml` with `npx herb-lint --init`, and run `herb-lint` from the `lint` Rake task so `bin/rails lint` fails on its errors.

## Go
- **Build and env**: Go modules (`go mod init <module path>`), Go version in `go.mod` and `toolchain` directive.
- **Release age**: Go has no setting for this. After `go get`, read each new module's publish time from `https://proxy.golang.org/<module>/@v/<version>.info` and pin back with `go get <module>@<version>` where it is under 3 days old.
- **Lint and format**: golangci-lint, gofmt.
- **Unit**: `go test ./...` with the standard library.
- **E2e**: `go test` with a build tag (`//go:build e2e`) that drives the built binary or HTTP server; Playwright if there is a web UI.
- **E2e waiting**: `cmd.Run()` and `cmd.Output()` wait for the binary to exit. For a server, wait until it prints its listening line on stdout, or pass it a listener the test already opened, before sending requests. Never `time.Sleep()`. With Playwright, use the waiting listed under JavaScript and TypeScript.
- **Coverage**: `go test -coverprofile=coverage.out ./...` and `go tool cover`.
- **Task runner**: Makefile.

## Rust
- **Build and env**: Cargo, toolchain pinned in `rust-toolchain.toml`.
- **Release age**: Cargo has no stable setting for this. Check `https://crates.io/api/v1/crates/<crate>/versions` for `created_at` and pin back with `cargo add <crate>@=<version>` or `cargo update -p <crate> --precise <version>`.
- **Lint and format**: clippy, rustfmt.
- **Unit**: `cargo test`.
- **E2e**: integration tests in `tests/` with `assert_cmd` for CLIs.
- **E2e waiting**: `Command::assert()` waits for the process to exit before checking its output. For a long running process, read its output until the expected line appears. Never `std::thread::sleep()` or `tokio::time::sleep()`.
- **Coverage**: cargo-llvm-cov.
- **Task runner**: Makefile or cargo aliases in `.cargo/config.toml`.
