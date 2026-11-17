# Putting a review on GitHub

`gh pr review` cannot carry inline comments, so everything below goes through `gh api`.

## The normal case: one call, one pending review

Write the whole payload to `~/.claude/post-on-behalf/<slug>.reviewed.json`. The `.reviewed.json`
suffix is what the gate hook allows, the same way `.reviewed.md` works for a single body. The
bodies inside it must still have come out of the `post-on-behalf` pass.

```json
{
  "commit_id": "<headRefOid>",
  "comments": [
    { "path": "Modules/Dns/Services/ZoneService.php", "line": 82, "side": "RIGHT", "body": "..." },
    { "path": "Modules/Dns/Services/ZoneService.php", "start_line": 55, "start_side": "RIGHT", "line": 61, "side": "RIGHT", "body": "..." }
  ]
}
```

```bash
gh api repos/<owner>/<repo>/pulls/<n>/reviews -X POST \
  --input ~/.claude/post-on-behalf/<slug>.reviewed.json
```

Leaving `event` out is what makes the review **pending**. With `event` it would submit
immediately, which is exactly what must not happen.

Anchors must sit inside the diff hunk (the changed range plus a few context lines). GitHub
rejects the whole call when one comment anchors outside it, so a rejected call usually means one
bad anchor, not a broken payload.

## What a live test confirmed

Run against exonet/backend #8363 on 2026-09-16, with three comments in one call, then deleted again:

- Leaving `event` out gives `state: PENDING`. Confirmed.
- **The `body` is stored but never reaches the author, and submitting destroys it.** It comes back at
  full length while the review is pending, which is misleading. GitHub's "Finish your review" dialog
  does not pre-fill from it, so Maarten never sees it, and the empty textarea overwrites it on
  submit. Measured on exonet/backend #8373: created with `bodylen=708`, came back as `708` while
  pending, and read `bodylen=0` after he submitted it as `CHANGES_REQUESTED`. **Do not put a `body`
  in the payload.** Hand the summary to him in chat so he can paste it into that dialog.
- A single-line anchor, a multi-line anchor (`start_line` + `line`) and an anchor in a second file
  all landed correctly in one call.
- Deleting the review with `-X DELETE` on `pulls/<n>/reviews/<id>` removes its pending threads too.
- **GraphQL lags a few seconds behind that delete.** Right after it, `reviewThreads` still listed one
  of the removed threads while REST already reported zero pending reviews. Re-query before concluding
  a thread survived.

The re-check path was tested on the same PR on the same day:

- A second review over REST while one is pending fails with
  `422 "User can only have one pending review per pull request"`, as expected.
- `addPullRequestReviewThread` attaches to the pending review and works for a single-line anchor and
  for a multi-line one (`startLine` plus `startSide`).
- `addPullRequestReviewThreadReply` returns `state: PENDING`, both for a thread in that same pending
  review and for **a thread that was already submitted in an earlier review**. The latter is the
  common re-check case, and it is the one that could have gone public. It does not. The reply was
  absent from `GET /pulls/<n>/comments` while it was pending, so nobody sees it until Maarten
  submits.
- `deletePullRequestReviewComment` on a thread's only comment removes the whole thread, and the
  review itself stays `PENDING`.

These are facts about the API. They do not make a pending review the place for replies, see
"Replies" below.

## When a pending review already exists

Only one pending review per user per PR. A second `POST` fails with
`422 "User can only have one pending review per pull request"`. Attach to the existing one
instead.

```bash
# the review's node id
gh api repos/<owner>/<repo>/pulls/<n>/reviews --jq '.[]|select(.state=="PENDING")|.node_id'
```

```bash
gh api graphql -f reviewId=<node> -f path=<file> -F line=<n> \
  -F body=@$HOME/.claude/post-on-behalf/<slug>.reviewed.md \
  -f query='mutation($reviewId:ID!,$body:String!,$path:String!,$line:Int!){addPullRequestReviewThread(input:{pullRequestReviewId:$reviewId,body:$body,path:$path,line:$line,side:RIGHT}){thread{id}}}'
```

A follow-up on one of his own pending drafts can go in the same review with
`addPullRequestReviewThreadReply(input:{pullRequestReviewId:<reviewNode>, pullRequestReviewThreadId:<threadNode>, body:...})`.
It lands as `PENDING`. A reply to someone else is never parked like that, see "Replies".

Remove a draft you replaced: `deletePullRequestReviewComment(input:{id:<commentNode>})`. Deleting a
thread's only comment removes the thread.

## Replies

A reply to a review thread is posted directly once he says to place it, through `post-on-behalf`.
It never waits in a pending review. A pending review is only for an actual review of someone
else's PR.

```bash
gh api repos/<owner>/<repo>/pulls/<n>/comments/<commentId>/replies -X POST \
  -F body=@$HOME/.claude/post-on-behalf/<slug>.reviewed.md
```

An answer to a question from a review body goes in a top-level PR comment instead.

A reply is not a review. Parking replies in a pending review only adds a submit round for him, and
on exonet/backend #8433 that submit did not even go through the first time.

## Reading what is already there

**Pending drafts are invisible** to `GET /pulls/<n>/comments`, which lists submitted comments
only, and a pending review's `body` can be `""`. So a pending review looks empty when it is not.
Before calling one empty or deleting it, list its real drafts:
`gh api repos/<owner>/<repo>/pulls/<n>/reviews/<reviewId>/comments`.

That REST endpoint returns `line: null` for pending drafts, so when the anchor matters, read
`repository.pullRequest.reviewThreads` over GraphQL instead (`id path line startLine`, plus
`comments.nodes.id`).

On PR #8042 an "empty" pending review actually held three draft comments. Deleting it would have
wiped them.

## Watch out

- **An empty ```` ```suggestion ```` block submits as "delete these lines".** Flag stray empty ones
  rather than leaving them in a review that gets submitted.
- **A suggestion in a *reply* applies to the thread's anchor lines, not to lines you pick.** On
  #8243 an empty suggestion in a reply would have removed an `if (...) {` and left its `return` and
  `}` stranded. Say "the whole block can go" in prose there instead.
- **Batching gh calls: use `/usr/bin/gh` and flat commands.** Wrapping the call in a zsh function
  and capturing it with `$(...)` fails with `command not found: gh` even when `which gh` resolves.
  The absolute path in a plain, non-nested command works.
