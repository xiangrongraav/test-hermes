# Hermes to Codex CLI workflow

## 1. Prepare an isolated task

Create a task file containing the requested outcome, relevant context, constraints, and acceptance criteria. Treat it as plain text; the runner passes it to Codex through standard input and never evaluates it as shell syntax.

Use a dedicated Git branch or linked worktree. For example, create a branch/worktree through Git using the options shown by the installed `git worktree --help`. The runner refuses to run on `main` or `master`. Keep the task file outside generated run logs and omit credentials.

## 2. Run the task

Hermes should turn the request into a plain text task file with acceptance criteria, then call the runner as a local shell command. From any directory, invoke:

```sh
scripts/run-codex-task.sh /path/to/task.txt /path/to/isolated-worktree
```

The script starts `codex exec` in the specified worktree, reads the task from stdin, and records the combined CLI output, final response, and numeric exit code under `.hermes-codex/runs/<task-hash>/`. It holds an atomic lock keyed by task contents and worktree, so concurrent invocations for the same task in that worktree are rejected. The lock is removed when the process exits. If a process is forcibly killed, remove its stale lock directory under `${XDG_RUNTIME_DIR:-/tmp}/hermes-codex-locks/` after confirming that the recorded PID is no longer running.

The runner does not push, merge, deploy, bypass Codex approvals, or read credentials. Codex authentication and any interactive approval remain under the developer's control.

## 3. Verify and recover

In the worktree, run:

```sh
scripts/verify.sh
```

The script stops and returns nonzero on the first failed check. Review the run's `.exit-code` file and log if Codex or verification fails. Correct the task or implementation, then start a new run; do not erase the previous evidence. A failed or interrupted run does not imply that its partial file changes are safe to keep, so inspect `git status` and `git diff` before resuming.

## 4. Human review and optional PR

Inspect the branch diff, generated logs, final response, and verification output. Resolve questions and review all changes yourself. Only after explicit human authorization should a maintainer push the branch. Then, with `gh` authenticated by the human operator, create the PR using the installed CLI's supported options, for example `gh pr create --head <branch> --title "..." --body-file <reviewed-description.md>`. Passing `--head` avoids `gh pr create` prompting to push a branch. This workflow does not invoke `gh` or perform remote Git operations on its own. Never paste tokens, passwords, or credential files into task text or logs.
