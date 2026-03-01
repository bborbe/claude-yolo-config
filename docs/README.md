# claude-yolo docs guide

This directory contains coding guides optimized for AI consumption inside the claude-yolo Docker container. They are mounted at `/home/node/.claude/docs/` and auto-loaded by Claude Code.

## Purpose

These docs teach YOLO **project-specific conventions** that AI wouldn't know from general training. They are NOT general Go/Python tutorials.

## Design Principles

1. **Only what AI doesn't know** — skip standard language features, stdlib patterns, common frameworks. Focus on custom libraries (`github.com/bborbe/*`), naming conventions, project structure rules.
2. **Short** — max ~100 lines per doc. One pattern per file. No prose, just rules + examples.
3. **Show don't tell** — code examples > explanations. Good/bad examples are effective.
4. **Actionable** — checklists at the end. YOLO can verify compliance.
5. **Self-contained** — each doc works standalone. No cross-references to external docs that YOLO can't access.

## File Naming

`{language}-{pattern-name}.md` — e.g., `go-factory-pattern.md`, `go-enum-pattern.md`

Non-language-specific: `git-workflow.md`

## Structure Template

```markdown
# {Pattern Name}

One-line description.

## Core Pattern

```{lang}
// minimal complete example
```

## Rules / Key Points

1. Rule one
2. Rule two

## Good / Bad Examples (optional)

## Checklist (optional)
```

## Current Docs

| File | What YOLO learns |
|------|-----------------|
| `git-workflow.md` | Never commit in dark-factory, branch naming, changelog format |
| `go-factory-pattern.md` | `Create*` prefix, zero logic, constructor pattern, Factory vs Runner |
| `go-patterns.md` | Interface→Constructor→Struct, error wrapping, counterfeiter, pointer utils |
| `go-testing.md` | Ginkgo/Gomega setup, suite files, counterfeiter mocks, coverage ≥80% |
| `go-enum-pattern.md` | String enums with `Available*`, `Validate()`, plural collection type |
| `go-functional-composition.md` | `XxxFunc` + `XxxList` pattern for composable interfaces |
| `go-validation.md` | `validation.All/Any/Name` from `github.com/bborbe/validation` |
| `go-composition.md` | Compose small services via DI, never call package functions directly |
| `go-security-linting.md` | gosec rules: file perms, `#nosec` annotations, fix on first attempt |
| `go-precommit.md` | Linter limits (funlen 80, nestif 4, golines 100), banned packages, errcheck, license |

## When to Add a New Doc

Add when:
- YOLO repeatedly gets a pattern wrong across multiple prompts
- A custom library has non-obvious API conventions
- Project-specific naming/structure rules differ from standard Go

Don't add when:
- It's standard Go knowledge (error handling, goroutines, channels)
- It's well-documented stdlib/framework usage
- It's a one-off project-specific detail (put in project's CLAUDE.md instead)

## Source of Truth

Human-readable guides live in `~/Documents/workspaces/coding-guidelines/`. These YOLO docs are AI-optimized condensations of those guides. When updating, check the source guide first for accuracy.
