# Stack defaults

Starting points, not rules, read during phase 1 so every choice is settled before installing. If the user names a tool, use theirs. If a stack is missing here, pick the tool its official docs recommend and say so. Check current versions with endoflife.date or the tool's release page rather than trusting this file.

## Python
- **Build and env**: uv (`uv init .`, `uv python pin <version>`, `uv add`, `uv add --dev`). uv installs Python itself, so no separate version manager is needed.
- **Lint and format**: ruff (`ruff check`, `ruff format`), config in `pyproject.toml`.
- **Unit**: pytest, tests in `tests/`.
- **E2e**: Playwright for Python (`pytest-playwright`, then `uv run playwright install chromium`) for web apps; for CLIs, pytest driving the console script through `subprocess`.
- **Coverage**: pytest-cov (`pytest --cov`).
- **Task runner**: Makefile (`make lint`, `make fix`, `make test`, `make e2e`, `make coverage`, `make check`, `make check-all`).

## JavaScript and TypeScript
- **Build and env**: ask which package manager (npm, pnpm, bun). Node version via whatever manager they use (asdf `.tool-versions`, mise, nvm `.nvmrc`), plus `engines` in `package.json`. Prefer TypeScript unless told otherwise.
- **Lint and format**: ESLint (flat config) with Prettier, or Biome if they prefer one tool.
- **Unit**: Vitest (Jest only for an existing Jest ecosystem such as some React Native setups).
- **E2e**: Playwright (`@playwright/test`, `npx playwright install`).
- **Coverage**: Vitest coverage with `@vitest/coverage-v8`.
- **Task runner**: `package.json` scripts (`lint`, `fix`, `test`, `test:e2e`, `coverage`, `check`, `check:all`).

## Ruby and Rails
- **Build and env**: Bundler; Ruby via their manager (asdf, rbenv, mise) with `.ruby-version` or `.tool-versions`. Rails: `rails new .` plus the database flag they chose; omit `--skip-git`, which also skips `.gitignore`, and let it rerun `git init` harmlessly. Rails generates its own `bin/setup`; merge the template into it.
- **asdf and new Ruby releases**: the asdf ruby plugin keeps its own copy of ruby-build at `~/.asdf/plugins/ruby/ruby-build`. Homebrew does not manage it (`brew upgrade ruby-build` reports it is not installed), and `asdf plugin update ruby` alone may not make a new Ruby appear in `asdf list all ruby`. The fix that works is `asdf plugin remove ruby && asdf plugin add ruby`, then `asdf install ruby <version>`. Warn first: removing the plugin uninstalls every Ruby it installed, so other projects need `asdf install` afterwards. When the project uses asdf for Ruby, generate `bin/update-ruby` in phase 3 (see SKILL.md) and mention this in `bin/setup`, the install skill and the README.
- **Shared `GEM_HOME`**: if the shell sets `GEM_HOME` (for example `~/.gem`), every Ruby shares one gem folder and Bundler prints "missing extensions" warnings for gems built under an older Ruby. They are harmless; mention them in the install skill's Troubleshooting rather than changing the user's shell config.
- **Lint and format**: RuboCop (`rubocop-rails-omakase` comes with Rails 7.2 and later).
- **Unit**: Minitest for Rails by default; RSpec if they prefer.
- **E2e**: Capybara system tests (Rails includes them) with Selenium or Cuprite.
- **Coverage**: SimpleCov.
- **Task runner**: Rake tasks or `bin/` scripts.

## Go
- **Build and env**: Go modules (`go mod init <module path>`), Go version in `go.mod` and `toolchain` directive.
- **Lint and format**: golangci-lint, gofmt.
- **Unit**: `go test ./...` with the standard library.
- **E2e**: `go test` with a build tag (`//go:build e2e`) that drives the built binary or HTTP server; Playwright if there is a web UI.
- **Coverage**: `go test -coverprofile=coverage.out ./...` and `go tool cover`.
- **Task runner**: Makefile.

## Rust
- **Build and env**: Cargo, toolchain pinned in `rust-toolchain.toml`.
- **Lint and format**: clippy, rustfmt.
- **Unit**: `cargo test`.
- **E2e**: integration tests in `tests/` with `assert_cmd` for CLIs.
- **Coverage**: cargo-llvm-cov.
- **Task runner**: Makefile or cargo aliases in `.cargo/config.toml`.
