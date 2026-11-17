# Shared by bin/check-dependencies and bin/dependency-report. The rules they
# apply are in .agents/skills/dependencies/SKILL.md.
#
# Written for bash 3.2 (the macOS default) and jq 1.6, so no associative arrays
# and no jq functions newer than 1.6.
#
# Environment variables used by this repo's tests:
#   DEPS_FIXTURES  directory of saved responses; when set, nothing touches the
#                  network or runs a package manager
#   DEPS_RECORD    directory to save real responses into, to refresh fixtures
#   DEPS_NOW       Unix time to treat as now
#   DEPS_CACHE     cache directory (default .dependency-cache)

DEPS_MIN_AGE_DAYS=3
DEPS_STALE_DAYS=365
DEPS_MIN_HISTORY_DAYS=730
DEPS_MIN_RELEASES=5
DEPS_USER_AGENT="dependency-check (bash script; contact via the project's repository)"
DEPS_ALLOW_FILE=bin/check-dependencies.allow
DEPS_COMMENTS_FILE=package-json-comments.md
DEPS_NPM_REGISTRY=https://registry.npmjs.org
DEPS_NPM_DOWNLOADS=https://api.npmjs.org/downloads/point/last-week
DEPS_PYPI=https://pypi.org/pypi
DEPS_PYPISTATS=https://pypistats.org/api/packages
DEPS_RUBYGEMS=https://rubygems.org/api/v1
DEPS_CRATES=https://crates.io/api/v1
DEPS_GOPROXY=https://proxy.golang.org
DEPS_PKGGODEV=https://pkg.go.dev
DEPS_OSV=https://api.osv.dev/v1
DEPS_GITHUB_API=https://api.github.com

deps_now() { echo "${DEPS_NOW:-$(date +%s)}"; }
deps_cutoff() { echo $(($(deps_now) - DEPS_MIN_AGE_DAYS * 86400)); }
deps_date() { jq -rn --argjson t "$1" '$t | strftime("%Y-%m-%d")'; }
deps_days_ago() { echo $((($(deps_now) - $1) / 86400)); }
deps_commas() { awk '{ n = $1; s = ""; while (length(n) > 3) { s = "," substr(n, length(n) - 2) s; n = substr(n, 1, length(n) - 3) } print n s }' <<<"$1"; }
deps_regex_escape() { sed 's/[][\.*^$+?(){}|/]/\\&/g' <<<"$1"; }

# Works out the package manager from the lockfile in the project root.
# Sets DEPS_PM, DEPS_ECO (the registry), DEPS_MANIFEST and DEPS_LOCK.
deps_detect() {
  DEPS_PM='' DEPS_ECO='' DEPS_MANIFEST='' DEPS_LOCK=''
  if [ -f uv.lock ]; then DEPS_PM=uv DEPS_ECO=pypi DEPS_MANIFEST=pyproject.toml DEPS_LOCK=uv.lock
  elif [ -f pnpm-lock.yaml ]; then DEPS_PM=pnpm DEPS_ECO=npm DEPS_MANIFEST=package.json DEPS_LOCK=pnpm-lock.yaml
  elif [ -f bun.lock ]; then DEPS_PM=bun DEPS_ECO=npm DEPS_MANIFEST=package.json DEPS_LOCK=bun.lock
  elif [ -f bun.lockb ]; then
    echo "bun.lockb is a binary lockfile these scripts cannot read; run 'bun install --save-text-lockfile' to write bun.lock" >&2
    return 1
  elif [ -f package-lock.json ]; then DEPS_PM=npm DEPS_ECO=npm DEPS_MANIFEST=package.json DEPS_LOCK=package-lock.json
  elif [ -f Gemfile.lock ]; then DEPS_PM=bundler DEPS_ECO=rubygems DEPS_MANIFEST=Gemfile DEPS_LOCK=Gemfile.lock
  elif [ -f Cargo.lock ]; then DEPS_PM=cargo DEPS_ECO=crates DEPS_MANIFEST=Cargo.toml DEPS_LOCK=Cargo.lock
  elif [ -f go.mod ]; then DEPS_PM=go DEPS_ECO=go DEPS_MANIFEST=go.mod DEPS_LOCK=go.sum
  else
    echo "No lockfile found (uv.lock, pnpm-lock.yaml, bun.lock, package-lock.json, Gemfile.lock, Cargo.lock or go.mod); install the dependencies first" >&2
    return 1
  fi
}

deps_cache_dir() { echo "${DEPS_CACHE:-.dependency-cache}"; }

deps_key() { printf '%s' "$1" | LC_ALL=C tr -c 'A-Za-z0-9._-' '_' | cut -c1-200; }

# deps_http URL [JSON_BODY] prints the response body.
# Returns 0 on success, 1 when the registry says not found, 2 when unreachable.
deps_http() {
  local url=$1 body=${2:-} key out code token
  key=$(deps_key "$url${body:+ $body}")
  if [ -n "${DEPS_FIXTURES:-}" ]; then
    if [ -f "$DEPS_FIXTURES/http/$key" ]; then cat "$DEPS_FIXTURES/http/$key"; return 0; fi
    [ -f "$DEPS_FIXTURES/http/$key.404" ] && return 1
    return 2
  fi
  out=$(mktemp)
  local args=(-sS -L --max-time 30 -A "$DEPS_USER_AGENT" -o "$out" -w '%{http_code}')
  [ -n "$body" ] && args+=(-X POST -H 'Content-Type: application/json' --data "$body")
  case $url in
    "$DEPS_GITHUB_API"/*)
      token=${GITHUB_TOKEN:-${GH_TOKEN:-}}
      [ -n "$token" ] && args+=(-H "Authorization: Bearer $token")
      ;;
  esac
  if ! code=$(curl "${args[@]}" "$url" 2>/dev/null); then
    rm -f "$out"
    return 2
  fi
  case $code in
    2??) ;;
    404 | 410)
      rm -f "$out"
      [ -n "${DEPS_RECORD:-}" ] && mkdir -p "$DEPS_RECORD/http" && : >"$DEPS_RECORD/http/$key.404"
      return 1
      ;;
    *) rm -f "$out"; return 2 ;;
  esac
  if [ -n "${DEPS_RECORD:-}" ]; then
    mkdir -p "$DEPS_RECORD/http"
    cp "$out" "$DEPS_RECORD/http/$key"
  fi
  cat "$out"
  rm -f "$out"
}

# Runs a package manager command, or replays its saved output under DEPS_FIXTURES.
deps_run() {
  local key
  key=$(deps_key "$*")
  if [ -n "${DEPS_FIXTURES:-}" ]; then
    [ -f "$DEPS_FIXTURES/cmd/$key" ] || return 127
    cat "$DEPS_FIXTURES/cmd/$key"
    return 0
  fi
  if [ -n "${DEPS_RECORD:-}" ]; then
    mkdir -p "$DEPS_RECORD/cmd"
    "$@" | tee "$DEPS_RECORD/cmd/$key"
    return "${PIPESTATUS[0]}"
  fi
  "$@"
}

# Prints the prerelease part of a version, or nothing for a stable release.
deps_prerelease_part() {
  local v=$1 core
  case $DEPS_ECO in
    npm | crates)
      core=${v%%+*}
      [[ $core =~ ^[0-9]+\.[0-9]+\.[0-9]+-(.+)$ ]] && echo "${BASH_REMATCH[1]}"
      ;;
    go)
      # A pseudo-version (vX.Y.Z-<14 digit time>-<12 hex commit>) names an
      # untagged commit. Strip it so only a real tag such as -rc.1 counts.
      core=${v%%+*}
      core=$(sed -E 's/[-.](0\.)?[0-9]{14}-[0-9a-f]{12}$//' <<<"$core")
      [[ $core == *-* ]] && echo "${core#*-}"
      ;;
    pypi)
      core=$(sed -E 's/[.]?post[0-9]*//g' <<<"${v%%+*}")
      [[ $core =~ [a-zA-Z].* ]] && echo "${BASH_REMATCH[0]}"
      ;;
    rubygems)
      [[ $v =~ [a-zA-Z].* ]] && echo "${BASH_REMATCH[0]}"
      ;;
  esac
  return 0
}

# Every installed package from the lockfile as "name version" lines, top level
# copies first. Go adds the publish time as a third field.
deps_installed_all() {
  case $DEPS_PM in
    npm)
      jq -r '.packages | to_entries
        | map(select(.key != "" and (.value.link | not) and .value.version != null
            and ((.value.resolved // "") | startswith("file:") | not)))
        | sort_by(.key | split("node_modules/") | length)[]
        | "\(.key | split("node_modules/") | last) \(.value.version)"' package-lock.json
      ;;
    pnpm)
      awk '
        /^packages:/ { inpk = 1; next }
        /^[a-z]/ { inpk = 0 }
        inpk && /^  [^ ]/ {
          line = $0; sub(/^  /, "", line); sub(/:$/, "", line); gsub(/'\''/, "", line)
          sub(/\(.*$/, "", line)
          at = match(substr(line, 2), /@/)
          if (at == 0) next
          name = substr(line, 1, at); version = substr(line, at + 2)
          if (version ~ /^[0-9]/) print name, version
        }' pnpm-lock.yaml
      ;;
    bun)
      sed -n '/^  "packages": {/,/^  }/p' bun.lock |
        sed -nE 's/^    "[^"]+": \["(@?[^"@]+)@([0-9][^"]*)".*/\1 \2/p' |
        awk '!seen[$0]++'
      ;;
    uv)
      awk '
        /^\[\[package\]\]/ { flush(); name = ""; version = ""; reg = 0; next }
        /^name = / { name = $3; gsub(/"/, "", name) }
        /^version = / { version = $3; gsub(/"/, "", version) }
        /^source = \{ registry/ { reg = 1 }
        function flush() { if (name != "" && reg) print name, version }
        END { flush() }' uv.lock
      ;;
    bundler)
      awk '
        /^GEM$/ { ingem = 1; next }
        /^[A-Z]/ { ingem = 0 }
        ingem && /^    [^ ]/ {
          name = $1; version = $2; gsub(/[()]/, "", version)
          sub(/-(x86|x64|arm|aarch|universal|java|mingw|mswin|darwin|linux|freebsd).*$/, "", version)
          print name, version
        }' Gemfile.lock | awk '!seen[$0]++'
      ;;
    cargo)
      awk '
        /^\[\[package\]\]/ { flush(); name = ""; version = ""; reg = 0; next }
        /^name = / { name = $3; gsub(/"/, "", name) }
        /^version = / { version = $3; gsub(/"/, "", version) }
        /^source = "(registry|sparse)\+https:\/\/(github\.com\/rust-lang\/crates\.io-index|index\.crates\.io)/ { reg = 1 }
        function flush() { if (name != "" && reg) print name, version }
        END { flush() }' Cargo.lock
      ;;
    go)
      deps_run go list -m -f '{{if not .Main}}{{.Path}} {{.Version}} {{with .Time}}{{.Unix}}{{end}}{{end}}' all |
        awk 'NF >= 2'
      ;;
  esac
}

# Names of the direct dependencies, one per line.
deps_direct() {
  case $DEPS_PM in
    npm | pnpm | bun)
      jq -r '[.dependencies, .devDependencies, .optionalDependencies] | map(select(. != null) | keys[]) | unique[]' package.json
      ;;
    uv)
      awk '
        /^\[\[package\]\]/ { root = 0 }
        /^source = \{ (editable|virtual) / { root = 1 }
        root && /\{ name = "/ { s = $0; sub(/.*\{ name = "/, "", s); sub(/".*/, "", s); print s }' uv.lock | sort -u
      ;;
    bundler)
      awk '/^DEPENDENCIES$/ { d = 1; next } /^[A-Z]/ { d = 0 } d && /^  [^ ]/ { n = $1; sub(/!$/, "", n); print n }' Gemfile.lock
      ;;
    cargo)
      # The project's own crates are the ones without a source line.
      awk '
        function flush() { if (name != "" && !src) for (i = 1; i <= nd; i++) print dl[i]; nd = 0; src = 0; name = "" }
        /^\[\[package\]\]/ { flush(); next }
        /^name = / { name = $3 }
        /^source = / { src = 1 }
        /^dependencies = \[/ { indeps = 1; next }
        indeps && /^\]/ { indeps = 0; next }
        indeps { d = $1; gsub(/[",]/, "", d); dl[++nd] = d }
        END { flush() }' Cargo.lock | sort -u
      ;;
    go)
      awk '
        /^require \(/ { b = 1; next }
        b && /^\)/ { b = 0; next }
        b && NF && !/\/\/ indirect/ { print $1 }
        /^require [^(]/ && !/\/\/ indirect/ { print $2 }' go.mod
      ;;
  esac
}

# The installed version of one package: the one the project itself depends on
# where several copies are installed.
deps_installed_version() {
  local name=$1
  case $DEPS_PM in
    pnpm)
      awk -v n="$name" '
        /^importers:/ { imp = 1; next }
        /^[a-z]/ { imp = 0 }
        imp && /^      [^ ]/ { k = $1; sub(/:$/, "", k); gsub(/'\''/, "", k); cur = k; next }
        imp && cur == n && /^        version:/ { v = $2; sub(/\(.*/, "", v); print v; exit }' pnpm-lock.yaml
      ;;
    *) deps_installed_all | awk -v n="$name" '$1 == n { print $2; exit }' ;;
  esac
}

deps_is_direct() { deps_direct | grep -qxF -- "$1"; }

deps_npm_path() { sed 's|/|%2F|' <<<"$1"; }
deps_go_escape() { sed 's/[A-Z]/!&/g' <<<"$1" | tr 'A-Z' 'a-z'; }

# jq definitions shared by the normalizers below. Times become Unix seconds.
DEPS_JQ_DEFS='
def ts: if . == null then null else sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z") | fromdateiso8601 end;
def semverpre: split("+")[0] | test("^[0-9]+\\.[0-9]+\\.[0-9]+-");
def pep440pre: split("+")[0] | gsub("[.]?post[0-9]*"; "") | test("[a-zA-Z]");
def numparts: [scan("[0-9]+") | tonumber];
'

# Fetches a package's release history and prints it in one shape for every
# registry, saving it in the cache:
#   {name, description, repository, maintainers, versions: [{v, t, pre, yanked}]}
# Go is not handled here: the build list already carries publish times.
deps_fetch_package() {
  local name=$1 raw status=0 json cache
  cache="$(deps_cache_dir)/packages/$DEPS_ECO"
  case $DEPS_ECO in
    npm)
      raw=$(deps_http "$DEPS_NPM_REGISTRY/$(deps_npm_path "$name")") || status=$?
      [ $status -eq 0 ] || return $status
      json=$(jq -c "$DEPS_JQ_DEFS"'
        (.time // {}) as $time | {
          name: .name,
          description: (.description // ""),
          repository: ((.repository | if type == "object" then .url elif type == "string" then . else "" end) // ""),
          maintainers: ((.maintainers // []) | length),
          versions: [(.versions // {}) | to_entries[] | {
            v: .key, t: ($time[.key] | ts), pre: (.key | semverpre), yanked: false,
            deprecated: (.value.deprecated // null)
          }]
        }' <<<"$raw")
      ;;
    pypi)
      raw=$(deps_http "$DEPS_PYPI/$name/json") || status=$?
      [ $status -eq 0 ] || return $status
      json=$(jq -c "$DEPS_JQ_DEFS"'
        .info as $i | {
          name: $i.name,
          description: ($i.summary // ""),
          repository: (($i.project_urls // {}) | to_entries
            | map(select(.key | test("source|repo|code"; "i"))) + map(select(.value | test("github\\.com|gitlab\\.com|codeberg\\.org")))
            | .[0].value // $i.home_page // ""),
          maintainers: null,
          versions: [.releases | to_entries[] | select(.value | length > 0) | {
            v: .key, t: (.value | map(.upload_time_iso_8601 | ts) | min), pre: (.key | pep440pre),
            yanked: (.value | all(.yanked))
          }]
        }' <<<"$raw")
      ;;
    rubygems)
      raw=$(deps_http "$DEPS_RUBYGEMS/versions/$name.json") || status=$?
      [ $status -eq 0 ] || return $status
      json=$(jq -c --arg name "$name" "$DEPS_JQ_DEFS"'{
          name: $name, description: "", repository: "", maintainers: null,
          versions: [group_by(.number)[] | {
            v: .[0].number, t: (map(.created_at | ts) | min),
            pre: (.[0].prerelease or (.[0].number | test("[a-zA-Z]"))), yanked: false,
            ruby: .[0].ruby_version
          }]
        }' <<<"$raw")
      ;;
    crates)
      raw=$(deps_http "$DEPS_CRATES/crates/$name") || status=$?
      [ $status -eq 0 ] || return $status
      json=$(jq -c "$DEPS_JQ_DEFS"'{
          name: .crate.name,
          description: (.crate.description // ""),
          repository: (.crate.repository // ""),
          maintainers: null,
          downloads: .crate.recent_downloads,
          versions: [.versions[] | {v: .num, t: (.created_at | ts), pre: (.num | semverpre), yanked: .yanked}]
        }' <<<"$raw")
      ;;
    *) return 1 ;;
  esac
  mkdir -p "$cache"
  printf '%s\n' "$json" >"$cache/$(deps_key "$name").json"
  printf '%s\n' "$json"
}

deps_cached_package() {
  local file
  file="$(deps_cache_dir)/packages/$DEPS_ECO/$(deps_key "$1").json"
  [ -f "$file" ] && cat "$file"
}

# Summarizes a normalized package: the newest stable release, the newest one
# old enough to install, the last and first stable releases, and the count.
deps_summarize() {
  jq -c --argjson cutoff "$(deps_cutoff)" "$DEPS_JQ_DEFS"'
    [.versions[] | select((.pre | not) and (.yanked | not))] as $stable
    | ($stable | map(select(.t != null))) as $dated
    | {
        newest: ($stable | max_by(.v | numparts)),
        eligible: ($dated | map(select(.t <= $cutoff)) | max_by(.v | numparts)),
        last: ($dated | max_by(.t)),
        first: ($dated | min_by(.t)),
        count: ($stable | length)
      }'
}

# Go has no single registry document, so build the same normalized shape from
# the module proxy: every tagged version, with publish times for the newest
# releases (until one is old enough) and the oldest.
deps_go_package() {
  local module=$1 esc list status=0 cutoff info t v fetched=0 origin=''
  esc=$(deps_go_escape "$module")
  list=$(deps_http "$DEPS_GOPROXY/$esc/@v/list") || status=$?
  [ $status -eq 0 ] || return $status
  cutoff=$(deps_cutoff)
  local stable newest_first entries=()
  stable=$(printf '%s\n' "$list" | while read -r v; do
    if [ -n "$v" ] && [ -z "$(DEPS_ECO=go deps_prerelease_part "$v")" ]; then echo "$v"; fi
  done | awk '{ s = $0; sub(/^v/, "", s); split(s, p, "."); printf "%09d%09d%09d %s\n", p[1], p[2], p[3], $0 }' |
    sort | awk '{ print $2 }')
  newest_first=$(sed -n '1!G;h;$p' <<<"$stable")
  for v in $newest_first; do
    info=$(deps_http "$DEPS_GOPROXY/$esc/@v/$v.info") || return $?
    [ -z "$origin" ] && origin=$(jq -r '.Origin.URL // ""' <<<"$info")
    t=$(jq -r "$DEPS_JQ_DEFS"'.Time | ts' <<<"$info")
    entries+=("{\"v\":\"$v\",\"t\":$t,\"pre\":false,\"yanked\":false}")
    fetched=$((fetched + 1))
    if [ "$t" -le "$cutoff" ] || [ $fetched -ge 5 ]; then break; fi
  done
  local oldest
  oldest=$(head -1 <<<"$stable")
  if [ -n "$oldest" ] && ! printf '%s\n' ${entries[@]+"${entries[@]}"} | grep -qF "\"v\":\"$oldest\""; then
    info=$(deps_http "$DEPS_GOPROXY/$esc/@v/$oldest.info") || return $?
    t=$(jq -r "$DEPS_JQ_DEFS"'.Time | ts' <<<"$info")
    entries+=("{\"v\":\"$oldest\",\"t\":$t,\"pre\":false,\"yanked\":false}")
  fi
  for v in $stable; do
    printf '%s\n' ${entries[@]+"${entries[@]}"} | grep -qF "\"v\":\"$v\"" || entries+=("{\"v\":\"$v\",\"t\":null,\"pre\":false,\"yanked\":false}")
  done
  printf '%s\n' ${entries[@]+"${entries[@]}"} | jq -sc --arg name "$module" --arg origin "$origin" \
    '{name: $name, description: "", repository: (if $origin != "" then $origin elif ($name | startswith("github.com/")) then "https://" + $name else "" end), maintainers: null, versions: .}'
}

# A package's normalized history, from the registry (for Go, the proxy).
deps_package() {
  if [ "$DEPS_ECO" = go ]; then deps_go_package "$1"; else deps_fetch_package "$1"; fi
}

# The reason given in a "finished library" note for a package, if there is one.
# Manifests that allow comments hold the note beside the dependency, written as
# "finished library: <name>, <reason>". package.json cannot hold comments, so
# its notes live in package-json-comments.md as
# "- `<name>` (line <n>): finished library: <reason>".
deps_finished_note() {
  local name=$1 esc
  esc=$(deps_regex_escape "$name")
  case $DEPS_PM in
    npm | pnpm | bun)
      [ -f "$DEPS_COMMENTS_FILE" ] || return 0
      { grep -E "^- \`$esc\`.*finished library:" "$DEPS_COMMENTS_FILE" || true; } | head -1 | sed 's/.*finished library:[[:space:]]*//'
      ;;
    *)
      { grep -E "finished library: $esc(,|[[:space:]]|$)" "$DEPS_MANIFEST" || true; } | head -1 |
        sed -E "s/.*finished library: $esc,?[[:space:]]*//"
      ;;
  esac
}

# The owner of a GitHub repository and whether it is an organization.
# Prints "Organization <owner>", "User <owner>", or nothing.
deps_github_owner() {
  local repo=$1 owner info
  [[ $repo =~ github\.com[/:]([^/]+)/ ]] || return 0
  owner=${BASH_REMATCH[1]}
  info=$(deps_http "$DEPS_GITHUB_API/users/$owner") || return 0
  echo "$(jq -r '.type // ""' <<<"$info") $owner"
}

# True when version $1 is higher than version $2, comparing the numbers in each.
deps_version_gt() {
  jq -en --arg a "$1" --arg b "$2" "$DEPS_JQ_DEFS"'($a | numparts) > ($b | numparts)' >/dev/null
}
