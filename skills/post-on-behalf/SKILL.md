---
name: post-on-behalf
description: "Use BEFORE posting ANY content on Maarten's behalf to GitHub — PR descriptions, PR/issue comments, PR reviews, inline review comments, replies on review threads — or similar outward-facing text. Routes the draft through a fresh-context voice pass so it matches his voice the first time. A PreToolUse hook hard-blocks raw gh posts until the body comes from a *.reviewed.md (or a review payload from a *.reviewed.json) file this skill produces, so invoke this whenever you would otherwise run gh pr comment / gh pr create / gh pr review / gh api ... comments|reviews (POST/PATCH). These rules govern the posted text only; they do NOT change the language of normal chat replies."
---

# Post on behalf of Maarten

Outward-facing text drafted for Maarten is checked against his voice BEFORE it is posted, so he is
not the review loop after the fact. A hook (`~/.claude/hooks/gate-posts-on-behalf.sh`) blocks raw
`gh` posts; the sanctioned path is below.

What to write is owned elsewhere: the `pr-review` skill owns review comments and their labels, the
`pull-request` skill owns PR titles, templates and bodies. This skill owns the voice pass, the footer
and the gated post.

## Steps

1. **Re-read the "Rules" section** at the bottom of this file.

2. **Load his voice from the cache** at `~/.claude/post-on-behalf/voice-profile.md` (verbatim human
   samples plus a short style summary). Use it as-is; do not sample live every time.

   **Refresh the cache only when it is due** (cheap to check):

   ```bash
   mkdir -p ~/.claude/post-on-behalf
   COUNT=$(ls ~/.claude/post-on-behalf/*.reviewed.md 2>/dev/null | wc -l)
   # compare with `reviewed_count_at_refresh` in the profile's frontmatter
   ```

   Refresh when the profile is **missing**, when `COUNT < reviewed_count_at_refresh` (files were
   pruned), or when `COUNT - reviewed_count_at_refresh >= 40` (about every 40 posts). He can force
   one by deleting the profile or saying "refresh voice profile".

   **On refresh:** pull fresh, genuinely human samples — a few short review and PR comments and,
   when there are any, one or two PR bodies — and rewrite `voice-profile.md` with verbatim samples
   plus a short style summary. Set `refreshed:` to today and `reviewed_count_at_refresh:` to the
   current `COUNT`. **Keep the file under 4 KB**, samples over summary: a long summary does not earn
   its cost. Never type his login, and exclude **every** machine-generated marker, not just one
   footer:

   ```bash
   me=$(gh api user --jq .login)
   gh search prs --commenter=@me --owner=exonet --sort=updated --limit 15 --json repository,number
   # then, per PR:
   gh api --paginate "repos/<owner>/<repo>/pulls/<n>/comments" \
     --jq ".[] | select(.user.login == \"$me\") | select(.body | test(\"🤖|Claude|AI-assistent|gegenereerd door\") | not) | .body"
   gh api --paginate "repos/<owner>/<repo>/issues/<n>/comments" \
     --jq ".[] | select(.user.login == \"$me\") | select(.body | test(\"🤖|Claude|AI-assistent|gegenereerd door\") | not) | .body"
   ```

   Mirror only these real samples, never machine-drafted posts: learning from those drifts further
   from his voice with every round.

3. **Draft** the content, following the skill that owns it.

4. **Voice pass in a FRESH subagent.** Spawn a subagent (Agent tool) whose ENTIRE context is: the
   quoted "Rules" section from this file, the verbatim samples from the cache (not the whole file),
   and the draft. Keep it on the main model: the fresh context, not a bigger model, is what makes it
   work. Tell it to rewrite the draft to match his voice and apply every rule — plain everyday Dutch
   (no formal words like "empirisch" or "construeerbaar", no stiff loanwords like "compliant"),
   English identifiers, the right footer, scope trimmed to the change, every sentence cut that only
   restates what the reader already expects (the change meets its ticket, a requirement is covered,
   CI is green), and no coined or borrowed word where one the repo and he already use would do. For a
   PR body, it rewrites the prose only and keeps the template's headings, order, checklists, fields
   and the disclaimer exactly as they are. For a review comment, it keeps the label line, the
   `<details>` block and any `suggestion` block intact. It returns ONLY the final body.

5. **Write the reviewed body** to `~/.claude/post-on-behalf/<slug>.reviewed.md`. The `.reviewed.md`
   suffix is what the gate allows. A whole review payload (inline comments in one pending review)
   goes in `~/.claude/post-on-behalf/<slug>.reviewed.json` instead, built from bodies that each went
   through step 4; see the `pr-review` skill.

6. **Post** with the body read from that file:
   - PR comment: `gh pr comment <n> -R <owner>/<repo> --body-file ~/.claude/post-on-behalf/<slug>.reviewed.md`
   - edit a comment: `gh api repos/<o>/<r>/issues/comments/<id> -X PATCH -F body=@$HOME/.claude/post-on-behalf/<slug>.reviewed.md`
   - thread reply: `gh api repos/<o>/<r>/pulls/<n>/comments/<id>/replies -X POST -F body=@$HOME/.claude/post-on-behalf/<slug>.reviewed.md`
   - new PR: `gh pr create … --body-file ~/.claude/post-on-behalf/<slug>.reviewed.md`
   - pending review: `gh api repos/<o>/<r>/pulls/<n>/reviews -X POST --input ~/.claude/post-on-behalf/<slug>.reviewed.json`

## Notes

- If the gate blocks you, you skipped step 4 or 5. Produce the reviewed file and retry. A post the
  gate lets through is not automatically fine: the rules stand on their own.
- The source of truth is the "Rules" section below. When Maarten corrects the voice, he edits it
  there, and the gate guarantees it gets read on the next post.
- The cache (`voice-profile.md`) holds *samples*, not *rules*. Editing the rules needs no cache
  refresh. The cache only saves the live `gh` sampling, not the rule-reading or the fresh-subagent
  pass.
- `gh pr edit --body` is not gated by the hook. Still route a rewritten body through this skill.

## Rules

### Voice, language, and scope

- **Language (default):** Dutch body, with technical terms and identifiers kept in English (package
  names, class and method names, file paths, code, CLI commands). Keep the English programming terms
  developers simply use (`race condition`, `nullable`, `edge case`). A PR title is English (see
  `pull-request`). A comment needs no heading by default; never add one that just restates the
  opening line. Deviate only when the thread or audience is clearly another language.
- **Voice:** plain, concrete and direct — lead with what the change does or what goes wrong. No
  generic machine-register filler or jargon-heavy framing ("three independent standalone bumps
  without transitive blockers").
- **Reader's vantage:** write for someone with no context on how the work was done. Describe what a
  change or test *does* or *covers*, not the process followed, and skip internal workflow jargon.
  Backstory earns its place only when it is genuinely the *why* (a bugfix, or why an existing test
  was insufficient).
- **Mirror real examples, not machine output.** When unsure of phrasing, mirror his own comments and
  PRs — only ones without an AI footer.
- **Scope:** keep the content self-contained to the change at hand. Don't pull in internal roadmap
  or planning context the reader doesn't need: work deferred to other PRs, broader groupings, or
  internal analysis terminology.
- **Cut what is implied or expected.** Don't state what the merge gate already guarantees (tests
  pass, static analysis clean, CI green). Don't restate the expected outcome either: that the change
  does what its ticket asked, or that a requirement is covered. Only a *gap* is worth words.

### Inline review comments

- Short, informal, first person, often a soft suggestion or a question ("Volgens mij mist hier een
  `->save()`", "Bewust X hier?", "Zou 'm zo doen", "Wat gebeurt er als …?"). The one-line summary is
  what must read like a quick human remark; the `<details>` block may go deeper.
- The rest of the shape (label line, `<details>`, `suggestion` outside it, anchoring) is in the
  `pr-review` skill.

### Footer

Every post gets a footer so readers can tell the text is machine-drafted. It goes at the end, after
one blank line:

- **Comments, reviews, inline comments, replies, a pasted review summary:**

      ---
      🤖 _Automatische comment gegenereerd door een AI-assistent._

- **PR bodies:** the disclaimer from the `pull-request` skill instead.

No footer on:

- commit messages (the `Co-Authored-By` trailer covers those);
- messages to Maarten in the chat;
- internal-only files (CLAUDE.md, plans, memory, code comments);
- messages between sessions;
- a reply the desktop app posts itself on a review comment (Auto-fix or address comments), which
  carries the app's own trailer.
