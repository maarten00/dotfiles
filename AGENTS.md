# AGENTS.md

## Scope
- These instructions apply to the entire `/Users/maarten/.dotfiles` tree unless a deeper `AGENTS.md` overrides them.

## Goals
- Keep changes minimal, reversible, and aligned with existing dotfile patterns.
- Prefer portability across macOS, Linux, and shell environments when practical.
- Preserve user-specific behavior unless the task explicitly asks to change it.

## Editing Rules
- Match the style and structure already used in nearby files.
- Do not rename or reorganize files unless the task requires it.
- Avoid adding new dependencies or bootstrap steps unless clearly necessary.
- Prefer small, targeted diffs over sweeping refactors.

## Shell And Script Conventions
- Assume `zsh` is the primary interactive shell unless a file clearly targets another shell.
- Keep scripts POSIX-compatible when feasible; if a script requires `zsh` or `bash`, keep that explicit.
- Quote paths and variables defensively.
- Avoid destructive commands in scripts unless explicitly requested and clearly documented.

## Dotfiles Safety
- Do not embed secrets, tokens, private keys, or machine-specific credentials.
- Treat host-specific settings as opt-in and easy to disable.
- Prefer feature detection over hard-coded machine assumptions.

## Validation
- When changing shell config, validate with a non-interactive syntax check when possible.
- When changing tool configs, run the narrowest relevant validation command available.
- If a change cannot be validated locally, state that clearly in the handoff.

## Documentation
- Update nearby docs or comments when behavior changes in a non-obvious way.
- Keep instructions concise and operational.
