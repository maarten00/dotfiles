---

name: pull-request

description: "Rules for writing a GitHub pull request: the title (English, changelog-ready) and the body (Dutch, following the repo's PR template). Load this whenever you are about to draft, open, or update a PR — e.g. 'open a PR', 'gh pr create', 'write the PR description', 'update the pull request body'. These rules govern the PR title and body text only; they do NOT change the language of normal chat replies."

---


# Pull request

Guidelines for writing the title and body of a GitHub pull request. These rules govern the PR text only; they must not change the language of ordinary chat responses.

## Ticket (Notion — optional)

If a Notion link to the ticket hasn't been provided, **ask for one once** — make clear it's optional and proceed without it if there is none.

When a link is given, fetch the page (`notion-fetch` with the URL) and read out the **`EXO-XXXX` ticket number** from its title or properties. Use it to:

- append `[EXO-XXXX]` to the PR title;
- fill the `## Issues` section (`**Issue:** EXO-XXXX`).

You may also draw on the ticket for context (what the change is for, from the end-user's perspective) — but the ticket is background, not something to copy verbatim into the body. When no link is given, drop the title tag and leave the `## Issues` section for the user to fill (or omit it if there's genuinely no ticket).

## Title

- **English**, imperative mood (`Add …`, `Fix …`, `Revoke …`), matching existing titles in the repo.
- **Short and concise** — the title lands verbatim in the changelog, so it must read as a one-line release note on its own.
- Describe the change **from the end-user's perspective** whenever possible: what behaviour changes for the customer or the admin user, not which class you touched.
  - Good: `Revoke Let's Encrypt certificates without fetching the order`
  - Avoid: `Refactor LetsEncrypt::revoke() to drop getOrder() call`
- Append the issue tag when there is one: `… [EXO-XXXX]`.

## Body

Write the body in **Dutch**, in developer-speak: mix in English words wherever that's simply the word developers use (`race condition`, `nullable`, `edge case`, `hydrate`, `pointer`, `on-demand`, …) instead of forcing a Dutch translation. Don't hard-translate terms that lack a sensible Dutch equivalent.

But it has to stay easy for a human to read. Avoid mixes that read weird because the English word is obscure or the combination is clumsy — e.g. `dubbel resident`, or a bare `invariant`. If such a term genuinely is the best fit, add a **very short** inline gloss the first time you use it, e.g. `resident (altijd in context geladen)`. Readability always wins over translating — or over jargon — for its own sake.

Follow the repo's PR template (`.github/PULL_REQUEST_TEMPLATE.md`):

```
## What does it do?

## How to test?

## Issues
**Issue:** EXO-XXXX
```

Keep it **short and concise**, but do call out important details and major design decisions — behaviour changes, new limits, non-obvious trade-offs, anything a reviewer or future reader needs to understand the change. Describe the effect from the end-user's perspective where you can; drop to implementation detail only where it matters for review. Omit the `## Issues` section only when there is genuinely no ticket.

### How to test?

Describe how **another developer** can verify the change themselves. Do **not** write "run unit test X" — tests are a given, not a test instruction.

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

Always end the body with a disclaimer marking the description as Claude-generated. A small italic note on its own line, separated by a rule:

    ---
    🤖 _Deze PR-omschrijving is gegenereerd door Claude._

This disclaimer is mandatory on every PR body — never omit it.
