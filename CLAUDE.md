# YOLO Container - Autonomous Execution Mode

You are running in an isolated Docker container with `--dangerously-skip-permissions` enabled.

## Critical Constraints

**Git:**
- **NO** Claude attribution in commits (no "Generated with Claude Code", no "Co-Authored-By")
- Use `cd path && git ...` (NEVER `git -C /path` - breaks auto-approval)
- Create new commits (don't amend unless explicitly blocked)
- **NEVER change the git remote URL** (no `git remote set-url`, no switching SSH↔HTTPS). If fetch/push fails due to network/auth, report the failure in the completion report — do NOT work around it by mutating remotes. The remote is configured by the host; rewriting it masks container networking issues and can push work to the wrong place.

**Verification:**
- Use `make test` iteratively after each change (fast feedback loop, NOT `go build ./...`)
- Run `make precommit` ONCE at the very end as final validation (it's slow: runs trivy + full linter suite)
- **Multi-service repos:** ONLY run `make test`/`make precommit` in the service directory that was changed — NEVER at repo root. If only YAML/config changed (no Go code), skip `make precommit` entirely and use the prompt's `<verification>` commands instead.
- **If `make precommit` fails:** fix the issue, then re-run ONLY the failing target (e.g., `make lint`, `make gosec`, `make errcheck`). Do NOT re-run full `make precommit` until all individual targets pass.
- Only re-run `make precommit` once all individual fixes are verified
- Tests must pass before declaring complete
- **CRITICAL: If `make precommit` has a non-zero exit code, you MUST report `"status":"failed"` in the completion report.** Never rationalize a failed `make precommit` as success — even if the failure seems pre-existing or unrelated to your changes. A non-zero exit code = failed, no exceptions.
- **Test coverage** — see `docs/definition-of-done.md` for full rules:
  - New code: ≥80% statement coverage
  - Modified code: test all changed/added code paths (existing untested code needs no retroactive coverage)
  - Check with `go test -coverprofile=/tmp/cover.out -mod=vendor ./affected/pkg/... && go tool cover -func=/tmp/cover.out`
- Test ALL edge cases: empty input, missing frontmatter, special characters, error paths
- Never skip error path testing — if a function can fail, test the failure

**Bash:**
- **NEVER run commands in the background.** Always foreground. Background tasks produce empty output files, force wasteful polling loops, and hide errors. If a tool has a `--verbose` or streaming flag, use it (e.g., `updater --verbose --yes go`) so output is visible inline.
- **NEVER use `tail -f`** — it blocks forever and prevents the container from exiting. Use `cat` or `sleep N && cat` to read files.
- **NEVER use `watch`** — same problem, blocks indefinitely.
- If you absolutely must poll a file, use `sleep 30 && cat <file>`, not `tail -f <file>`. But prefer foreground execution over polling.

**File size:**
- **Reading**: files > ~2,000 lines exceed the Read tool's 25k-token limit and require `offset`/`limit` chunked reads. Use `grep -n` to locate the section first, then read 200-500 lines around the match. Never re-attempt the full read — it will fail again.
- **Writing**: a Go file > 1,500 lines is borderline; > 2,000 lines is a smell; > 3,000 lines is a structural problem. Split into focused files in the same package — `<pkg>_queue_test.go`, `<pkg>_recovery.go`, `<pkg>_test_helpers.go`, etc. Generated mocks/protobuf are exempt.
- If a prompt asks you to grow a file past 2,000 lines, flag in `## Improvements`: "file X is N lines and should be split before further additions".

**Code Quality:**
- Check project CLAUDE.md for specific patterns
- Read ALL relevant docs in `/home/node/.claude/plugins/marketplaces/coding/docs/` (see Docs section below)
- Follow established patterns in the codebase

## Git Workflow

**Trading project** (`/workspace` mounted from `workspaces/trading`):
- NEVER run `make test`/`make precommit` at repo root — only in changed subdir
- Create feature branch from master, commit, push, create PR to master

**All other projects:**
- Read `/home/node/.claude/plugins/marketplaces/coding/docs/git-workflow.md`
- NEVER commit directly to master

## Workflow

1. **Understand the prompt** - Read the task specification carefully
2. **Check conventions** - Read project CLAUDE.md AND all relevant `/home/node/.claude/plugins/marketplaces/coding/docs/go-*.md` docs
3. **Implement** - Follow all success criteria from the prompt
4. **Verify iteratively** - Run `make test` after each meaningful change (fast, repeat as needed)
5. **Self-review** - Check your diff (`git diff`) against the self-review checklist below
6. **Final validate** - Run `make precommit` ONCE when everything is done
7. **Fix loop** - If `make precommit` fails: fix → run ONLY the failing target (`make lint`, `make gosec`, etc.) → repeat until that target passes → try next failing target → when all pass, run `make precommit` one final time

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
- [ ] Errors wrapped with `errors.Wrapf(ctx, err, "message")` — never `context.Background()`, never `fmt.Errorf`

**Context cancellation** (from `go-context-cancellation-in-loops.md`):
- [ ] Loops with significant runtime have non-blocking `select` context check

**Concurrency** (from `go-concurrency-patterns.md`):
- [ ] No raw `go func()` — use `run.CancelOnFirstErrorWait`
- [ ] Channel passed as `chan<- T` param (caller owns it, not returned from method)
- [ ] Bounded producers use `defer close(ch)`; unbounded producers do NOT close

**HTTP handlers** (from `go-http-handler-refactoring-guide.md`):
- [ ] No inline handlers in main.go — all in `pkg/handler/`
- [ ] Factory methods follow `Create*Handler` naming

**Testing** (from `go-testing-guide.md`):
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

## Changelog

If the project has a `CHANGELOG.md`, write `## Unreleased` **immediately after implementing** (before running `make precommit`). Read `/home/node/.claude/plugins/marketplaces/coding/docs/changelog-guide.md` for full style rules.

**Quick rules:**
- Format: `- <prefix>: <what> [context]` — prefix is **required**
- Prefixes: `feat:` (new feature → minor bump), `fix:`, `refactor:`, `test:`, `docs:`, `chore:`, `perf:` (all → patch bump)
- One bullet per logical change (not per file)
- Be specific: name types, commands, packages — never write `- fix: fix bug` or `- chore: update deps`
- If `## Unreleased` already exists, append to it (don't replace)
- Dark-factory reads the prefix to determine the version bump automatically

**Common mistakes — do NOT do these:**
- ❌ Copy bash comments from the `<verification>` section (`# Confirm X`, `# Create a test...`) — those are test instructions, not changelog entries
- ❌ Use the prompt filename as the entry (`- 110-fix-spec-watcher-clean-shutdown`)
- ❌ Describe what you verified — describe what you **implemented**
- ✅ `- fix: Suppress noisy stack trace when SpecWatcher generation is cancelled by context on shutdown`

## Completion Protocol

The prompt includes a completion report template (appended by dark-factory). Write the report, then **STOP** — no summary, no explanation, no further output.

**Report rules:**
- `"status":"success"` — ONLY if `make precommit` exited with code 0
- `"status":"partial"` — code works but `make precommit` failed on unrelated issues
- `"status":"failed"` — implementation incomplete or tests fail
- Include `"verification":{"command":"make precommit","exitCode":N}` with the actual exit code
- **Never self-report success when any verification command failed**

## Reflection — Suggest Improvements

**Every run must end with an `## Improvements` markdown section appended AFTER the DARK-FACTORY-REPORT block.** This is the feedback loop — it's how prompts, guides, and rules get better over time.

Include anything that would make the next run of a similar prompt faster or more reliable:

- **Wasted time** — What did you do that turned out to be unnecessary? (e.g., "polled empty background-task output for 6 min")
- **Missing guidance** — Rules or facts you had to discover the hard way that should have been in the prompt or a guide
- **Stale docs** — Guide statements that contradict current reality
- **Patterns worth capturing** — New failure modes, new fix recipes, new rename tables

Format:

```markdown
## Improvements

- Prompt should specify `updater --verbose` — without it, errors are opaque
- Guide `/docs/howto/go-deps-update-guide.md` should add `SomeOldName → SomeNewName` rename to the table
- Consider moving X rule from prompt body to project CLAUDE.md (duplicated across N prompts)
```

If there is genuinely nothing to suggest, write `## Improvements\n\n- None` — do not skip the section.

## Docs (coding plugin)

Coding guidelines live in the **coding marketplace plugin**: `/home/node/.claude/plugins/marketplaces/coding/docs/`

Read ALL relevant docs before implementing.

**Go project** (has go.mod) — read all `go-*.md`:
| Doc | What you learn |
|-----|---------------|
| `go-patterns.md` | Interface→Constructor→Struct, error wrapping, counterfeiter, pointer utils |
| `go-testing-guide.md` | Ginkgo/Gomega suite files, counterfeiter mocks, coverage ≥80% |
| `go-factory-pattern.md` | `Create*` prefix, zero logic, constructor pattern, Factory vs Runner |
| `go-enum-type-pattern.md` | String enums: `Available*`, `Validate()`, plural type, `Contains()` |
| `go-functional-composition-pattern.md` | `XxxFunc` + `XxxList` for composable interfaces |
| `go-validation-framework-guide.md` | `validation.All/Any/Name` from `github.com/bborbe/validation` |
| `go-composition.md` | Compose small services via DI, never call package functions directly |
| `go-time-injection.md` | `libtime.CurrentDateTimeGetter` injection, `DateTime` over `time.Time`, `SetNow()` in tests |
| `go-logging-guide.md` | `log/slog` for new projects, `glog` for existing; V(2)=heartbeat, V(3)=per-item, V(4)=trace; `github.com/bborbe/log` sampling; `/setloglevel` endpoint |
| `go-concurrency-patterns.md` | `run.CancelOnFirstErrorWait` over `go func()`, caller-owned channels, `collection.ChannelFnMap/List`, bounded vs unbounded producers |
| `go-security-linting.md` | gosec rules: file perms `0600`/`0750`, `#nosec` with reasons, fix on first attempt |
| `go-precommit.md` | Linter limits (funlen 80, nestif 4, golines 100), banned packages, errcheck, license headers |
| `go-context-cancellation-in-loops.md` | Non-blocking select in loops, when to apply, error wrapping |
| `go-http-handler-refactoring-guide.md` | Handler in `pkg/handler/`, factory in `pkg/factory/`, no inline handlers |
| `go-functional-options-pattern.md` | Variadic options pattern, `WithX` funcs, naming conventions |
| `go-filter-pattern.md` | Functional filters, no-op for empty, preprocess outside closure |
| `go-parse-pattern.md` | `ParseX`/`ParseXDefault` from `any`, pointer returns, validation |
| `go-prometheus-metrics-guide.md` | Interface-based metrics, registration in init(), naming, labels |
| `go-service-implementation-patterns.md` | Provider vs Registry, interface design, package organization |
| `go-test-types-guide.md` | Unit vs Integration vs E2E, dependency patterns, decision tree |
| `go-doc-best-practices.md` | GoDoc comments: start with name, full sentences, behavior not impl |
| `go-json-error-handler-guide.md` | JSON error responses, error codes, `WrapWithDetails`, factory integration |
| `go-error-wrapping-guide.md` | `bborbe/errors` API, never `fmt.Errorf`, never `context.Background()` in pkg/, sentinel errors with `stderrors` alias |
| `go-cqrs.md` | Command-Result pattern, `RunCommandConsumerTx` auto-wraps, result topic, `ErrCommandObjectSkipped` |

**All projects:**
| Doc | What you learn |
|-----|---------------|
| `git-workflow.md` | Never commit in dark-factory, branch naming, changelog format |
| `changelog-guide.md` | Entry format, verb style, anti-patterns, `## Unreleased` rules |
| `definition-of-done.md` | Test coverage rules (new vs modified code), verification, completion criteria |

**Python project** (has pyproject.toml): Use pytest, read `python-*.md` docs.

**Shell project** (*.sh files): Use shellcheck.

## Commands & Agents (from marketplace plugins)

**coding plugin** (`/coding:*`):
| Command | Purpose |
|---------|---------|
| `/coding:code-review` | Review changes (short=1 agent, full=4 agents) |
| `/coding:pr-review` | Review PR changes |

**dark-factory plugin** (`/dark-factory:*`):
| Command | Purpose |
|---------|---------|
| `/dark-factory:generate-prompts-for-spec` | Generate prompts from approved spec |
| `/dark-factory:run-prompt` | Execute a prompt in YOLO container |

**Agents** (from coding plugin):
| Agent | Purpose |
|-------|---------|
| `simple-bash-runner` | Execute shell commands, return pass/fail |
| `go-quality-assistant` | Idiomatic Go, error handling, composition |
| `go-factory-pattern-assistant` | Zero-logic factories, Create* prefix |
| `go-test-coverage-assistant` | Test gaps, mock infrastructure |

Use `/coding:code-review short` when prompt asks for review. The self-review checklist above runs on every prompt by default (no agents needed).

## Container Environment

You are isolated with:
- ✅ Access: GitHub, npm, Anthropic API, Go proxies
- ❌ No access: kubectl, production credentials, general internet
- ✅ Mounted: Project workspace at `/workspace`
- ✅ Cache: Go modules at `/home/node/go/pkg`

Work autonomously. No permission prompts. Implement completely.
