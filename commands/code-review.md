---
allowed-tools: Task, Bash(git diff:+), Bash(git log:+), Bash(git status:+)
argument-hint: "[short|full]"
description: Review code changes for Go quality, factory patterns, composition, and test coverage
---

## Context

- Current git status: `!git status`
- Recent changes: `!git diff HEAD~1 --stat`
- Current branch: `!git branch --show-current`

## Your task

Review code changes against YOLO coding guidelines.

### Step 1: Parse Mode

- No argument or `short` → **Short mode** (1 agent — fast)
- `full` → **Full mode** (4 agents — thorough)

### Step 2: Read Guidelines

Read these docs before reviewing:
- `/home/node/.claude/docs/go-patterns.md`
- `/home/node/.claude/docs/go-factory-pattern.md`
- `/home/node/.claude/docs/go-composition.md`
- `/home/node/.claude/docs/go-testing.md`
- `/home/node/.claude/docs/git-workflow.md` (CHANGELOG section)

### Step 3: Run make precommit

Use Task tool with simple-bash-runner:
```
subagent_type="simple-bash-runner", prompt="make precommit"
```

### Step 4: Agent Review

**Short mode** (default):
1. `go-quality-assistant` — critical pattern violations only

**Full mode**:
Run ALL in parallel:
1. `go-quality-assistant` — idiomatic Go, error handling, composition
2. `go-factory-pattern-assistant` — zero-logic factories, Create* prefix
3. `go-test-coverage-assistant` — test gaps, mock infrastructure

### Step 4b: CHANGELOG Review

If CHANGELOG.md was modified (check `git diff --name-only`), validate `## Unreleased` entries:

- Each entry starts with approved verb (capital): `Add` · `Fix` · `Update` · `Remove` · `Refactor` · `Improve`
- Entries are specific (name exact type, function, or package)
- Dependency updates include version numbers (`from vX to vY`)
- No vague entries (`fix bug`, `refactor`, `update deps`, `add tests`)
- No prompt filenames as entries
- Flat list under `## Unreleased` (no `### Added` subsections)

Flag violations as **Important (SHOULD FIX)**.

### Step 5: Consolidated Report

```markdown
## Code Review Summary

### make precommit
PASS | FAIL (details)

### Must Fix (Critical)
- Package function calls from business logic (use injected interface)
- Business logic in factory
- Missing error wrapping

### Should Fix (Important)
- Constructor returns concrete type
- Missing counterfeiter annotations
- Missing tests for critical components

### CHANGELOG
PASS | FAIL (list violations)

### Nice to Have
- GoDoc improvements
- Naming conventions
```
