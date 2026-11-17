# The checks of step 2

Every subagent of step 2 reads "For every subagent" and its own sections below before it starts.
The main session names the sections in the prompt and does not paste this text.

## For every subagent

- File contents come from git, never from the working tree: the PR's version from
  `git show <head>:<path>`, the version before it from `git show origin/<base>:<path>`. The diff is
  `git diff origin/<base>...<head>`. `<head>` is the SHA the prompt gives, not a branch name.
- Do all work inline. Spawn no subagents of your own.
- When the prompt lists risk-trigger hits, look hardest where they point. The "Why" next to each
  hit says what can go wrong there.

## For every finder

Surface up to 8 candidates, each with `file`, `line`, a one-line summary and a concrete failure
scenario: the input or state that triggers it and what goes wrong. For a cleanup, altitude or
conventions candidate the failure scenario is the concrete cost instead: what is duplicated,
wasted or harder to maintain, or which rule is broken.

Pass every candidate with a nameable failure scenario through. Dropping a half-believed candidate
skips the verify step, and that is the main cause of misses. Do not filter for "worth flagging",
the main session does that later. Another check flagging the same line for a different reason does
not make yours redundant.

## A. Line by line

Read every hunk line by line, then the enclosing function of each hunk in the head version. Bugs in
unchanged lines of a touched function are in scope when the PR re-exposes them or should have fixed
them. For every line ask what input, state, timing or platform makes it wrong: inverted or wrong
conditions, off-by-one, a null dereference, a falsy `0` or `"0"` treated as missing, a copy-paste
with the wrong variable, an error swallowed in a catch, unescaped regex characters.

## B. Removed behaviour

For every line the diff deletes or replaces, name the invariant or behaviour it enforced, then find
where the new code re-establishes it. When it cannot be found, that is a candidate: a removed guard,
a dropped error path, a narrowed validation, a deleted test that covered a real case.

## C. Callers and callees

For each function the diff changes, find its callers and check whether the change breaks a call
site: a new precondition, a changed return shape, a new exception, an ordering dependency. Check
the callees too: does a parallel change in the same PR make a call unsafe?

## D. Language and framework pitfalls

The classic pitfalls of the diff's language and framework. For PHP and Laravel, for example: loose
comparison and type juggling, `empty()` on a value that can be `0`, a query per loop iteration,
mass assignment, raw SQL with interpolated input (`whereRaw`, `DB::raw`), timezone and DST drift,
float equality. For JS: `==` coercion and a closure that captures the loop variable. Flag every
instance the diff introduces.

## E. Wrappers and proxies

When the PR adds or changes a type that wraps another (a cache, a proxy, a decorator, an adapter):
check that every method routes to the wrapped instance and not back through a registry, the
container or a facade, which re-enters the wrapper or recurses. Check that the wrapper forwards
every method its callers use.

## F. Reuse

New code that duplicates what the codebase already has. Search shared and utility code and the
files next to the change, and name the existing helper to call instead.

## G. Simplification

Complexity the diff adds without need: redundant or derivable state, copy-paste with small
variations, deep nesting, dead code left behind. Name the simpler form.

## H. Efficiency

Wasted work the diff adds: repeated computation or I/O, independent operations run one after
another, blocking work added to boot or to a hot path, a long-lived object that keeps a large
captured scope alive. Name the cheaper form.

## I. Altitude

Does each change fix the root cause at the right depth, or patch a symptom? Special cases layered
on shared infrastructure are a sign the fix is not deep enough. Name the simpler, more general
change to the underlying mechanism.

## J. Conventions

Read the guideline files that govern the changed code, as they stand on the base: `CLAUDE.md` and
`AGENTS.md` at the repo root and in every ancestor directory of a changed file, and the repo's own
rule files that cover the changed code, such as `.ai/guidelines/` and `.ai/skills/*/rules/` in
exonet/backend, or `.ai/rules/` where that exists. Flag a violation only when you can quote the
exact rule and the exact line that breaks it, and name the file the rule comes from. No style
preferences, no "spirit of the doc". These files guide an agent that writes code, so not every
instruction applies to a review. The module layout counts as a convention too.

## K. History

The git history and blame of the touched lines, review comments on earlier PRs that touched these
files, and the guidance in existing code comments of the changed files that the change has to
respect.

## Verifier

You get 2 to 4 candidates. For every candidate return exactly one of:

- **CONFIRMED.** You can name the input or state that triggers it and the wrong outcome. Quote the
  line.
- **PLAUSIBLE.** The mechanism is real, the trigger is uncertain (timing, environment, config). Say
  what would confirm it.
- **REFUTED.** Factually wrong (the code does not say that) or guarded elsewhere. Quote the line
  that proves it.

PLAUSIBLE is the default. Do not refute a candidate for being speculative or for depending on
runtime state when that state is realistic: a race, null on a rare but reachable path (an error
handler, a cold cache, a missing optional field), a falsy zero, an off-by-one on a boundary the code
does not exclude, retry storms and partial failures, a regex or allowlist that lost an anchor.
REFUTED only when it can be built from the code: wrong (quote the line), provably impossible (a
type, a constant, an invariant), already handled in this diff (cite the guard), or pure style with
no observable effect.

Settle a candidate by reading first: the line, its callers, the framework code in `vendor/`. Run
code only when reading cannot settle it, for example when the outcome depends on middleware and
validation working together. A scratch test that repeats what the source already shows costs
minutes and proves nothing new.

## Sweep

You are a fresh reviewer and you get the verified list. Re-read the diff and the enclosing
functions looking only for defects that are not on the list yet. Focus on what the first pass tends
to miss: moved or extracted code that dropped a guard or an anchor, second-tier traps (a default
evaluated once, non-deterministic hashing, a lock scope that shrank, a predicate method with side
effects), setup and teardown that do not mirror each other in tests, and config defaults that
flipped. Up to 8 extra candidates, in the shape of "For every finder". When there is nothing new,
return nothing. No padding.
