# Implementation Plan: Portable Agent Skills

## Overview

Move the four personal skills out of the Claude-specific flat-file layout and
make them standard Agent Skills, then install them globally for selected agent
harnesses from one command. Also declare Addy Osmani's `agent-skills` pack as an
external source managed by these dotfiles. Keep this repository as the authored
source for personal skills and preserve machine-local skills that are not
managed by it.

## Recommendation

Use the open Agent Skills directory format plus Vercel's `skills` CLI as the
multi-agent installer:

```text
~/.dotfiles/skills/<skill-name>/SKILL.md   authored source
                    |
                    | scripts/sync-agent-skills.sh
                    v
~/.agents/skills/<skill-name>/             installer-managed canonical copy
                    |
                    +--> ~/.claude/skills/<skill-name>
                    +--> ~/.codex/skills/<skill-name>
                    +--> other selected harness locations

~/.dotfiles/agent-skills.sources           declared external packs
                    |
                    +--> addyosmani/agent-skills (all 25 skills)
```

The CLI already accepts local paths, supports global installation, supports
Claude Code, Codex, Cursor, Gemini CLI, GitHub Copilot, OpenCode, and many other
harnesses, and recommends symlinks from agent-specific locations to its
canonical copy. This avoids maintaining an agent-path matrix in these dotfiles.

Laravel Boost is the right analogy, but not the reusable package for this job:
its `.ai/skills/` source and `boost:update` fan-out are Laravel application
features. The generic equivalent is the Agent Skills format plus the `skills`
CLI.

The external pack should be referenced declaratively rather than copied into
the dotfiles repository. A small tracked `agent-skills.sources` file will list
one whole-repository source per line, initially:

```text
addyosmani/agent-skills
```

The sync wrapper installs local authored skills and declared external packs by
default. A `--local` flag excludes external packs, while git hooks use strict
offline local-only mode so a normal pull does not unexpectedly require network
access or change third-party content.

Official references:

- https://agentskills.io/specification
- https://github.com/vercel-labs/skills
- https://github.com/addyosmani/agent-skills
- https://laravel.com/docs/boost#custom-skills

## Architecture Decisions

- Use `skills/<name>/SKILL.md` as the repository source. This is directly
  discoverable by the `skills` CLI and follows the open specification.
- Keep `claude/CLAUDE.md` Claude-specific for now. Always-loaded global
  instruction files are not standardized like skills and should be handled as
  a separate follow-up if cross-agent guidelines are desired.
- Add one POSIX `scripts/sync-agent-skills.sh` wrapper around `npx skills add`.
  It holds the selected agent list and gives `fresh.sh` and git hooks one stable
  entry point even if the CLI invocation changes.
- Track third-party intent in `agent-skills.sources`, not by committing upstream
  skill contents. Install all 25 Addy Osmani skills together rather than keeping
  a list of individually copied skills. The generic installer does not guarantee
  access to the upstream repository-level supplementary references; native
  whole-repository plugins remain an optional follow-up for that material.
- Follow the pack's latest default branch whenever the wrapper runs normally.
  A `--local` flag excludes third-party sources when desired, and git hooks use
  `--offline` so normal Git operations never trigger an implicit upgrade.
- Make local plus external sources the wrapper default. Use `--local` to skip
  external sources and `--offline` for a cache-only local refresh.
- Start with explicitly selected global targets rather than `--agent '*'`.
  Installing files for dozens of unused harnesses creates noise. Suggested
  initial targets: `claude-code` and `codex`; add Cursor, Gemini CLI, Copilot,
  or OpenCode when they are actually used.
- Let the CLI use its recommended canonical-copy-plus-symlink mode. Edits still
  happen in the dotfiles source; rerunning the sync wrapper refreshes the
  installer-managed copy. Do not edit `~/.agents/skills` directly.
- Pin the CLI version in the wrapper or a small package manifest after verifying
  the version during implementation. A floating `npx skills` invocation makes
  bootstrap behavior non-reproducible.
- Preserve local unmanaged skills. The sync command may replace the four named
  managed skills and declared third-party skills, but migration cleanup must
  only remove old symlinks that point into this dotfiles repository or entries
  recorded as managed by the installer.
- Detect name collisions across personal skills, external packs, and unmanaged
  local skills before installation. Local authored skills are explicitly
  managed; third-party installs remain interactive so the installer can surface
  an existing same-named entry rather than silently replacing one.

## Portability Audit Required

- Convert each flat Markdown file to a directory containing `SKILL.md` and
  validate its YAML frontmatter.
- Reconcile `create-branch`: it currently says every branch uses `mku/`, while
  `claude/CLAUDE.md` now limits that prefix to `exonet/*` repositories.
- Replace or qualify Claude-only concepts in `design-first`, including the
  `Agent` tool, TaskList/TaskStop, and Opus/Sonnet model selection.
- Make the PR attribution truthful across harnesses. A Codex-authored PR should
  not claim it was generated by Claude; use agent-neutral wording or document a
  deliberate Claude-only exception.
- Treat optional integrations such as `notion-fetch` as capabilities: use them
  when available and fall back to asking for the ticket identifier.

## Task List

### Phase 1: Standardize the source

- [x] Task 1: Convert all four skills to `skills/<name>/SKILL.md`.
- [x] Task 2: Audit and revise harness-specific instructions for portability.

### Checkpoint: Portable source

- [x] Every skill passes an Agent Skills format check and remains usable in
      Claude Code.

### Phase 2: Add multi-agent installation

- [x] Task 3: Declare Addy Osmani's repository as a managed external pack.
- [x] Task 4: Add and validate the pinned sync wrapper for chosen agents.
- [x] Task 5: Route fresh-machine setup and git hooks through the wrapper.

### Checkpoint: Installation

- [x] A clean temporary project receives working Claude Code and Codex skill links
      without deleting an unrelated local skill.

### Phase 3: Document and migrate

- [x] Task 6: Update setup documentation and remove only superseded managed
      links/files.

### Checkpoint: Complete

- [x] Setup is idempotent, shell syntax checks pass, and the four skills are
      discoverable by both selected harnesses.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| A CLI update changes paths or behavior | Medium | Pin its version and test the wrapper in a temporary HOME |
| Local source is copied before being linked | Low | Document dotfiles as the edit location and sync after pulls |
| A target harness ignores unsupported frontmatter/features | Medium | Keep shared frontmatter to `name` and `description`; test discovery in each selected harness |
| Migration overwrites a machine-local skill with the same name | High | Detect collisions and stop unless the existing item is a dotfiles-managed symlink |
| Git hooks need network access to run `npx` | Medium | Ensure the pinned CLI is already available, or make hook sync best-effort with a clear manual command |
| Upstream external skills change unexpectedly | Medium | Separate install/update commands, show the source being updated, and document how to inspect the diff/version before updating |
| The generic installer omits upstream repository-level references | Medium | Document that the core skills still work and use a native whole-repository plugin later if those supplementary checklists are needed |

## Open Questions

- Which harnesses beyond Claude Code and Codex should be in the default target
  list?
- Should generated PR text say “AI-generated” everywhere, or should each
  harness get its own attribution?
- Do you also want a later pass that makes the always-loaded rules in
  `claude/CLAUDE.md` portable to `AGENTS.md`, Gemini, Cursor, and other formats?
