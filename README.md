# Dark Factory Claude Code Configs

YOLO container configuration for [dark-factory](https://github.com/bborbe/dark-factory) autonomous execution.

## What is this?

**dark-factory** is an autonomous software development pipeline: prompts go in, working code comes out. It runs [claude-yolo](https://github.com/bborbe/claude-yolo) — Claude Code with `--dangerously-skip-permissions` inside an isolated Docker container.

This repo is the Claude configuration mounted into that container:

```
docker run ... -v ~/.claude-yolo:/home/node/.claude ...
```

Completely separate from your host `~/.claude` — YOLO gets its own instructions, agents, and commands.

## Structure

```
CLAUDE.md          — workflow instructions (auto-loaded by Claude Code)
settings.json      — Claude Code settings (model, permissions)
docs/              — coding guides (Go patterns, testing, git workflow)
agents/            — specialist sub-agents (quality, factory, testing)
commands/          — slash commands (/code-review, /run-prompt, etc.)
```

## How it works

```
human writes prompt
  -> dark-factory queues it
  -> YOLO container starts (mounts this config + project workspace)
  -> Claude Code executes autonomously with --dangerously-skip-permissions
  -> dark-factory commits, tags, pushes, creates PR
```

The Docker container provides the safety boundary: no kubectl, no SSH keys, no production credentials. Firewall restricts network to GitHub, Anthropic API, npm, and Go proxies only.

## Docs

| File | Purpose |
|------|---------|
| `docs/go-patterns.md` | Interface/constructor/struct, error wrapping, counterfeiter |
| `docs/go-testing.md` | Ginkgo/Gomega, counterfeiter mocks, coverage rules |
| `docs/go-factory-pattern.md` | Zero-logic factories, `Create*` prefix |
| `docs/go-composition.md` | DI composition, never call package functions directly |
| `docs/go-time-injection.md` | `libtime.CurrentDateTimeGetter`, `DateTime` over `time.Time`, `SetNow()` |
| `docs/go-enum-pattern.md` | String enums, `Available*`, `Validate()` |
| `docs/go-validation.md` | `validation.All/Any/Name` patterns |
| `docs/go-logging-guide.md` | `log/slog` for new projects, `glog` for existing, level mapping |
| `docs/go-security-linting.md` | gosec rules, file perms, `#nosec` |
| `docs/go-precommit.md` | Linter limits, banned packages, license headers |
| `docs/go-context-cancellation.md` | Non-blocking select in loops, error wrapping |
| `docs/go-http-handler.md` | Handler in `pkg/handler/`, factory in `pkg/factory/` |
| `docs/go-functional-options.md` | Variadic options, `WithX` funcs, naming |
| `docs/go-filter-pattern.md` | Functional filters, no-op, preprocess outside closure |
| `docs/go-parse-pattern.md` | `ParseX`/`ParseXDefault`, pointer returns |
| `docs/go-prometheus-metrics.md` | Interface metrics, init() registration, naming |
| `docs/go-service-patterns.md` | Provider vs Registry, interface design |
| `docs/go-test-types.md` | Unit vs Integration vs E2E decision tree |
| `docs/go-doc.md` | GoDoc comment conventions |
| `docs/go-json-error-handler.md` | JSON error responses, `WrapWithDetails` |
| `docs/go-error-wrapping.md` | `bborbe/errors` wrapping, never `fmt.Errorf`, never `context.Background()`, sentinel errors |
| `docs/git-workflow.md` | Branch naming, changelog format, PR rules |
| `docs/changelog-guide.md` | Entry format, prefixes, anti-patterns |

## Related

- [bborbe/dark-factory](https://github.com/bborbe/dark-factory) — Go daemon that orchestrates execution
- [bborbe/claude-yolo](https://github.com/bborbe/claude-yolo) — Docker image definition
