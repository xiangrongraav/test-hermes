---
name: development-workflow
description: Coordinate Hermes-to-Codex implementation tasks in an isolated Git worktree, inspect results, verify changes, and manage authorized PR handoff.
metadata:
  hermes:
    tags: [development, codex, git, verification]
    category: software-development
---

# Development workflow: Hermes and Codex CLI

Use this workflow when Hermes should hand implementation work to Codex through a repository's `scripts/run-codex-task.sh` and `scripts/verify.sh`.

## Before starting

1. Resolve the target repository and read its top-level `AGENTS.md`, plus any nested `AGENTS.md` files relevant to the requested files. Read `scripts/agent-workflow.md` or equivalent workflow documentation when present.
2. Turn the user request into a concise task brief with scope, constraints, and observable acceptance conditions. Preserve the user's exact authorization boundary for remote operations.
3. Check `git status`, the current branch, and whether `HEAD` is a commit. Do not move, stash, or overwrite user changes. If the repository cannot support an independent worktree, stop and explain what is missing.
4. Create a uniquely named branch and worktree from the agreed base commit. Use an absolute worktree path, confirm it with `pwd -P` and `git worktree list`, and record it. Keep the task brief and persistent task record outside the Codex worktree.
5. Confirm that the worktree contains the required runner and verifier. Check their usage and the installed CLI help before relying on any flags; do not invent CLI options.

## Handoff and implementation

Create a persistent task record under the repository's `.hermes-codex/task-records/` directory, outside the active worktree. Include the task, acceptance conditions, current phase, branch, absolute worktree path, base commit, verification state, and PR URL or `none`. Update it at each phase boundary.

Write the task brief to a plain-text file outside the Codex worktree, then invoke the repository's `scripts/run-codex-task.sh` with the absolute task-file and worktree paths. Capture the runner's output and record its run-log, final-response, and exit-code paths.

While Codex is running, do not edit, format, generate, or otherwise mutate files in its worktree. Read-only process/status checks are allowed. Do not start a second Codex run against the same task and worktree while one is active.

If the runner exits nonzero, preserve its logs, record the failure, and stop for human input. Do not claim implementation succeeded.

## Review and independent verification

After Codex exits:

1. Read the complete relevant branch diff and inspect untracked files; do not rely on a summary alone.
2. Read the Codex run log and final response. Check that the changed files satisfy the acceptance conditions and do not include unrelated or sensitive data.
3. Independently run the worktree's `scripts/verify.sh` and retain its full result. Do not treat a Codex-reported test result as independent verification.
4. Update the persistent record with the review and verification outcome.

If verification fails, give Codex a new repair task containing the exact failing command and diagnostic, along with the original acceptance conditions. Reuse the same branch and worktree. Do not edit the worktree yourself while Codex is fixing it. After each repair run, repeat the diff/log/final-output review and independently rerun verification. Allow at most two automatic repair rounds after the initial implementation. If verification still fails, record the concrete blocker, set the phase to `blocked`, and stop without claiming completion.

## Push and pull request

Pushing and creating a PR are separate remote actions. Do either only when the user has explicitly authorized that action for the current task; general workflow preferences or authorization from an unrelated task do not count. Before acting, confirm verification passed and review the exact branch diff. Check the installed `git` and `gh` help for supported arguments. Never merge or deploy automatically.

When no current-task authorization exists, leave the branch local and set the record's PR URL to `none`. When authorized and the user has completed any required login, push only the task branch and create the PR. Store its URL in the persistent task record. Do not expose or copy credentials into task files, logs, shell arguments, or the record.

## Persistent task record

Keep one record per task outside the Codex worktree. At minimum, preserve:

```text
Task and acceptance conditions:
Current phase:
Branch:
Base commit:
Absolute worktree path:
Codex runs (log, final response, exit code):
Diff review:
Verification command and result:
Repair rounds used (0-2):
Blocker, if any:
Push authorization/result:
PR authorization/result/URL:
```

Use phases such as `preparing`, `codex-running`, `reviewing`, `verifying`, `repairing`, `blocked`, `ready-for-review`, and `pr-open`. Report completion only after the acceptance conditions and independent verification pass; a PR is complete only when its URL has been recorded.
