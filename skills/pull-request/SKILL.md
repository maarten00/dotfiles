---
name: pull-request
description: "Rules for writing a GitHub pull request: discover and preserve the repository-specific PR template, then write a concise title and body using the repository's conventions. Load this whenever you are about to draft, open, or update a PR — e.g. 'open a PR', 'gh pr create', 'write the PR description', 'update the pull request body'. These rules govern the PR title and body text only; they do NOT change the language of normal chat replies."
---


# Pull request

Guidelines for writing the title and body of a GitHub pull request. These rules govern the PR text only; they must not change the language of ordinary chat responses.

## Ticket (Notion — optional)

If a Notion link to the ticket hasn't been provided, **ask for one once** — make clear it's optional and proceed without it if there is none.

When a link is given and the current harness has connected Notion access, fetch
the page and read the **`EXO-XXXX` ticket number** from its title or properties.
If Notion access is unavailable, ask for the ticket number once and proceed
without it when none is provided. Use the number to:

- append `[EXO-XXXX]` to the PR title unless repository-specific title rules
  require another format;
- fill the template's issue/ticket field. In the fallback template below, use
  `**Issue:** EXO-XXXX` under `## Issues`.

You may also draw on the ticket for context (what the change is for, from the end-user's perspective) — but the ticket is background, not something to copy verbatim into the body. When no link is given, drop the title tag. Follow the selected template's instructions for an empty issue/ticket field; in the fallback template, omit `## Issues` when there is genuinely no ticket.

## Title

- Unless repository-specific instructions say otherwise, use **English**, imperative mood (`Add …`, `Fix …`, `Revoke …`), matching existing titles in the repo.
- **Short and concise** — the title lands verbatim in the changelog, so it must read as a one-line release note on its own.
- Describe the change **from the end-user's perspective** whenever possible: what behaviour changes for the customer or the admin user, not which class you touched.
  - Good: `Revoke Let's Encrypt certificates without fetching the order`
  - Avoid: `Refactor LetsEncrypt::revoke() to drop getOrder() call`
- Append the issue tag when there is one and repository-specific title rules
  permit it: `… [EXO-XXXX]`.

## Body

### Find the applicable template first

Before drafting or replacing a body, inspect the target repository rather than assuming one fixed template:

1. Read applicable repository instructions such as `AGENTS.md`, `CONTRIBUTING.md`, and documented pull request guidance.
2. For an existing PR, read its current body first. Preserve its selected template and user-authored content unless the user asks for a rewrite.
3. Determine the repository's default branch and inspect templates there. GitHub only applies templates from the default branch; do not switch branches or modify the worktree just to read one.
4. Search GitHub's supported locations, case-insensitively:
   - `pull_request_template.md` or `pull_request_template.txt` in the repository root, `docs/`, or `.github/`;
   - `.md` or `.txt` template files inside `PULL_REQUEST_TEMPLATE/` in the repository root, `docs/`, or `.github/`.
5. When multiple templates exist, use the one already reflected in the PR body, explicitly selected by the user or command, linked by repository documentation, or clearly matching the change type. If the choice remains ambiguous and would materially change the body, ask which template to use rather than silently choosing one.
6. If the repository has no template and connected GitHub access is available, check for an applicable default community-health template in the owner or organization's public `.github` repository.

Treat repository instructions and the selected template as authoritative for structure and required content:

- Preserve its headings, order, checklists, tables, and required fields. Follow its comments and placeholder instructions; remove comments or placeholder text only when the template tells authors to replace or remove them.
- Fill every applicable section. Use `N/A` with a short reason only when the template permits it; do not delete a required section merely because it is inconvenient.
- Put ticket, testing, and change details in the template's corresponding fields. Do not add duplicate fallback sections under different names.
- Do not inject the fallback layout below when a repository or community-health template exists.
- Apply the language and content defaults in this skill only where they do not conflict with explicit repository guidance or the selected template.

### Writing defaults

Unless repository-specific instructions say otherwise, write the body in **Dutch**, in developer-speak: mix in English words wherever that's simply the word developers use (`race condition`, `nullable`, `edge case`, `hydrate`, `pointer`, `on-demand`, …) instead of forcing a Dutch translation. Don't hard-translate terms that lack a sensible Dutch equivalent.

But it has to stay easy for a human to read. Avoid mixes that read weird because the English word is obscure or the combination is clumsy — e.g. `dubbel resident`, or a bare `invariant`. If such a term genuinely is the best fit, add a **very short** inline gloss the first time you use it, e.g. `resident (altijd in context geladen)`. Readability always wins over translating — or over jargon — for its own sake.

When no repository-specific or community-health template exists, use this fallback layout:

```
## What does it do?

## How to test?

## Issues
**Issue:** EXO-XXXX
```

Keep it **short and concise**, but do call out important details and major design decisions — behaviour changes, new limits, non-obvious trade-offs, anything a reviewer or future reader needs to understand the change. Describe the effect from the end-user's perspective where you can; drop to implementation detail only where it matters for review. In the fallback layout only, omit the `## Issues` section when there is genuinely no ticket.

### How to test?

When the template has a testing field, describe there how **another developer** can verify the change themselves. If it has no testing field, add concise verification details only when repository guidance permits extra sections. Do **not** write "run unit test X" — tests are a given, not a test instruction.

Prefer, in this order:

1. **A concrete action in a frontend** — the click-path a developer follows (which screen, which button, what to enter, what result to expect). There are two frontends: the **admin** (employee-facing) and the **portal** (customer-facing); pick whichever one exposes the behaviour under test, and name it in the steps. Both are **separate projects you don't know**, so **ask Maarten** for the exact steps rather than inventing screen names or navigation. Frame the question around the behaviour that needs triggering ("how does a user create/edit X in the admin or portal?") and turn his answer into the steps.
2. **API calls**, when the frontend route is impossible or awkward. Give the method, the endpoint, and — for `POST`/`PATCH` — the request body as JSON. Each developer runs their own devbox on their own domain, so write the base URL as `https://api.xxx.exodev.nl` (the `xxx` is a per-developer placeholder). The API has **no version prefix** — do **not** add `/v1/` (or any other version) to the path; the endpoint follows the host directly (e.g. `https://api.xxx.exodev.nl/actions`). State the expected response (status code and the relevant part of the payload).

   ````
   `POST https://api.xxx.exodev.nl/...`
   ```json
   {
     "field": "value"
   }
   ```
   Verwacht: **201**, met ...
   ````

Include the setup a tester needs (a fixture to create first, an artisan command to kick a queued job, a specific record id to act on) so the steps are runnable start to finish.

## Draft

Always open a new PR as a **draft** (`gh pr create --draft …`), so Maarten can check it before requesting reviews. Never mark it ready for review yourself (`gh pr ready`) unless he asks for that in that message.

## Labels

Apply **exactly one** label yourself — never add a second one. Add it when opening (`gh pr create --label …`) or right after (`gh pr edit <nr> --add-label …`). Pick the single label that best captures the change.

Labels the repo adds automatically (e.g. `development`) are separate — leave those in place, don't remove them. The one-label rule is only about the label you choose to apply.

Usually that is the primary type:

- `bugfix` — fixes an inconsistency or issue that hurts users/implementors.
- `new-feature` — new feature or option.
- `enhancement` — improves existing code, no new feature.
- `refactor` — improves existing code structure, no behaviour change.
- `performance` — improves performance, no new feature.
- `maintenance` — generic maintenance.
- `documentation` — solely documentation.
- `ci` — improves continuous integration.
- `dependencies` — upgrades/downgrades dependencies.

Pick one of these instead when it is the defining aspect of the change (they still count as the single label — don't add them on top of a type):

- `breaking-change` — breaks existing users (usually pairs with `major`).
- `security` — security issue that needs resolving asap.
- `hotfix` — critical, needs deploying immediately.
- `major` / `minor` — force a version bump when the change warrants it.
- `skip-changelog` — exempt from the release notes (e.g. internal-only churn).
- `skip-deployment` — don't run deploy hooks on merge.

If the correct label is genuinely unclear from the change, pick the closest one and mention which you applied so Maarten can correct it. Confirm the repo's actual label set with `gh label list` if unsure — the list above may drift.

## Disclaimer

Always end the body with a disclaimer marking the description as AI-generated. A small italic note on its own line, separated by a rule:

    ---
    🤖 _Deze PR-omschrijving is gegenereerd door een AI-assistent._

This disclaimer is mandatory on every PR body — never omit it.
