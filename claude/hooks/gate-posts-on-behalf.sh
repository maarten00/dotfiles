#!/usr/bin/env bash
# Gate: outward-facing content posted on Maarten's behalf must go through the
# post-on-behalf voice-review pass first.
#
# Blocks raw `gh` posts (PR/issue comments, PR create, PR reviews, and gh api
# writes to comment/review endpoints) UNLESS the body is read from a *.reviewed.md
# file produced by the post-on-behalf skill's fresh-context review subagent.
#
# Detection is anchored to command boundaries (start of command, or after && || ; |
# and an optional VAR=val prefix), so a gh-post string sitting INSIDE a quoted
# argument (a test, echo, heredoc, python -c '...') is NOT treated as a post.
#
# GET reads (sampling Maarten's real comments) and all unrelated commands pass through.
# Fail-open: any parse error exits 0, so a bug here can never block normal work.

input="$(cat)"

# Fast path: if the payload never mentions gh, there is nothing to gate.
printf '%s' "$input" | grep -q 'gh' || exit 0

cmd="$(printf '%s' "$input" | python3 -c 'import sys, json
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("command", ""))
except Exception:
    pass' 2>/dev/null)"

[ -z "$cmd" ] && exit 0

# Optional leading env-assignments allowed before the gh command.
prefix='^([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]* +)*'
# gh itself, also when called by path (/usr/bin/gh), with a backslash, or through command/env/exec.
ghcmd='((command|env|exec) +)?(\\|[^[:space:]]*/)?gh'

is_post=0
# Split the command on shell separators so each segment is a command start,
# then check whether a segment actually BEGINS with a gh post.
while IFS= read -r seg; do
    seg="$(printf '%s' "$seg" | sed -E 's/^[[:space:]]+//')"
    [ -z "$seg" ] && continue

    # Asking for help posts nothing.
    printf '%s' "$seg" | grep -Eq '(^| )(--help|-h)( |$)' && continue

    # An approve without a body carries no text of his, so there is nothing to voice-review. It passes
    # when it creates a review (the path ends at /reviews, so submitting a pending one does not count),
    # sets event=APPROVE and sets no field but event and commit_id. Flags such as --jq or --method change
    # nothing that is posted, so they may come along.
    field="(-[fF]|--field|--raw-field)( +|=)?['\"]?"
    if printf '%s' "$seg" | grep -Eq "^${prefix}${ghcmd} +api( |\$)" \
       && printf '%s' "$seg" | grep -Eq "[ =]['\"]?/?repos/[{}A-Za-z0-9._-]+/[{}A-Za-z0-9._-]+/pulls/[0-9]+/reviews['\"]?( |\$)" \
       && printf '%s' "$seg" | grep -Eq -- "${field}event=['\"]?APPROVE(['\"]| |\$)" \
       && ! printf '%s' "$seg" | grep -Eq -- '--input' \
       && [ -z "$(printf '%s' "$seg" | grep -Eo -- "(^| )${field}[][A-Za-z0-9_]+=" | grep -Ev -- "${field}(event|commit_id)=\$")" ]; then
        continue
    fi

    if printf '%s' "$seg" | grep -Eq "${prefix}${ghcmd} +(pr|issue) +(comment|create)( |\$)|${prefix}${ghcmd} +pr +review( |\$)"; then
        is_post=1
        break
    fi
    if printf '%s' "$seg" | grep -Eq "${prefix}${ghcmd} +api( |\$)" \
       && printf '%s' "$seg" | grep -Eq '(comments|reviews)' \
       && printf '%s' "$seg" | grep -Eq '(-X +(POST|PATCH|PUT)|--method +(POST|PATCH|PUT)|(-F|-f|--field|--raw-field) +body)'; then
        is_post=1
        break
    fi
    # A GraphQL mutation that adds or edits a comment, review, thread or reply carries text too.
    if printf '%s' "$seg" | grep -Eq "${prefix}${ghcmd} +api +graphql( |\$)" \
       && printf '%s' "$seg" | grep -Eq '(add|update)(PullRequestReview|IssueComment|DiscussionComment|Comment)[A-Za-z]* *\('; then
        is_post=1
        break
    fi
done <<EOF
$(printf '%s' "$cmd" | sed -E 's/(\&\&|\|\||;|\||\n)/\n/g')
EOF

[ "$is_post" -eq 0 ] && exit 0

# Allow only when the body comes from a reviewed file. A single body is a
# *.reviewed.md; a whole review payload (summary + inline comments) is a
# *.reviewed.json handed to the api --input flag.
if printf '%s' "$cmd" | grep -Eq '(body=@|--body-file +)[^[:space:]]*\.reviewed\.md|--input +[^[:space:]]*\.reviewed\.json'; then
    exit 0
fi

>&2 cat <<'MSG'
BLOCKED — content posted on Maarten's behalf was not routed through the voice-review pass.

Use the post-on-behalf skill (~/.claude/skills/post-on-behalf/SKILL.md) instead of posting directly:
  1. Draft the content with the skill that owns it (pr-review, pull-request, ...).
  2. Run post-on-behalf's voice pass: a FRESH subagent whose only context is that skill's Rules
     section, the samples in ~/.claude/post-on-behalf/voice-profile.md, and the draft.
  3. Write the result to ~/.claude/post-on-behalf/<slug>.reviewed.md
  4. Re-run the gh command with the body read from that .reviewed.md file.

The gate allows the post once the body is read from a *.reviewed.md file.

Posting a full PR review (all inline comments in one pending review) is the
pr-review skill's job. It writes the payload to ~/.claude/post-on-behalf/<slug>.reviewed.json
and hands that file to the reviews endpoint with the --input flag, which the gate allows.
MSG
exit 2
