# Repository guide

## Project structure

This repository has no application code yet. It contains local agent workflow support; add future application code under its natural top-level directories and document new build or test entry points here.

- `scripts/` contains local development and verification helpers.
- `docs/` contains workflow and maintenance documentation.
- `skills/` contains source copies of Hermes skills installed for this workflow.

## Development rules

- Keep changes focused and explain behavior changes in the task handoff.
- Do not put credentials, access tokens, or private configuration in the repository, task files, or logs.
- Run `scripts/verify.sh` from the target worktree before handing work to a reviewer.
- Keep generated output out of source directories unless the project requires it.

## Verification and build

Run `scripts/verify.sh`. It always runs `git diff --check` and, when matching project manifests are present, runs the repository's conventional checks:

- `npm test` and `npm run build` when those scripts exist in `package.json`.
- `python -m pytest` when a `pytest.ini`, `pyproject.toml`, or `tests/` directory exists.
- `cargo test --workspace` when `Cargo.toml` exists.
- `go test ./...` when `go.mod` exists.

There are no application manifests or project-specific build commands yet, so the current baseline is `git diff --check` plus whitespace checks for new text files.
