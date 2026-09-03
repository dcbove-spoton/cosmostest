---
name: mcpteam-discovery-team
description: Orchestrate an Agent Team coordinated via the mcpteam MCP server to perform discovery within existing code
---

# Discovery Team with mcpteam

Use this skill for non-trivial investigation work that benefits from multiple Agent Team teammates exploring different parts of the repository in parallel.

This skill is for discovery, diagnosis, design analysis, risk assessment, and recommendation. It is not for implementation unless the user explicitly asks to continue into delivery mode.

## Preflight checks

Before doing anything else, verify both prerequisites:

1. **Agent Teams**: Confirm `TeamCreate` is available. If not, stop and tell the user: "Agent Teams are not available. Enable them with CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1."
2. **mcpteam MCP server**: Call `mcp__mcpteam__list_ready_tasks()` to check connectivity. If the tool is not available or errors, stop and tell the user: "The mcpteam MCP server is not connected. Check your .mcp.json configuration and restart Claude Code."

If either check fails, do not proceed.

## Required execution model

Create an actual Claude Code Agent Team using separate teammates. Do not simulate the team serially in one conversation.

If actual Agent Teams are unavailable, stop and say so. Do not role-play Lead, Explorer, Typechecker, Tester, and Reviewer in sequence.

Use `mcpteam` as the coordination layer.

Use only these plan-aware `mcpteam` tools for plan tasks:

- `create_plan`
- `get_plan`
- `add_task_to_plan`
- `claim_plan_task`
- `complete_plan_task`
- `fail_plan_task`

Do not use low-level task or shared-state tools for plan work unless explicitly debugging `mcpteam`.

## Team

### Lead

`agent_id="lead"`

Responsibilities:

- Create one mcpteam plan for the discovery work.
- Decompose the investigation into independent tasks.
- Delegate tasks to teammates.
- Monitor plan state.
- Synthesize findings into a final recommendation.

Rules:

- The Lead does not perform worker investigations.
- The Lead does not edit files.
- The Lead should avoid forcing sequential work unless there is a real dependency.

### Explorer

`agent_id="explorer"`

Responsibilities:

- Claim exactly one exploration task.
- Map relevant code paths, modules, interfaces, and dependencies.
- Identify where the requested behavior is implemented.
- Find likely extension points and risk areas.

Can edit:

- No.

Must report:

- Files inspected
- Important functions/classes/modules
- Current behavior
- Relevant architectural seams
- Open questions or ambiguities

### Typechecker

`agent_id="mypy"`

Responsibilities:

- Claim exactly one typing/static-analysis task.
- Run mypy or inspect typing configuration when relevant.
- Identify typing risks, ignored imports, stub gaps, or strictness boundaries.
- Distinguish real project issues from third-party typing limitations.

Can edit:

- No.

Must report:

- Exact commands run
- Error counts
- Error categories
- Whether findings represent real code risk or type-system/stub limitations

### Tester

`agent_id="tester"`

Responsibilities:

- Claim exactly one validation/discovery task.
- Run existing tests or targeted commands to characterize current behavior.
- Identify likely regression boundaries.
- Report whether the current test suite covers the area being investigated.

Can edit:

- No.

Must report:

- Exact commands run
- Passing/failing counts
- Relevant failures or skipped coverage
- Gaps in current validation

### Reviewer

`agent_id="reviewer"`

Responsibilities:

- Claim exactly one review/challenge task.
- Review the Explorer, Typechecker, and Tester findings.
- Challenge assumptions.
- Identify contradictions, missing evidence, and implementation risks.
- Recommend safest next step.

Can edit:

- No.

Must report:

- Findings it agrees with
- Findings it challenges
- Missing evidence
- Risk ranking
- Recommended next action

## Discovery phases

The Lead should generally structure work into phases.

### Phase 1: Parallel investigation

Create independent tasks for the teammates.

Typical tasks:

- Explorer: map relevant code and architecture
- Typechecker: inspect typing/static-analysis implications
- Tester: run validation and identify coverage boundaries

These tasks should run in parallel when possible.

### Phase 2: Review and challenge

After enough findings are available, create or release the Reviewer task.

The Reviewer should inspect the completed task summaries and detailed task results before completing its review.

### Phase 3: Lead synthesis

The Lead should call `get_plan` and summarize:

- Plan status
- Completed task summaries
- Key files/modules involved
- Evidence gathered
- Risks and unknowns
- Recommended next implementation task
- Whether Delivery Team mode should be used next

## mcpteam rules

Every teammate must claim a task before doing work.

Every claimed task must be completed or failed.

No teammate may complete or fail a task claimed by another teammate.

Each teammate should claim at most one task at a time.

Use the role-specific `agent_id` exactly:

- `lead`
- `explorer`
- `mypy`
- `tester`
- `reviewer`

Detailed findings go in the task result.

Plan completion summaries must stay compact.

Do not dump full command output into the plan summary. Put full command output or detailed findings in the task result.

## File modification rules

Discovery Team mode is read-only by default.

Do not edit files.

Do not format files.

Do not apply fixes.

Do not update docs.

If a teammate discovers a likely fix, it should describe the fix and risk level, not implement it.

If implementation is needed, the Lead should recommend switching to Delivery Team mode.

## Command and tool selection

Teammates should prefer Claude Code's dedicated tools over shell equivalents wherever possible. The Grep, Glob, and Read tools are not just stylistic preferences — they avoid permission prompts that would otherwise force the user to approve every command.

- **Prefer the Grep tool over `grep`, `find`, `awk`, `sed`, or any combination of them.** Grep takes `pattern`, `glob`, `output_mode`, `head_limit`, and `multiline` parameters. Anything you would build as a `find ... | xargs grep ...` or `grep ... | awk ... | sed ...` pipeline is almost always expressible as a single Grep call.
- **Prefer the Read tool over `cat`, `head`, `tail`, or `sed -n`.** Read supports `offset` and `limit` for partial reads of large files.
- **Prefer the Glob tool over `find -name`.** Glob takes a `pattern` and returns matches sorted by modification time.
- **Reserve Bash for cases where there's genuinely no dedicated-tool equivalent** (e.g. `pytest --collect-only`, `git log`, `aws describe-*`, running a project script).

### Why this matters

Claude Code's permission system parses shell commands into an AST to check them against the allowlist. Compound shell constructs — `while read`, `for ... in`, nested `$(...)`, multi-stage pipes, `||` with side-effecting fallbacks — frequently defeat the parser. When parsing fails, the permission system falls back to "must ask the user," even for read-only operations that would otherwise be auto-allowed. Every such compound pipeline becomes a permission prompt regardless of whether each individual command in the pipeline is safe.

The dedicated tools (Grep, Glob, Read) bypass this entirely. They have well-defined parameter schemas, no compound parsing involved, and permission settings can target them precisely.

### Examples

❌ `find src -name "*.py" | xargs grep "def foo"`
✓ Grep with `pattern="def foo"` and `glob="**/*.py"`

❌ `grep -rE "^def _[a-z]+" src | awk '{print $2}'`
✓ Grep with `pattern="^def _[a-z]+"` and `output_mode="content"`, then process in your own reasoning.

❌ `cat src/twis_geocoder/geocoder/resolver.py | head -50`
✓ Read with `file_path="..."` and `limit=50`.

❌ `for f in src/*.py; do grep -c "pattern" $f; done`
✓ Grep with `pattern=...` and `output_mode="count"`.

### Lead responsibility

When the Lead writes task descriptions for teammates, the Lead should explicitly include these tool-preference rules in the task prompt. Stating "Use Grep tool freely" or "Read, Grep, Glob only — no compound shell pipelines" in each task prevents teammates from defaulting to shell habits.

## Dependency rules

Explorer, Typechecker, and Tester may run in parallel when their tasks are independent.

Reviewer should run after at least one substantive discovery task is complete. Preferably, Reviewer should run after Explorer, Typechecker, and Tester have completed.

Do not block the whole team on one slow task unless the Reviewer genuinely requires that result.

## Failure handling

If a teammate cannot complete a task:

- call `fail_plan_task`
- include a compact failure summary
- include detailed failure output in the task result
- leave enough information for the Lead to decide whether to retry, skip, or change scope

If mcpteam reports a claim conflict, the teammate should re-read the plan and choose another eligible task or stop.

If mcpteam reports a plan conflict, re-read the plan and retry only if the intended update is still valid.

## Task prompt template

When this skill is invoked, use the user's question or investigation request as the discovery goal.

If the user did not provide a plan key, create one using a short kebab-case name derived from the investigation goal, with a timestamp suffix if needed to avoid collisions.

Do not ask for confirmation unless the investigation target is genuinely ambiguous.

End with a recommendation, not an implementation.