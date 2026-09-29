---
name: prototype
description: Build a throwaway logic or UI prototype to answer a design question.
disable-model-invocation: true
metadata:
  upstream:
    repo: mattpocock/skills
    path: skills/engineering/prototype
    commit: 3cca18b368ae95cdbdebbff572ccafa662551015
    status: modified
    notes:
      - local: omit agents/openai.yaml because Pi does not load OpenAI-specific skill metadata.
      - local: capture uses an independent JJ change (bookmark when a durable pointer is needed) when .jj/ exists; otherwise a Git throwaway branch.
      - local: require explicit user selection of prototyping and hide the skill from automatic discovery.
      - local: capture follows the current project's tracker and authorization rules; without a configured tracker or issue, keep the pointer and verdict locally.
---

# Prototype

A prototype is **throwaway code that answers a question**. The question decides the shape.

Start when the user invokes `/skill:prototype` or explicitly selects a prototype step in another workflow. A general request to assess a design is not permission to build a prototype; answer the question or offer the prototype first.

## Pick a branch

Identify which question is being answered, using the user's prompt, the surrounding code, or by asking if the user is around:

- **"Does this logic / state model feel right?"** → [LOGIC.md](LOGIC.md). Build a single shareable HTML file (free-play buttons plus tabbed guided walkthroughs) that pushes the state machine through cases that are hard to reason about on paper, and that a non-developer can drive.
- **"What should this look like?"** → [UI.md](UI.md). Generate several radically different UI variations on a single route, switchable via a URL search param and a floating bottom bar.

The two branches produce very different artifacts, so getting this wrong wastes the whole prototype. If the question is genuinely ambiguous and the user isn't reachable, default to whichever branch better matches the surrounding code (a backend module → logic; a page or component → UI) and state the assumption at the top of the prototype.

## Rules that apply to both

1. **Throwaway from day one, and clearly marked as such.** Locate the prototype code close to where it will actually be used (next to the module or page it's prototyping for) so context is obvious, but name it so a casual reader can see it's a prototype, not production. For throwaway UI routes, obey whatever routing convention the project already uses; don't invent a new top-level structure.
2. **Trivial to run.** A UI prototype starts from one command in the project's task runner: `pnpm <name>`, `python <path>`, `bun <path>`, etc. A logic demo is a single HTML file the user double-clicks. Either way, no thinking required to start it.
3. **No persistence by default.** State lives in memory. Persistence is the thing the prototype is _checking_, not something it should depend on. If the question explicitly involves a database, hit a scratch DB or a local file with a clear "PROTOTYPE, wipe me" name.
4. **Skip the polish.** No tests, no error handling beyond what makes the prototype _runnable_, no abstractions. The point is to learn something fast.
5. **Surface the state.** After every action (logic) or on every variant switch (UI), print or render the full relevant state so the user can see what changed.
6. **Capture it when done.** Fold any validated decision into the real code, then capture the prototype itself as a **primary source** out of the main line:
   - **If `.jj/` exists**, read the installed `jj` skill and put the prototype on an independent JJ change; create a bookmark when a durable pointer is needed. Preserve unrelated work and follow its confirmation rules for history changes.
   - **Otherwise**, commit it to a throwaway Git branch, out of main.

   Read the current project's tracker instructions (such as `docs/agents/issue-tracker.md`) before publishing anything. Use the configured tracker and its authorization rules to put the capture pointer, verdict, and question settled on the associated implementation issue. Do not infer a tracker from a mirror remote. If no tracker or associated issue is configured, keep the pointer and verdict in the prototype's local notes or commit description and report their location; do not create an issue merely to satisfy this step. The main line keeps only the validated decision.
