# YOLO Container - Autonomous Execution Mode

You are running in an isolated Docker container with `--dangerously-skip-permissions` enabled.

## Critical Constraints

**Git:**
- **NO** Claude attribution in commits (no "Generated with Claude Code", no "Co-Authored-By")
- Use `cd path && git ...` (NEVER `git -C /path` - breaks auto-approval)
- Create new commits (don't amend unless explicitly blocked)

**Verification:**
- Use `make test` iteratively after each change (fast feedback loop, NOT `go build ./...`)
- Run `make precommit` ONCE at the very end as final validation before writing summary (it's slow: runs trivy + full linter suite)
- Tests must pass before declaring complete
- **Test coverage must be ≥80%** for every changed package. Check with `go test -cover ./pkg/...`
- Test ALL edge cases: empty input, missing frontmatter, special characters, error paths
- Never skip error path testing — if a function can fail, test the failure

**Code Quality:**
- Check project CLAUDE.md for specific patterns
- Read ALL relevant docs in `/home/node/.claude/docs/` (see Docs section below)
- Follow established patterns in the codebase

## Git Workflow

**Trading project** (`/workspace` mounted from `workspaces/trading`):
- NEVER run `make test`/`make precommit` at repo root — only in changed subdir
- Create feature branch from master, commit, push, create PR to master

**All other projects:**
- Read `/home/node/.claude/docs/git-workflow.md`
- NEVER commit directly to master

## Workflow

1. **Understand the prompt** - Read the task specification carefully
2. **Check conventions** - Read project CLAUDE.md and relevant coding guidelines
3. **Implement** - Follow all success criteria from the prompt
4. **Verify iteratively** - Run `make test` after each meaningful change (fast, repeat as needed)
5. **Self-review** - Before final validation, check your changes against the self-review checklist below
6. **Final validate** - Run `make precommit` ONCE only when everything is done (slow — trivy + full linter)

## Self-Review Checklist (Go projects)

Before running `make precommit`, review your own diff (`git diff`) against these rules:

**Composition** (from `go-composition.md`):
- [ ] No `pkg.Function()` calls from business logic — use injected interfaces
- [ ] All deps visible in constructor params
- [ ] Interfaces are small (1-2 methods)

**Factory** (from `go-factory-pattern.md`):
- [ ] Factory has zero business logic (no loops, no switch, no conditionals)
- [ ] Factory functions use `Create*` prefix
- [ ] Constructors return interfaces, not concrete types

**Patterns** (from `go-patterns.md`):
- [ ] Public interface + private struct + `New*` constructor
- [ ] Counterfeiter annotations on all interfaces
- [ ] Errors wrapped with `errors.Wrap(ctx, err, "message")`

**Testing** (from `go-testing.md`):
- [ ] Coverage ≥80% for changed packages
- [ ] Error paths tested
- [ ] Counterfeiter mocks (never manual mocks)
- [ ] External test packages (`package_test`)

If any check fails, fix it before proceeding to `make precommit`.

**Note:** YOLO does NOT commit or push. Management session handles git operations (has GPG key and credentials).

## Prompt Management

After executing a prompt via `/run-prompt`:
- Completed prompts are archived to `prompts/completed/`
- Management session will commit them (not YOLO)

## Completion Protocol

When task is complete:
1. **Summary** - Clearly state what was implemented
2. **Blockers** - List any issues encountered
3. **Verification** - Confirm all tests pass
4. **Exit suggestion** - Say: "Type /exit to close container"

## Docs (`/home/node/.claude/docs/`)

Project-specific conventions AI wouldn't know. Read ALL relevant docs before implementing.

**Go project** (has go.mod) — read all `go-*.md`:
| Doc | What you learn |
|-----|---------------|
| `go-patterns.md` | Interface→Constructor→Struct, error wrapping, counterfeiter, pointer utils |
| `go-testing.md` | Ginkgo/Gomega suite files, counterfeiter mocks, coverage ≥80% |
| `go-factory-pattern.md` | `Create*` prefix, zero logic, constructor pattern, Factory vs Runner |
| `go-enum-pattern.md` | String enums: `Available*`, `Validate()`, plural type, `Contains()` |
| `go-functional-composition.md` | `XxxFunc` + `XxxList` for composable interfaces |
| `go-validation.md` | `validation.All/Any/Name` from `github.com/bborbe/validation` |
| `go-composition.md` | Compose small services via DI, never call package functions directly |

**All projects:**
| Doc | What you learn |
|-----|---------------|
| `git-workflow.md` | Never commit in dark-factory, branch naming, changelog format |

**Python project** (has pyproject.toml): Use pytest, follow Python conventions.

**Shell project** (*.sh files): Use shellcheck.

See `docs/README.md` for guide on maintaining these docs.

## Commands & Agents

**Commands** (`/home/node/.claude/commands/`):
| Command | Purpose |
|---------|---------|
| `/code-review` | Review changes (short=1 agent, full=4 agents) |
| `/code-review full` | Thorough review with all agents |

**Agents** (`/home/node/.claude/agents/`):
| Agent | Purpose |
|-------|---------|
| `simple-bash-runner` | Execute shell commands, return pass/fail |
| `go-quality-assistant` | Idiomatic Go, error handling, composition |
| `go-factory-pattern-assistant` | Zero-logic factories, Create* prefix |
| `go-test-coverage-assistant` | Test gaps, mock infrastructure |

Use `/code-review short` when prompt asks for review. The self-review checklist above runs on every prompt by default (no agents needed).

## Container Environment

You are isolated with:
- ✅ Access: GitHub, npm, Anthropic API, Go proxies
- ❌ No access: kubectl, production credentials, general internet
- ✅ Mounted: Project workspace at `/workspace`
- ✅ Cache: Go modules at `/home/node/go/pkg`

Work autonomously. No permission prompts. Implement completely.
