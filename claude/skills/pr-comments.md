---

name: pr-comments

description: "Rules for writing GitHub pull request review comments (inline or general): the required language, style, and mandatory footnote. Load this whenever you are about to place, draft, or post review comments on a GitHub PR — e.g. 'review this PR', 'leave comments on the pull request', 'gh pr review', 'reply to the review comment', 'post inline comments'. These rules apply only to the text of GitHub PR comments; they do NOT change the language of normal chat replies."

---


# PR comments

Guidelines for every comment placed on a GitHub pull request — inline or general. Applies to both Claude CLI and Claude Desktop. These rules govern the PR comment text only; they must not change the language of ordinary chat responses.

## Language

Write in Dutch, but keep English programming terms where that reads naturally (`race condition`, `nullable`, `type hint`, `edge case`, etc.). Don't hard-translate terms that lack a sensible Dutch equivalent — forced translations hurt readability more than they help.

## Style

To the point and punctual. Keep each comment as short as possible while still giving enough detail to pin down the issue — name the concrete problem and where it bites, skip the throat-clearing.

## Footnote

Always end the comment with a footnote marking it as an automated Claude comment. Use a small italic note on its own line, separated by a rule:

    ---
    🤖 _Automatische comment gegenereerd door Claude._

This footnote is mandatory on every comment — never omit it.
