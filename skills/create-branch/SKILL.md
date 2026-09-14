---
name: create-branch
description: "Defines branch naming rules for Maarten. Use whenever creating a branch, branching off, running git checkout or switch with a new branch, or before committing work that should not land on the current branch."
---


# Create branch

Guidelines for naming a new git branch.

## Prefix

First inspect the `origin` remote.

- In repositories whose origin is under `github.com/exonet/`, use the mandatory
  `mku/` prefix. Never substitute another set of initials or a generic prefix.
- Outside `exonet/*`, use a Conventional Commits type as the prefix, such as
  `feat/`, `fix/`, `chore/`, `refactor/`, `docs/`, or `test/`.

## Name format

```
<prefix>/<short-kebab-case-description>
```

- Lowercase, words separated by hyphens.
- Short but descriptive of the change.
- When an `exonet/*` repository has a Notion/Jira ticket, include the
  `EXO-XXXX` number right after the prefix, for example
  `mku/EXO-2122-direct-debit-status`.
- Match the repository's existing kebab-case naming style after choosing the
  prefix with the rule above.

## Base branch

Branch off the repo's main branch (usually `master` or `main`) unless told otherwise.
