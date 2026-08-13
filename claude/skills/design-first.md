---

name: design-first

description: "Plan a code change design-first: understand the change, then propose and iterate on an ARCHITECTURE before any code is written. The output centers on the architecture — components and their responsibilities, how they interact, the key design decisions, and the alternatives that were considered and rejected — delivered as a written design doc plus an inline summary, then revised in a loop until you approve. MANDATORY TRIGGERS: 'design-first', 'design this', 'architect this', 'plan the architecture', 'how should I build/structure X', 'let's design before building', 'think through the architecture'. STRONG TRIGGERS (use when the request is a non-trivial build or refactor): 'plan this change', 'how would you approach X', 'I want to add/build/refactor <feature>' where the shape isn't obvious, 'what's the best way to structure', 'where should this live'. Do NOT trigger for trivial or fully-specified changes (a one-line fix, a rename, a change with an obvious single implementation), for pure debugging, or when the user has already agreed on an approach and just wants it built. DO trigger whenever the user wants to reason about design and structure before committing to code, especially when they want to weigh options."

---


# Design First

You noticed something: the fun and the value both live in the *puzzle* — laying out the pieces, seeing how they fit, choosing between real alternatives — and it's easy to skip straight to typing code and lose that. This skill exists to slow that first reflex down. The deliverable is not code and not even a task list; it's an **architecture you can argue with** before a single line is written.

The rule that makes this work: **do not edit or write application code while this skill is active.** You are designing. Code comes only after the architecture is agreed. If you feel the pull to start implementing, that's the signal you're skipping the part that matters.

---

## The loop

```
Understand  →  Design the architecture  →  Write the doc  →  Iterate  →  (approval)  →  Build plan
                        ▲                                        │
                        └────────────── revise ──────────────────┘
```

Most of the effort — and almost all of the output — belongs in **Design the architecture**. The other phases exist to make that one good.

---

## Phase 1 — Understand the change

**First, make sure you actually have a change to design.** This skill is often invoked by name (`/design-first`, "design-first this") with the change described in the same breath — but sometimes the invocation arrives *bare*, with no concrete task attached. If that happens, your only job right now is to ask, in one short line, **what change the user wants to design** (and, if it helps, roughly what it's for). Do not try to define what "design-first" means — the user knows; they picked the skill. And do not launch exploration agents or read code yet: you have nothing to look for until you know the change. Get the target, then continue.

Once you have a concrete change, get the shape of the problem. Cheap to do, expensive to skip: an architecture built on a misread of the requirement is wasted no matter how elegant. Pin the intent *before* you fan out — exploration is only useful once you know what you're exploring for.

- **Pin the intent and the boundaries.** What is the change actually for? What is explicitly *not* in scope? What constraints are non-negotiable (backward compatibility, performance, a deadline, an existing API contract)? Ask the user targeted questions *only* where the answer would change the design — don't interrogate them on things you can settle by reading the code or picking a sane default.
- **Learn the terrain.** Find the existing patterns this change lands in: similar features already built, the seams where new code will attach, the data that flows through, the call sites that will be affected. A good architecture usually *rhymes* with what's already there rather than inventing a parallel universe next to it.
- **Fan out when the surface is broad.** If the change touches several independent areas (call sites, config, related flows, tests), use `Explore` or `Plan` subagents in parallel to map them — but keep it to a few at a time, and read key files directly afterward when exact structure matters. If the surface is small and known, just read it yourself; spawning agents for a two-file change is pure overhead.
- **Ground yourself in the repo's idioms.** If the project ships an architecture/conventions skill (for example a `project-architecture` skill describing repositories, DataObjects, structures, actions, or similar building blocks), invoke it now so your proposal uses the house style instead of a generic one. If no such skill exists, infer the conventions from neighboring code. Repo-idiomatic beats textbook-correct.

Come out of this phase able to state, in a sentence or two, *what* is being built and *what existing machinery it has to live with*.

---

## Phase 2 — Design the architecture

This is the heart of the skill. Think of it as solving a puzzle in the open, showing your reasoning, not delivering a verdict from on high. The user wants to *see the design space* and reason about it with you.

Work through these, and let the genuinely interesting parts run long — this is where depth pays off:

- **The forks in the road.** Identify the real decisions this change forces — the places where a thoughtful engineer could reasonably go two or three different ways. These are the substance of the architecture. Examples: where a responsibility should live, whether to extend an existing abstraction or add a new one, sync vs. async, one component or several, how state flows, where the boundary between modules falls.
- **The candidate approaches.** For each meaningful fork, lay out the viable options — typically two or three. For each: how it works, what it costs, what it buys. **Do not manufacture fake alternatives** to pad the analysis; if one approach is clearly right, say so and say why the others don't survive. But where the choice is genuinely live, resist collapsing it prematurely — the comparison *is* the value.
- **The tradeoffs, made explicit.** Judge the options on the axes that actually matter for *this* change. Common ones: fit with existing patterns, complexity added, blast radius / risk, testability, extensibility for likely future needs, performance. Name the axes you're weighing so the user can disagree with the weighting, not just the conclusion.
- **The recommendation and the why.** Commit to a recommended architecture and explain the reasoning that got you there — especially the tradeoffs you accepted and what you gave up. A recommendation without its reasoning can't be argued with, and being argued with is the whole point.
- **The shape of it.** Describe the resulting structure concretely: the components/classes/modules, each one's single responsibility, and the boundaries between them. Then describe how they interact — the flow of data and control, what calls what, in what order. When the interaction is more than a couple of hops, a small diagram (an ASCII sketch or a mermaid block) earns its place; when it's simple, prose is clearer than a box-and-arrow ritual.
- **The seams and the risks.** Where does this touch existing code, and what could that break? What's still unknown or assumed? What would you want to validate before or during the build? Surfacing a risk early is worth more than a polished plan that hides it.

Aim to give the user something meaty enough to have opinions about. Vague designs produce vague feedback; specific proposals with named tradeoffs produce the sharp iteration that makes the final architecture good.

---

## Phase 3 — Write the design doc

Persist the design so the user can read it slowly, annotate it, and come back to it — this is why the output is a file, not just chat.

**Where:** prefer a natural home in the repo if one exists (`docs/design/`, `design/`, `notes/`, or wherever design docs already live). If there's no obvious place, write it to the session scratchpad directory. Always tell the user the exact path.

**Structure — architecture first, everything else in service of it:**

```markdown
# <Change name>

## Problem & goal
<1–3 sentences: what this change is for. Non-goals if they clarify scope.>

## Context & constraints
<What already exists that this must fit into. Hard constraints. Key assumptions.>

## Architecture   ← the centerpiece; most of the doc lives here
### Recommended approach
<The design you're proposing, and the reasoning — including the tradeoffs accepted.>
### Components & responsibilities
<Each piece, its single responsibility, its boundaries.>
### How it fits together
<Data flow / control flow. Diagram if the interaction is non-trivial.>
### Key decisions
<Each real fork: the options, the axes weighed, the choice, the why.>
### Alternatives considered
<Approaches rejected and the specific reason each lost. Skip only if there truly was one sane path.>

## Risks & open questions
<What could break, what's unresolved, what to validate.>

## Implementation plan   ← intentionally last and lighter; fill in only after the architecture is agreed
<Left as a stub until Phase 5.>

## Testing strategy
<How the design will be proven correct. Stub until Phase 5.>
```

The ordering is deliberate: architecture and its rationale come first and take up the most room; the task breakdown comes last and small. That's the opposite of a typical rush-to-implement plan, and it's the point of the skill.

After writing the file, give an **inline summary** in chat: the recommended architecture in a few lines, and — most importantly — the 2–4 crux decisions surfaced explicitly so the user can react without reading the whole doc first. Point to the file for the full version.

---

## Phase 4 — Iterate

Now stop and hand the design back. Say plainly that this is a draft to react to, and invite disagreement — on the recommendation, on the tradeoff weighting, on a decision you called the wrong way, on a constraint you missed. Ask for the crux points where their judgment is likely to differ from yours rather than a generic "thoughts?".

When feedback comes, fold it into the doc, update the inline summary, and re-surface what changed. Loop here as many times as it takes. **Do not proceed to a build plan, and do not write any code, until the user signals the architecture is good.** This phase is the deliverable; treat "let's keep refining" as success, not delay.

---

## Phase 5 — Build plan (only after approval)

Once the architecture is agreed, and only then, flesh out the implementation plan and testing strategy in the doc:

- Break the work into a sequence of coherent steps, ordered so the codebase stays working (and ideally testable) between them.
- For each step, note what it changes and how it's verified — which tests to write or extend. In this codebase, remember new/changed code needs tests and must pass the project's static-analysis gate.
- Call out anything that should be a separate follow-up rather than bloating this change.

Then confirm the user wants to start building before you touch code. The architecture doc becomes the reference the implementation follows — if reality forces a design change mid-build, come back and update the doc rather than letting it silently drift.

---

## Keep it proportional

Scale the ceremony to the change. A large or ambiguous feature justifies the full loop with a rich alternatives analysis. A medium change might need one tight pass through the phases with two or three key decisions. If a request turns out to be trivial or has a single obvious implementation, say so and don't force a design doc onto it — the skill is for changes where the design genuinely deserves thought, and pretending a one-way-door decision is a hard puzzle wastes the user's time as surely as skipping design would.
