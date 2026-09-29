---
name: skill-authoring
description: "Create, revise, or review agent skills, including SKILL.md, helper scripts, and practical validation. Use when the user asks to author or improve a skill. Explaining skills or using an existing skill does not by itself authorize creating or changing one."
---

# Skill Authoring

Write a small operating manual backed by dependable tools. Show **what to run,
what comes back, and what to do next**. Let the model choose and interpret;
let code handle repeatable mechanics.

Prefer a command, an output example, or an observable check over an abstract
instruction. The command names below illustrate skills being authored;
`skill-authoring` itself has no executable helpers.

## Authoring flow

1. **Establish the task.** Extract a representative request, inputs, expected
   output, and a checkable completion condition from the conversation. Inspect
   existing skills and tools before proposing new ones. Ask only for missing
   information that changes scope, permissions, or the implementation.
2. **Choose the smallest implementation.** Reuse an existing CLI or API first.
   Add helper scripts for repeated mechanics or awkward integration. Keep a
   prose-only skill when judgment or conventions are the whole capability.
3. **Write the manual and any necessary helpers** using the guidance below.
   When revising a skill, preserve unrelated behavior and its public name;
   fix the observed problem rather than redesigning the whole package.
4. **Verify and hand off.** Run the applicable authoring checks. Report changed
   paths, checks actually run, and any unverified behavior. Installation,
   synchronization, publishing, and real external mutations require their own
   authorization; writing the skill does not authorize them.

If the request is advice or a review, return advice or findings rather than edits.
This flow is not a requirement to create a plan document, spawn agents, or ask
the user to approve routine details already covered by their request.

## 1. The skill itself: an operating manual

### Define the boundary

Give the skill one recognizable purpose. State what success produces and what
it does not do when a neighboring capability is easy to confuse with it.

Choose the appropriate home for the behavior:

| Need | Smallest suitable home |
| --- | --- |
| Reusable task guidance or a tool-use recipe | Skill |
| Repeated parsing, pagination, conversion, or state handling | Helper script |
| Project-specific conventions | Existing project instructions |
| A prompt the user deliberately invokes | Prompt command, if supported |
| Tool registration, session hooks, UI, or execution-lifecycle changes | Harness extension |

A skill teaches use of the available tools; it does not grant permissions or
replace the harness's execution protocol. Follow repository packaging rules.
Do not create an extension or a script merely to complete a directory template.

### Make discovery precise

Use a descriptive name such as `service-search`, not `expert-helper`, and valid
frontmatter. Match the directory name when required by the package contract.
Make `description` say what the capability does and which requests need it:

```yaml
name: service-search
description: "Search service error records by query and time range. Use when investigating recorded incidents or finding specific errors; not for general questions about error handling."
```

Use the user's task vocabulary. Add an exclusion only for a plausible near miss.
Keep commands and execution steps in the body instead of maintaining a second
manual in the description.

### Put the shortest useful path first

Usually write: purpose/prerequisites → quick start → input/output contract →
common failures → result verification. Omit sections with nothing useful to say.
Lead with one realistic command and the result it produces, not an option catalog.
For a prose-only skill, use one input/output example instead of inventing a script.

Replace vague advice with instructions the agent can actually follow:

| Instead of | Write something like |
| --- | --- |
| “Use the search tool.” | `./scripts/search.js --query "level:error" --limit 5` |
| “Configure the environment.” | “Requires Node.js on PATH and an existing signed-in account. Run `./scripts/auth.js accounts` to list accounts.” Add the minimum runtime version if the code requires one. |
| “Returns structured results.” | “stdout is JSON with `items` and `nextCursor`; `items: []` is a successful empty result.” |
| “Handle authentication errors.” | “On 401, check the selected account and request reauthentication for that account; do not silently switch accounts.” |
| “Verify carefully.” | “Render the model, open the preview images, and check shape and alignment before exporting.” |

These are patterns, not promises to paste into every skill. Describe only commands,
fields, prerequisites, and failure handling that the actual implementation supports.

Teach the missing information. A model usually does not need an introduction to
Git; it may need to know which files to include and that committing does not
include pushing. Use strong requirements for concrete failure modes, not every
preference. Explain a reason when it changes a decision; omit roleplay and repeated
warnings.

### Keep knowledge close to its source

Keep the common path in `SKILL.md`. Move large or branch-specific material to
bundled references and say **when** to read each one. Keep local links inside
the skill root. Aim for a body comfortably below 500 lines, but remove redundant
content rather than hiding essential instructions merely to hit a length target.

Document common commands and non-obvious defaults; use `--help` or authoritative
references for exhaustive option lists. Scripts should be usable without loading
their source into context. Read the source when diagnosing or changing them.

## 2. Helper scripts: ordinary, composable tools

Package what the agent would otherwise reconstruct: parsing a response, following
pagination, handling authentication, or managing a reusable connection. Keep an
existing CLI when it already does the job; do not wrap it just to rename it.

### Write short, directly executable commands

Use `./search.js --query "timeout"` for a root-level helper, or
`./scripts/search.js --query "timeout" --limit 5` for a helper under `scripts/`.
Use meaningful script names and named options, not a long installation path or an
unexplained sequence of positional values. Positional arguments are fine for
obvious inputs such as a single file or URL.

State once in the authored skill: **“Run the following commands from this skill's
directory, the directory containing SKILL.md.”** Reading a skill does not change
the shell's working directory; the agent must locate that directory and set the
command's cwd or change into it before executing the examples.

- Write `./scripts/search.js --limit 5`, not a hardcoded path such as
  `/Users/someone/projects/tools/skills/service-search/scripts/search.js --limit 5`.
- Avoid repeating `~/.pi/agent/skills/<name>/...`: the install location can change.
  Resolve the real location at execution time, not in every example.
- Give directly invoked scripts the right shebang and executable mode.
  For Node.js, use `#!/usr/bin/env node` and `chmod +x scripts/search.js`.
  Preserve that mode in version control and check that packaging preserves it.
- If the target environment requires an interpreter, document one consistent
  form such as `node ./scripts/search.js --limit 5`. Keep the path relative;
  do not alternate invocation styles without a reason.
- Preserve file arguments when changing cwd: resolve user-provided input/output
  paths against the original project directory first. Short helper paths do not
  mean reinterpreting the user's files relative to the skill directory.
- Resolve the helper's own templates and assets relative to its source file,
  not the caller's cwd. An absolute input or returned artifact path is fine when
  needed to identify a real file; the rule is against hardcoded helper locations.

### Show the common operations and their flags

A small command table is often enough. For a search helper, it could look like:

| Task | Example invocation |
| --- | --- |
| Find a few errors | `./scripts/search.js --query "level:error" --limit 5` |
| Select an account | `./scripts/search.js --account team --query "timeout"` |
| Save a large result | `./scripts/search.js --query "timeout" --output results.json` |
| Inspect all options | `./scripts/search.js --help` |

Document useful defaults alongside the examples: for instance, “`--limit` defaults
to 20, accepts 1–100; `--output` writes JSON instead of printing records.” The
numbers and behavior must match the implementation. Keep `--help` authoritative
for the full option list. Add only the options the current task needs.

`--help` should print usage, options, defaults, and an example without logging in,
accessing the network, or writing state. Validate arguments before making calls
or creating files. Missing prerequisites should explain what is missing rather
than install dependencies automatically.

### Specify the output and the failure path

For a machine-consumed search result, a complete small example is clearer than
“returns JSON”:

```json
{"items":[{"id":"err-42","title":"Request timed out"}],"nextCursor":null}
```

For this example contract, state that an empty match returns
`{"items":[],"nextCursor":null}` with exit code 0; invalid arguments and failed
requests use a nonzero exit code and a diagnostic on stderr. Keep progress messages
out of JSON stdout. Plain text or a single path is enough when that is the useful
result; do not require a JSON envelope for every script.

Filter, paginate, count, and aggregate in code. For large output, save the full
result to a file and report its actual path and record count. Distinguish complete
results from truncation or partial retrieval; an incomplete count is not a total.

Write recovery instructions for the actual failures, not “retry on error”:

| Failure | Behavior to implement and document |
| --- | --- |
| Missing or ambiguous account | Identify the required option and how to list accounts; do not guess. |
| Expired authentication | Identify the selected account and how to reauthenticate it; keep tokens out of output. |
| Timeout or partial retrieval | Use a bounded wait; report what completed and whether results are partial. |
| Uncertain remote write | Inspect the target state before retrying so the operation is not duplicated. |

### Make state and side effects visible

Say which commands only read and which create, modify, or delete data. Use the
existing authorization flow; a warning in Markdown is not access control.

If the helper keeps a cache or profile, document its location and reuse policy.
Keep it separate from the user's live profile. Cleanup should remove only owned
temporary files or processes, not clear a whole shared directory or kill whatever
happens to occupy a port.

For a long-lived job, return an ID and log location, and show the matching inspection
and stop commands, such as `./job.js status --id job-42` and
`./job.js stop --id job-42`. Do not add a job manager to a one-shot script.

If a helper needs model inference, make that stage explicit and pass its purpose,
for example a summary focused on authentication failures. Retain the raw input
or artifact needed to inspect the result. A summary is not the underlying evidence.

### Compose operations in code when it earns its complexity

Prefer one bounded script over many model turns for known sequences: fetch
pages, filter records, compute totals, and return a small result. Use independent
concurrent requests when the API permits them; preserve ordering where needed.

Choose between two interfaces based on current use:

- **Named commands** suit a small set of recurring operations with stable inputs.
- **A code-execution entry point** can suit varied combinations of a large SDK.
  It should supply the shared connection/authentication setup and a clear result
  contract instead of duplicating every API method as a new tool.

The latter is optional, not the default. Generated code still needs appropriate
permissions, validation, time bounds, and observation of side effects. `eval`, a
JavaScript VM context, or Markdown instructions are not a security sandbox.

## 3. Authoring checks: verify the usable capability

Use checks proportional to the change. A prose-only convention needs different
evidence from a script that writes remote data. Do not create empty test suites
or an elaborate evaluation system just to satisfy a template.

### Check the written interface

- Parse frontmatter and check the name against the directory/package contract.
- Follow local links and locate every helper presented as part of the skill.
  Clearly label hypothetical examples in authoring guides like this one.
- Look for hardcoded checkout/install paths; replace them with short `./...`
  invocations plus one working-directory instruction.
- Compare example flags, defaults, and output fields with the real CLI. A command
  that looks plausible but is not implemented is a documentation bug.
- Check stated runtimes, credentials, and assets against actual dependencies.
  Remove hidden reliance on the author's machine or undeclared sibling files.
- Attribute copied materials according to repository policy. Inspiration is not
  a claim that these files were copied from an upstream delivery unit.
- Remove sections, helpers, and dependencies that do not support a current task.

### Run the documented commands, when helpers are present

Use small fixtures or authorized test targets and existing tests where possible.
Select the checks relevant to the helper; these are not a mandate to add every
failure mode to every script.

| Check | Concrete action and expected evidence |
| --- | --- |
| Actual invocation | Run the documented `./... --...` form, not only `node file.js`; confirm its shebang and executable bit work in the delivery layout. If an interpreter is the documented form, test that form. |
| Help | Run `--help` without credentials; verify it prints useful usage and exits 0 without network calls or writes. |
| Happy path | Copy the quick-start command with fixture values; inspect stdout or the artifact contents, not only the exit code. |
| Empty and invalid input | Check a no-match query and an invalid flag/value, such as `--limit 0` when the range starts at 1; distinguish empty success from failure. |
| Paths | Invoke after locating the skill from another cwd, using a skill directory and input filename containing spaces; verify bundled assets and user files still resolve correctly. |
| External failure | Simulate the likely missing prerequisite, 401, or timeout; inspect the exit code, diagnostic, and any partial result. |
| Mutation or persistent work | Where applicable, verify retry does not duplicate writes, status identifies the right job, and stopping/cleanup preserves unrelated resources. |

Use temporary files and test state. Live credentials, browser launches, dependency
installation, and external mutations need appropriate authorization, not just an
example that mentions them. Report blocked checks precisely. A mocked API check
does not establish that live authentication works.

### Try representative requests

For the illustrative `service-search` skill, useful behavioral cases are:

| Request or situation | Expected behavior |
| --- | --- |
| “Find five recent timeout errors.” | Discover the skill, use the documented helper and filters, inspect results, and report relevant records. |
| “Explain what a timeout means.” | Answer without searching private records, logging in, or creating a new skill. |
| The search returns 401 | Identify the selected account and follow the documented reauthentication path or stop for missing authorization. |

Choose equivalent cases for the skill being authored. An available evaluation
harness or independent agent can provide observed behavior when authorized and
useful. A manual walkthrough is a lighter check for wording-only changes; label
it as a walkthrough, not a successful execution or a measured trigger rate.

For repeated triggering or compliance problems, compare the same cases before
and after the change. Fix the observed gap at its source: routing in the
description, choices in the manual, mechanics in code. Rerun the affected checks
and stop. Measure time or tokens only when efficiency is an actual question.

## Design basis

This is original guidance inspired by Armin Ronacher's tool-oriented approach,
not a copied skill or a claim that his repository implements every check above.
These sources explain the approach; reading them is not a prerequisite on each use.

- [Agent Stuff, inspected revision](https://github.com/mitsuhiko/agent-stuff/tree/122e2994adddb113c04764c5697217dae120fcc6/skills)
- [Tools: Code Is All You Need](https://lucumr.pocoo.org/2025/7/3/tools/)
- [Skills vs Dynamic MCP Loadouts](https://lucumr.pocoo.org/2025/12/13/skills-vs-mcp/)
- [Agent Skills specification](https://agentskills.io/specification)
