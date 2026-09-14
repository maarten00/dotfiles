# Portable Agent Skills Tasks

## Task 1: Convert skills to the standard directory format

**Description:** Move each tracked flat Claude skill into
`skills/<skill-name>/SKILL.md` without changing its intended behavior.

**Acceptance criteria:**

- [x] All four skills have valid `name` and `description` frontmatter.
- [x] No duplicate flat source remains under `claude/skills/`.
- [x] The user’s current uncommitted edits are preserved exactly through the move.

**Verification:**

- [x] The cached `skills` CLI discovers all four names from the dotfiles root.
- [x] Review the move diff for content loss.

**Dependencies:** None

**Files likely touched:** `claude/skills/*.md`, `skills/*/SKILL.md`

**Estimated scope:** Medium (4 moved files)

## Task 2: Make shared skill content harness-neutral

**Description:** Reconcile conflicting branch rules and qualify or replace
Claude-specific tools, model names, and attribution while preserving the desired
workflow.

**Acceptance criteria:**

- [x] Branch naming matches the current `exonet/*` rule.
- [x] Skills do not require Claude-only tool names when an equivalent capability exists.
- [x] PR and review attribution is truthful for every target harness.

**Verification:**

- [x] Manual review of each skill against Claude Code and Codex capabilities.
- [x] Search finds no unintended mandatory Claude-only terms.

**Dependencies:** Task 1

**Files likely touched:** `skills/*/SKILL.md`

**Estimated scope:** Medium (4 files)

## Task 3: Declare the external skill pack

**Description:** Add a tracked, human-readable external source manifest that
declares `addyosmani/agent-skills` as a whole-repository dependency without
copying its 25 skills into these dotfiles.

**Acceptance criteria:**

- [x] `agent-skills.sources` lists `addyosmani/agent-skills` once.
- [x] The format supports adding another whole-repository source later.
- [x] Normal syncs follow upstream latest; `--local` and `--offline` skip
      external updates when desired.

**Verification:**

- [x] The sync wrapper can parse the manifest without `jq` or another new runtime.
- [ ] `npx skills add addyosmani/agent-skills --list` discovers the upstream pack.

**Dependencies:** None

**Files likely touched:** `agent-skills.sources`

**Estimated scope:** Small (1 file)

## Task 4: Add the multi-agent sync wrapper

**Description:** Add a POSIX shell entry point that invokes a pinned `skills`
CLI version for an explicit list of global agent targets while preserving local
unmanaged skills. Default mode installs authored skills and every source in
`agent-skills.sources`; `--local` and `--offline` exclude third-party sources.

**Acceptance criteria:**

- [x] Defaults target Claude Code and Codex and can be extended deliberately.
- [x] Third-party installation stays interactive so collisions are surfaced.
- [x] Repeated runs are idempotent.
- [x] `--local` and `--offline` perform no external source fetch.
- [x] Default mode requests all 25 Addy Osmani skills rather than isolated copies.

**Verification:**

- [x] `sh -n scripts/sync-agent-skills.sh` passes.
- [x] Run twice with an isolated temporary agent home and compare results.

**Dependencies:** Tasks 1, 2, and 3

**Files likely touched:** `scripts/sync-agent-skills.sh`

**Estimated scope:** Small (1 file)

## Task 5: Integrate bootstrap and update hooks

**Description:** Replace Claude-only linking calls with the shared wrapper.

**Acceptance criteria:**

- [x] `fresh.sh`, `post-merge`, and `post-rewrite` call the shared sync path.
- [x] `fresh.sh` installs declared external packs; git hooks use offline local-only mode.
- [x] Hook failure behavior is explicit and does not break unrelated git work.
- [x] Existing setup remains safe on machines that have not migrated yet.

**Verification:**

- [x] `sh -n fresh.sh scripts/sync-agent-skills.sh git-hooks/post-merge git-hooks/post-rewrite` passes.
- [x] Exercise each hook against an isolated agent home.

**Dependencies:** Task 4

**Files likely touched:** `fresh.sh`, `git-hooks/post-merge`,
`git-hooks/post-rewrite`

**Estimated scope:** Medium (4 files)

## Checkpoint: End-to-end installation

- [x] A temporary project gets all four skills in Claude Code and Codex locations.
- [ ] The same HOME gets the complete Addy Osmani skill pack.
- [x] An unrelated pre-existing local skill is unchanged.
- [x] Installer invocations refresh both harnesses after a source change.

## Task 6: Document authoring and installation

**Description:** Update the README with the canonical edit location, supported
targets, manual sync command, bootstrap behavior, and safe migration notes.

**Acceptance criteria:**

- [x] Documentation distinguishes source files from generated links/copies.
- [x] Adding a new skill is a short, repeatable procedure.
- [x] Optional additional harnesses are documented without enabling all of them.
- [x] External pack installation, updates, provenance, and pinning policy are documented.

**Verification:**

- [ ] Follow the complete fresh-machine README flow on macOS.
- [x] Final diff contains no unrelated changes.

**Dependencies:** Task 5

**Files likely touched:** `README.md`

**Estimated scope:** Small (1 file)

## Checkpoint: Complete

- [x] All focused checks pass.
- [x] Claude Code and Codex discover the same four authored skills.
- [ ] Claude Code and Codex discover the declared Addy Osmani pack.
- [x] The migration is reversible by restoring the old link script and paths.
