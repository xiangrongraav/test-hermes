#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'Run this script from inside a Git worktree.\n' >&2
  exit 2
}
cd -- "$repo_root"

printf '%s\n' '==> git diff --check'
git diff --check

# `git diff --check` does not include untracked files (including everything in
# this repository's initial, commit-free baseline), so check new text files too.
while IFS= read -r -d '' file; do
  case "$file" in
    .hermes-codex/runs/*) continue ;;
  esac
  if grep -Iq . -- "$file" && grep -nI '[[:blank:]]$' -- "$file"; then
    printf 'Trailing whitespace found in untracked file: %s\n' "$file" >&2
    exit 1
  fi
done < <(git ls-files --others --exclude-standard -z)

if [[ -f package.json ]]; then
  if ! command -v node >/dev/null 2>&1; then
    printf 'package.json exists but node is unavailable.\n' >&2
    exit 127
  fi
  if node -e 'const p=require("./package.json"); process.exit(p.scripts?.test ? 0 : 1)'; then
    printf '%s\n' '==> npm test'
    npm test
  fi
  if node -e 'const p=require("./package.json"); process.exit(p.scripts?.build ? 0 : 1)'; then
    printf '%s\n' '==> npm run build'
    npm run build
  fi
fi

if [[ -f Cargo.toml ]]; then
  printf '%s\n' '==> cargo test --workspace'
  cargo test --workspace
fi

if [[ -f go.mod ]]; then
  printf '%s\n' '==> go test ./...'
  go test ./...
fi

if [[ -f pytest.ini || -f pyproject.toml || -d tests ]]; then
  printf '%s\n' '==> python -m pytest'
  python -m pytest
fi

printf '%s\n' 'Verification passed.'
