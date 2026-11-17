---
name: pull-request
description: "Rules for writing a GitHub pull request: discover and preserve the repository-specific PR template, then write a concise title and body using the repository's conventions, and optionally hand the opened PR to a self-review in its own session. Load this whenever you are about to draft, open, or update a PR — e.g. 'open a PR', 'gh pr create', 'write the PR description', 'update the pull request body'. These rules govern the PR title and body text only; they do NOT change the language of normal chat replies."
---


# Pull request

Guidelines for writing the title and body of a GitHub pull request. These rules govern the PR text only; they must not change the language of ordinary chat responses.

## Ticket (Notion — optional)

If a Notion link to the ticket hasn't been provided, **ask for one once** — make clear it's optional and proceed without it if there is none.

When a link is given and the current harness has connected Notion access, fetch
the page and read the **`EXO-XXXX` ticket number** from its title or properties.
When only a ticket number or name is known, don't `notion-search` the workspace:
every ticket lives in `Sprint tasks`, so look it up with
`notion-query-data-sources` (SQL on `collection://a6d84700-59c1-46a7-925e-76acc0a847ed`,
filtering on `"Task ID"` — the bare integer — or `"Task name"`).
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

## Voice pass before posting

Once the body is drafted (disclaimer included), hand it to the `post-on-behalf` skill for its voice pass, then open or update the PR with the body read from the file it writes: `gh pr create --draft … --body-file ~/.claude/post-on-behalf/<slug>.reviewed.md`. A gate hook blocks `gh pr create` with any other body. The voice pass rewrites prose only; the template structure and the disclaimer stay as this skill sets them. Route a rewritten body for an existing PR (`gh pr edit --body-file …`) through it too, even though the hook does not gate that.

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

## Self-review in its own session (optional)

Once the draft PR is open, offer a self-review in a separate session. The `pr-review` skill
recognises his own PR, skips the pending review, and sends its findings, plus any open threads from
colleagues, back to the session that wrote the PR with `SendMessage`. That is this session, so the
fixes happen here, with the context of how the change came about. Only in the desktop app, where
`mcp__ccd_session__start_session` exists; elsewhere, close with one line that `/pr-review <PR URL>`
in a new session does the same.

1. Bind this session to the PR (`mcp__ccd_pr__get_status`, then `bind_pr` when it does not report
   it). `pr-review` finds the writing session by its `prNumber`.
2. Call `start_session`:
   - `initiation: "user_asked"` when his request asked for a self-review, otherwise
     `"own_initiative"`: a card he starts with one click, so nothing runs unasked.
   - `context: "fresh"`, so the review reads the diff without this conversation's assumptions, and
     `use_worktree: false`, since it only reads. Leave `model` unset: a review needs Opus.
   - `prompt`: `/pr-review <PR URL>`, plus one line that this is his own PR and the findings go to
     the session that opened it.
3. When the findings arrive, check each one against the code before changing anything: a finding is
   a claim, not proof. Fix what holds, one signed commit per issue (see "Fixing PR issues" in
   `~/.claude/CLAUDE.md`), and run the narrowest checks. Commit and push without waiting for his
   go, draft or not: the comment of step 4 is where he reviews them. Replies to colleague threads
   that came along are drafts until he says to post them.
4. After the push, post one PR comment (`gh pr comment`, through `post-on-behalf`) as the record of
   what the self-review changed, so he can judge each fix later and revert the ones he does not
   like:
   - per fixed finding: its severity label, what was wrong in one line, and the commit as a link
     (`<owner>/<repo>@<sha>` renders as one);
   - per rejected finding: one line with what it claimed and why it does not hold;
   - the head SHA the review read.

   Language and voice follow the PR body. One comment per round, never an edit of an earlier one.
5. Send the rejected findings and the reasons back to the review session (`SendMessage`, its id from
   the `start_session` result), so its re-check does not flag them again.

The review session keeps watching the PR. After a push it re-checks by itself and sends anything new
here, so never start a second review for the same PR. Auto-fix at most two rounds: findings from a
third round go to him in the chat, with the fixes drafted but not committed, so the review and the
fixes cannot keep feeding each other.
