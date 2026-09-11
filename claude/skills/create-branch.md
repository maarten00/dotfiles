---

name: create-branch

description: "Rules for creating a git branch for Maarten. Load this whenever you are about to create a new branch — e.g. 'work on a separate branch', 'branch off', 'git checkout -b', or before committing changes that shouldn't land on the main branch. Defines the mandatory branch-name prefix."

---


# Create branch

Guidelines for naming a new git branch.

## Prefix — mandatory

Every branch Maarten works on is prefixed with `mku/`. Never create a branch without it (not `feature/`, not the git user's initials, not a bare name).

## Name format

```
mku/<short-kebab-case-description>
```

- Lowercase, words separated by hyphens.
- Short but descriptive of the change.
- When there's a Notion/Jira ticket, include the `EXO-XXXX` number right after the prefix, e.g. `mku/EXO-2122-direct-debit-status`.
- Match the style of existing branches in the repo (`<prefix>/<kebab-description>`), only ever swapping in the `mku/` prefix.

## Base branch

Branch off the repo's main branch (usually `master` or `main`) unless told otherwise.
