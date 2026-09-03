---
name: mcpteam-delivery-team
description: Orchestrate an Agent Team coordinated via the mcpteam MCP server to deliver code
---

# Delivery Team with mcpteam

Use this skill for non-trivial coding work that benefits from implementation, validation, documentation, and review being handled by separate Agent Team teammates.

## Preflight checks

Before doing anything else, verify both prerequisites:

1. **Agent Teams**: Confirm `TeamCreate` is available. If not, stop and tell the user: "Agent Teams are not available. Enable them with CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1."
2. **mcpteam MCP server**: Call `mcp__mcpteam__list_ready_tasks()` to check connectivity. If the tool is not available or errors, stop and tell the user: "The mcpteam MCP server is not connected. Check your .mcp.json configuration and restart Claude Code."

If either check fails, do not proceed.

## Required execution model

Create an actual Claude Code Agent Team using separate teammates. Do not simulate the team serially in one conversation.

If actual Agent Teams are unavailable, stop and say so. Do not role-play Lead, Implementer, Typechecker, Linter, Tester, Docs, and Reviewer in sequence.

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

- Create one mcpteam plan for the requested delivery work.
- Decompose the work into clear, claimable tasks.
- Decompose implementation into multiple increments when that allows validation or documentation work to proceed earlier.
- Respect dependencies between tasks.
- Include dependency notes in task descriptions because `mcpteam` does not currently enforce task dependencies directly.
- Delegate tasks to teammates.
- Monitor plan state.
- Summarize final outcome.

Rules:

- The Lead does not implement production code.
- The Lead does not complete worker tasks.
- The Lead should create validation tasks only when there is something meaningful to validate.
- The Lead should prefer a dependency graph over one large serial batch.

### Implementer

`agent_id="implementer"`

Responsibilities:

- Claim one implementation task at a time.
- Complete or fail the claimed task before claiming another task.
- The Implementer may complete multiple implementation tasks over the lifetime of the plan when the Lead decomposes the work into a pipeline.
- Make each code change minimal and focused.
- Respect the file scope and dependency notes in the task description.
- Run the smallest useful local validation before completing each implementation task.
- Complete each task with:
  - detailed result in the task result
  - compact summary in the plan summary

Can edit:

- Runtime code
- Tests directly related to the implementation
- Configuration only when required by the task

Must not:

- Perform final review.
- Claim validation, docs, or review tasks.
- Claim more than one task at the same time.
- Start a dependent implementation task before its prerequisite task is complete.
- Make broad unrelated refactors.

### Multiple implementation tasks

Default to one active Implementer.

The Lead may decompose implementation into multiple implementation tasks when the work has natural increments.

Examples:

- data model change
- persistence implementation
- API or tool wiring
- tests for the new behavior
- cleanup or follow-up fix

The Implementer may claim these tasks sequentially as `agent_id="implementer"`.

Each implementation task should include:

- expected file scope
- dependency notes
- what validation should happen after it completes
- whether downstream validation, docs, or review tasks may begin after this task

If two implementation tasks touch the same file or same logical surface, they should be sequenced.

If implementation tasks have clearly disjoint file scopes, the Lead may create multiple implementer roles, but this is not the default. Use explicit role IDs such as:

- `implementer-runtime`
- `implementer-tests`
- `implementer-config`

Only use multiple simultaneous implementers when the task descriptions include non-overlapping file scopes.

### Typechecker

`agent_id="mypy"`

Responsibilities:

- Claim exactly one typing validation task at a time.
- Run relevant mypy commands.
- Inspect typing failures.
- Distinguish real code issues from third-party stub gaps.
- Recommend minimal typing fixes.

Can edit:

- No, unless the Lead explicitly assigns a typing implementation task.

Must report:

- Exact commands run
- Error counts
- Important error categories
- Whether failures are caused by project code, config, or third-party stubs

### Linter

`agent_id="lint"`

Responsibilities:

- Claim exactly one lint/format validation task at a time.
- Run relevant lint and format checks.
- Identify style, import, or formatting issues.
- All reviewed code must be correctly formatted, even code from previous, unrelated changes.

Can edit:

- No, unless the Lead explicitly assigns a formatting task.

Must report:

- Exact commands run
- Whether lint passed
- Any files requiring changes
- Whether auto-fix would be safe

### Tester

`agent_id="tester"`

Responsibilities:

- Claim exactly one test validation task at a time.
- Run relevant unit/integration tests.
- Diagnose failures.
- Confirm whether failures are related to the implementation.

Can edit:

- No, unless the Lead explicitly assigns a test-fix task.

Must report:

- Exact commands run
- Passing/failing counts
- Failure summaries
- Whether failures appear related to the current change

### Docs

`agent_id="docs"`

Responsibilities:

- Claim exactly one documentation task at a time when documentation is required.
- Update README, docs, examples, comments, or usage notes as appropriate.
- Keep docs changes scoped to the behavior changed by the implementation.

Can edit:

- Documentation files
- Comments/docstrings only when directly related

Must not:

- Modify runtime behavior
- Rewrite unrelated documentation

### Reviewer

`agent_id="reviewer"`

Responsibilities:

- Claim exactly one review task after implementation and relevant validation tasks complete.
- Review the final diff.
- Review validation results from Typechecker, Linter, Tester, and Docs.
- Identify correctness risks, edge cases, dependency risks, and unnecessary changes.
- Recommend accept/revise/block.

Can edit:

- No.

Must report:

- Whether the change is safe to accept
- Any required follow-up
- Any validation gaps
- Any rollback or operational concerns

## Delivery phases

The Lead should structure delivery work as a dependency graph, not as one large serial batch.

Use phased execution, but allow downstream teammates to start as soon as their specific dependency is complete.

### Phase 0: Optional baseline validation

Create baseline validation tasks only when useful.

Examples:

- baseline mypy state
- baseline lint state
- baseline test state
- current docs/API behavior

Baseline tasks may run in parallel with implementation.

A baseline task must be explicitly labeled as baseline or pre-change validation.

### Phase 1: Incremental implementation pipeline

The Lead may create one or more implementation tasks.

Default to one active Implementer.

The Implementer claims one implementation task at a time, completes or fails it, then may claim the next implementation task if one exists.

The Lead should prefer smaller implementation tasks when downstream validation can begin earlier.

Each implementation task should state:

- file or module scope
- dependencies
- expected behavior change
- relevant validation commands
- downstream tasks that may start once it completes

### Phase 2: Dependency-aware parallel validation

Validation tasks do not always need to wait for all implementation work to complete.

A validation task may begin when the implementation task it validates is complete.

Examples:

- Typechecker validates implementation task A while Implementer starts implementation task B.
- Tester validates a completed test-related change while docs work proceeds.
- Linter validates changed files after a formatting-sensitive implementation task completes.

Final validation tasks must wait until all implementation tasks that affect their scope are complete.

Validation tasks must clearly state whether they are:

- baseline validation
- task-specific post-change validation
- final validation

### Phase 3: Documentation

Docs tasks may begin when the behavior or interface they document is stable enough to describe.

Docs should not run against speculative behavior.

Docs may run in parallel with final validation if the relevant implementation is complete.

### Phase 4: Review

The Reviewer should run after:

- all implementation tasks are complete,
- relevant validation tasks are complete,
- docs tasks are complete or explicitly deemed unnecessary.

The Reviewer should inspect:

- final diff
- task results
- validation outputs
- docs changes, if any
- remaining risks

### Phase 5: Lead synthesis

The Lead should call `get_plan` and summarize:

- Plan status
- Completed task summaries
- Implementation increments completed
- Files changed
- Commands run
- Validation status
- Reviewer recommendation
- Remaining risks
- Suggested next step

## mcpteam rules

Every teammate must claim a task before doing work.

Every claimed task must be completed or failed.

No teammate may complete or fail a task claimed by another teammate.

Each teammate may claim at most one task at a time.

A teammate may claim another eligible task only after completing or failing its current task.

Implementation tasks may be sequentially claimed by the same Implementer when the Lead has decomposed the implementation into multiple increments.

Use the role-specific `agent_id` exactly:

- `lead`
- `implementer`
- `mypy`
- `lint`
- `tester`
- `docs`
- `reviewer`

If multiple simultaneous implementers are explicitly used, use clear role-specific IDs such as:

- `implementer-runtime`
- `implementer-tests`
- `implementer-config`

Detailed findings go in the task result.

Plan completion summaries must stay compact.

Do not dump full command output into the plan summary. Put full command output or detailed findings in the task result.

## Dependency rules

The Lead must manage task dependencies explicitly in task descriptions.

`mcpteam` does not currently enforce dependencies, so the Lead and teammates must honor dependency notes.

Do not run final validation against a pre-change state unless the task explicitly says it is baseline/pre-change validation.

Validation teammates may run baseline tasks in parallel with implementation only when those tasks are explicitly labeled as baseline.

Task-specific validation may begin as soon as the implementation task it validates is complete.

Final validation must wait until all implementation tasks affecting its scope are complete.

Docs may begin once the relevant behavior or interface is stable.

Do not start the Reviewer until implementation, relevant validation, and docs tasks are complete.

If a validation task discovers required code changes, the Lead should create a new implementation follow-up task rather than letting the validation teammate directly modify runtime code.

If a follow-up implementation task is created, the Lead should also create or update downstream validation/review tasks as needed.

## Failure handling

If a teammate cannot complete a task:

- call `fail_plan_task`
- include a compact failure summary
- include detailed failure output in the task result
- leave enough information for the Lead to create a follow-up task

If mcpteam reports a claim conflict, the teammate should re-read the plan and choose another eligible task or stop.

If mcpteam reports a plan conflict, re-read the plan and retry only if the intended update is still valid.

## Command safety rules

Avoid complex inline shell scripts.

Do not use multi-line `python -c "..."` commands.

Do not use quoted multi-line shell strings that contain comments, shell metacharacters, heredocs, or embedded scripts.

### Prefer dedicated tools over shell

Teammates should prefer Claude Code's dedicated tools over shell equivalents wherever possible. The Grep, Glob, and Read tools are not just stylistic preferences — they avoid permission prompts that would otherwise force the user to approve every command.

- **Prefer the Grep tool over `grep`, `find`, `awk`, `sed`, or any combination of them.** Grep takes `pattern`, `glob`, `output_mode`, `head_limit`, and `multiline` parameters. Anything you would build as a `find ... | xargs grep ...` or `grep ... | awk ... | sed ...` pipeline is almost always expressible as a single Grep call.
- **Prefer the Read tool over `cat`, `head`, `tail`, or `sed -n`.** Read supports `offset` and `limit` for partial reads of large files.
- **Prefer the Glob tool over `find -name`.** Glob takes a `pattern` and returns matches sorted by modification time.
- **Reserve Bash for cases where there's genuinely no dedicated-tool equivalent** (e.g. `pytest`, `git log`, `aws describe-*`, running a project script).

Claude Code's permission system parses shell commands into an AST to check them against the allowlist. Compound shell constructs — `while read`, `for ... in`, nested `$(...)`, multi-stage pipes, `||` with side-effecting fallbacks — frequently defeat the parser. When parsing fails, the permission system falls back to "must ask the user," even for read-only operations that would otherwise be auto-allowed. The dedicated tools bypass this entirely.

Examples:

❌ `find src -name "*.py" | xargs grep "def foo"`
✓ Grep with `pattern="def foo"` and `glob="**/*.py"`

❌ `grep -rE "^def _[a-z]+" src | awk '{print $2}'`
✓ Grep with `pattern="^def _[a-z]+"` and `output_mode="content"`, then process in your own reasoning.

❌ `cat path/to/file.py | head -50`
✓ Read with `file_path="..."` and `limit=50`.

### Python validation

For ad hoc Python validation, prefer one of these approaches:

1. Use existing tests when possible.
2. Add or run a focused pytest test when file edits are allowed.
3. Use a temporary script file under `/tmp` without `#` comment lines, then run it.
4. Use a single-line `python -c` only for simple expressions.

When validating behavior with many cases, prefer:

```bash
uv run pytest tests/path/to/test_file.py -q
```
over large inline Python snippets.

### Lead responsibility

When the Lead writes task descriptions for teammates, the Lead should explicitly include the tool-preference rules in each task prompt (e.g. "Use Grep tool freely — no compound shell pipelines"). Stating this in the task prompt prevents teammates from defaulting to shell habits.

## Task prompt template

When this skill is invoked, use the user's task as the delivery goal.

If the user did not provide a plan key, create one using a short kebab-case name derived from the task, with a timestamp suffix if needed to avoid collisions.

Do not ask for confirmation unless the task is genuinely ambiguous or destructive.
