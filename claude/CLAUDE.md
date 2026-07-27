# Global instructions

## Delegation and subagents

My default model is Opus and I don't use Plan Mode, so `opusplan`'s automatic Opus/Sonnet split never kicks in — work stays on Opus unless deliberately delegated. Push the right work onto subagents via the Agent tool, picking the cheapest model that still does the job.

**Delegate at all?** Yes when the task is **token-heavy** AND **self-contained** (short handoff, no live conversation context needed). Delegating isn't free — the main loop writes the handoff and reads the result — so for cheap or context-bound work the overhead cancels the saving. Worth delegating: research/doc-reading, broad searches, codebase exploration, large/repetitive edits/refactors, thorough code review. Do it directly in the main loop only when NOT worth delegating: needs live conversation context (in-flight debugging, a decision still being shaped), or it's cheap in tokens (one-off Bash, tiny edit). A settled git commit is borderline — the message is cheap but execution is fiddly (SSH-signed commits needing agent reattach, php-cs-fixer pre-commit hook, several git roundtrips), so it's often still worth handing to a Sonnet subagent.

**Which model?**
- `model: "sonnet"` for mechanical or well-specified work — searches, lookups, settled edits, routine exploration.
- **Opus** (leave `model` unset to inherit parent, unless the agent type pins its own model; or set `model: "opus"`) for token-heavy work needing real judgment — careful code review, architectural exploration, tricky correctness analysis. "Needs Opus judgment" does NOT mean "do it in the main loop" — it can still be a subagent, just an Opus one.

The Agent tool's `model` param takes only a family (sonnet/opus/haiku/fable), not an effort tier — there's no way to force a reasoning-effort level (e.g. xhigh) on a subagent.

**Keep delegated work from orphaning.** Fan out breadth from the main loop, where I hold the task ids and can stop them — don't have a subagent spawn its *own* background children, because those grandchildren orphan as "Running" tasks that the main loop's TaskList/TaskStop can't see or stop, and they pile up in the Background-tasks panel. Tell a subagent to do its sub-work inline (no nested fan-out). And never claim "nothing is running" off an empty TaskList — that only shows the work-list, not agents a subagent spawned a level down; if asked, say those can be cleared from the Background-tasks panel.

## Reasoning effort

Work at the session's current effort level by default — don't second-guess it for
every task. But if the current effort is clearly wrong for what I've asked, stop
before doing the work, say so, and tell me which level to switch to and why:

- **Too low** — the task needs deeper reasoning than the current level can give
  (subtle correctness analysis, architectural trade-offs, tricky debugging), so
  the answer would likely be shallow or wrong.
- **Too high** — the task is mechanical or trivial (a one-line edit, a lookup, a
  rename) and the current level just burns tokens and time.

Don't silently compensate and don't just proceed with a caveat — stop and let me
decide, since only I can change the effort level (`/effort`).

## Mark where the answer starts

Maarten finds it hard to tell where my research stops and my real answer
begins. When a reply contains research, multiple steps, or visible reasoning
above the conclusion, mark where the answer begins with a horizontal rule
followed by a heading with a check emoji, then the conclusion:

    ...research / steps / reasoning...

    ---

    ## ✅ Conclusion

- Keep the research/steps above intact — he still wants to see them; the marker
  is only a visual cue for where to start reading, not a signal to trim.
- Skip the marker for short, direct answers (a one-liner, a simple lookup) —
  no research above means no marker, so it stays meaningful. It must stand out
  more than any headings the research itself uses; that's why it's a rule AND a
  heading, not just a heading.
