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
| `docs/go-enum-pattern.md` | String enums, `Available*`, `Validate()` |
| `docs/go-validation.md` | `validation.All/Any/Name` patterns |
| `docs/go-security-linting.md` | gosec rules, file perms, `#nosec` |
| `docs/go-precommit.md` | Linter limits, banned packages, license headers |
| `docs/git-workflow.md` | Branch naming, changelog format, PR rules |
| `docs/changelog-guide.md` | Entry format, prefixes, anti-patterns |

## Related

- [bborbe/dark-factory](https://github.com/bborbe/dark-factory) — Go daemon that orchestrates execution
- [bborbe/claude-yolo](https://github.com/bborbe/claude-yolo) — Docker image definition
