#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  printf 'Usage: %s TASK_FILE WORKTREE_DIR\n' "${0##*/}" >&2
}

if [[ $# -ne 2 ]]; then
  usage
  exit 2
fi

task_file=$1
worktree_dir=$2

if [[ ! -f "$task_file" || ! -r "$task_file" ]]; then
  printf 'Task file is not a readable regular file: %s\n' "$task_file" >&2
  exit 2
fi
if [[ ! -d "$worktree_dir" ]]; then
  printf 'Worktree directory does not exist: %s\n' "$worktree_dir" >&2
  exit 2
fi

task_file=$(cd -- "$(dirname -- "$task_file")" && printf '%s/%s' "$PWD" "$(basename -- "$task_file")")
worktree_dir=$(cd -- "$worktree_dir" && pwd -P)

if ! git -C "$worktree_dir" rev-parse --show-toplevel >/dev/null 2>&1; then
  printf 'Work directory is not inside a Git repository: %s\n' "$worktree_dir" >&2
  exit 2
fi
repo_root=$(git -C "$worktree_dir" rev-parse --show-toplevel)
branch=$(git -C "$worktree_dir" branch --show-current)
if [[ "$branch" == main || "$branch" == master ]]; then
  printf 'Refusing the primary branch. Use a dedicated branch or linked worktree.\n' >&2
  exit 2
fi

if ! command -v codex >/dev/null 2>&1; then
  printf 'codex CLI was not found on PATH.\n' >&2
  exit 127
fi
if ! command -v sha256sum >/dev/null 2>&1; then
  printf 'sha256sum is required to create a stable per-task lock.\n' >&2
  exit 127
fi

task_hash=$({ printf '%s\n' "$worktree_dir"; cat -- "$task_file"; } | sha256sum | cut -d ' ' -f 1)
lock_root=${XDG_RUNTIME_DIR:-/tmp}/hermes-codex-locks
mkdir -p -- "$lock_root"
lock_dir=$lock_root/$task_hash.lock
if ! mkdir -- "$lock_dir" 2>/dev/null; then
  printf 'This task is already running (lock: %s).\n' "$lock_dir" >&2
  exit 1
fi
printf '%s\n' "$$" > "$lock_dir/pid"
cleanup() { rm -rf -- "$lock_dir"; }
trap cleanup EXIT

run_root=$repo_root/.hermes-codex/runs/$task_hash
mkdir -p -- "$run_root"
stamp=$(date -u +%Y%m%dT%H%M%SZ)
run_id=$stamp-$$
log_file=$run_root/$run_id.log
final_file=$run_root/$run_id.final.txt
meta_file=$run_root/$run_id.exit-code

printf 'Running task in %s (branch: %s)\n' "$worktree_dir" "$branch"
printf 'Run log: %s\nFinal response: %s\n' "$log_file" "$final_file"

set +e
codex exec -C "$worktree_dir" --output-last-message "$final_file" - \
  < "$task_file" > "$log_file" 2>&1
codex_status=$?
set -e
printf '%s\n' "$codex_status" > "$meta_file"

if [[ $codex_status -ne 0 ]]; then
  printf 'Codex exited with status %s. See %s\n' "$codex_status" "$log_file" >&2
  exit "$codex_status"
fi
printf 'Codex completed successfully (exit %s).\n' "$codex_status"
