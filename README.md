# Dark Factory Claude Code Configs

YOLO container configuration for [dark-factory](https://github.com/bborbe/dark-factory) autonomous execution.

## What is this?

**dark-factory** is an autonomous software development pipeline: prompts go in, working code comes out. It runs [claude-yolo](https://github.com/bborbe/claude-yolo) — Claude Code with `--dangerously-skip-permissions` inside an isolated Docker container.

This repo is the Claude configuration mounted into that container:

```
docker run ... -v ~/.claude-yolo:/home/node/.claude ...
```

Completely separate from your host `~/.claude` — YOLO gets its own instructions and plugins.

## Structure

```
CLAUDE.md          — workflow instructions (auto-loaded by Claude Code)
settings.json      — Claude Code settings (plugins, permissions)
plugins/           — marketplace plugins (coding, dark-factory)
```

## Setup

After cloning this repo to `~/.claude-yolo`, install the required plugins:

```bash
cd ~/.claude-yolo/plugins/marketplaces
git clone https://github.com/bborbe/coding.git coding
git clone https://github.com/bborbe/dark-factory.git dark-factory
```

To update plugins:

```bash
cd ~/.claude-yolo/plugins/marketplaces/coding && git pull
cd ~/.claude-yolo/plugins/marketplaces/dark-factory && git pull
```

## Authentication

The YOLO Claude session needs its **own** OAuth token, **separate from your host `~/.claude` login**. The token lives in `~/.claude-yolo/.credentials.json` (or `.claude.json` on older versions) and is what `dark-factory` (and every other tool that mounts this dir) presents to Anthropic.

Tokens expire periodically — when they do, every prompt fails with `Claude OAuth token missing or expired in /Users/<you>/.claude-yolo` and the daemon refuses to start any container.

**Refresh the token** — recommended path, inside an interactive YOLO container so the environment matches what dark-factory uses:

```bash
cd ~/Documents/workspaces/claude-yolo
./scripts/yolo-run.sh
# inside the Claude session, type:
/login
# follow the device-code flow in your browser; on success the container reports
# "Login successful". Exit the session — ~/.claude-yolo/.credentials.json is updated.
```

Host-only alternative (no container):

```bash
CLAUDE_CONFIG_DIR=~/.claude-yolo claude
# inside the session, run /login as above
```

Both paths write the same file. Commit nothing back to this repo — `.credentials.json` is gitignored (and must stay that way; it is a secret).

**Verify auth is good** (host-side spot check):

```bash
ls -l ~/.claude-yolo/.credentials.json   # exists and mtime is recent
```

If `dark-factory` keeps failing with the OAuth error after a fresh `/login`, the token may have been refreshed in `~/.claude` instead of `~/.claude-yolo` — re-run the login with `CLAUDE_CONFIG_DIR=~/.claude-yolo` explicitly set.

## Plugins

All docs, agents, and commands are served from marketplace plugins:

| Plugin | Provides |
|--------|----------|
| [coding](https://github.com/bborbe/coding) | Coding guidelines (`docs/go-*.md`), quality agents, `/coding:code-review` |
| [dark-factory](https://github.com/bborbe/dark-factory) | `/dark-factory:generate-prompts-for-spec`, `/dark-factory:run-prompt`, spec/prompt management |

## How it works

```
human writes prompt
  -> dark-factory queues it
  -> YOLO container starts (mounts this config + project workspace)
  -> Claude Code executes autonomously with --dangerously-skip-permissions
  -> dark-factory commits, tags, pushes, creates PR
```

The Docker container provides the safety boundary: no kubectl, no SSH keys, no production credentials. Firewall restricts network to GitHub, Anthropic API, npm, and Go proxies only.

## Related

- [bborbe/dark-factory](https://github.com/bborbe/dark-factory) — Go daemon that orchestrates execution
- [bborbe/claude-yolo](https://github.com/bborbe/claude-yolo) — Docker image definition
- [bborbe/coding](https://github.com/bborbe/coding) — Coding guidelines and quality agents
