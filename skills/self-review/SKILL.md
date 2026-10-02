---
name: self-review
description: "Reviews Codex's own current-task changes before handoff by applying the code-review-and-quality and code-simplification skills, reporting prioritized findings, and asking the user which findings to fix. Use when the user asks for a self-review, asks Codex to review or check its own work, or when Codex needs a final review of changes it just made."
---

# Self Review

Review the work produced for the current user request without changing it. Use
the existing review skills as the source of review criteria, then give control
back to the user before applying any fixes.

## Workflow

### 1. Establish the review scope

- Read the current request, acceptance criteria, repository instructions, and
  relevant design or task context.
- Inspect staged, unstaged, and untracked changes. Include new files in the
  review; do not rely on `git diff` alone.
- Review only changes made for the current request. Identify pre-existing user
  changes as out of scope and do not modify them.
- If the intended behavior or ownership of overlapping changes cannot be
  determined safely, ask one focused question before continuing.

### 2. Gather verification evidence

- Review relevant tests before implementation code where tests exist.
- Run the narrowest relevant tests, linters, type checks, syntax checks, or
  builds that have not already been run against the current version.
- Do not run auto-fix commands or edit, stage, commit, push, or otherwise
  mutate the reviewed work.
- Record commands that passed, failed, or could not be run. Do not treat a
  passing check as proof that the change is free of review findings.

### 3. Apply both review skills

Load and follow these skills completely, in this order:

1. `code-review-and-quality` — review correctness, readability, architecture,
   security, performance, tests, and the verification story.
2. `code-simplification` — make a second, behavior-preserving pass for
   unnecessary complexity, duplication, poor naming, avoidable indirection,
   and clearer project-idiomatic structure.

Do not implement simplifications during this pass. Report them as findings.
Deduplicate overlapping observations and keep the higher severity. If either
required skill is unavailable, say which one was unavailable and do not claim
that its pass was completed.

### 4. Report findings

Lead with findings, ordered by severity and then impact. Use the severity
language from `code-review-and-quality`: `Critical`, `Required`, `Optional`, or
`Nit`.

For each finding, include:

- a stable number so the user can select it;
- the file and tightest useful line reference;
- the problem and its concrete impact;
- the recommended fix;
- whether it came from the quality pass, simplification pass, or both.

After the findings, summarize verification evidence and any residual risks or
untested areas. If there are no findings, say so explicitly; do not invent nits
to make the review look useful.

### 5. Stop and ask what to fix

End by asking which findings the user wants fixed. Offer concise choices such
as `all`, `required only`, finding numbers, or `none`. Do not begin fixing
anything in the same turn, even when the preferred fix seems obvious.

When the user chooses, fix only the selected findings, rerun affected checks,
and report the result. Preserve unrelated and pre-existing changes throughout.
