---
tags:
  - guide
  - git
  - documentation
---
Tags: [[Git Development Guide]] [[Git Commit Guide]]

---

Guide for writing consistent, useful CHANGELOG.md entries across Go projects.

## Goal

Produce changelog entries that are specific, scannable, and usable for automated version bumping via `/commit`.

## File Structure

```markdown
# Changelog

All notable changes to this project will be documented in this file.

Please choose versions by [Semantic Versioning](http://semver.org/).

* MAJOR version when you make incompatible API changes,
* MINOR version when you add functionality in a backwards-compatible manner, and
* PATCH version when you make backwards-compatible bug fixes.

## Unreleased

- Add X feature to Y type
- Fix Z returning wrong value on nil input

## v1.5.0

- Add FuncRunner interface for executing functions with custom behavior
- Fix WaiterUntil to handle equal times correctly
```

**Rules:**
- Preamble with SemVer explanation always present
- `## Unreleased` on feature branches — never a version number
- `## vX.Y.Z` on master — no date suffix
- Newest version first
- Flat list — no `### Added` / `### Fixed` categories

## Branch Workflow

| Branch | Section | Tag |
|--------|---------|-----|
| Feature branch | `## Unreleased` | Never |
| master | `## vX.Y.Z` (converted from Unreleased) | Yes |

The `/commit` skill handles this automatically.

## Entry Style

**Format:** `- <Verb> <what> [context]`

**Verbs:** `Add` · `Fix` · `Update` · `Remove` · `Refactor` · `Improve`

**Be specific:**
- Name the exact type, function, or package touched
- Include versions for dependency updates
- Add brief context for non-obvious changes

## Anti-Patterns

❌ `- update go and deps` — which Go version? which deps?
✅ `- Update Go from 1.25.5 to 1.26.0`
✅ `- Update github.com/bborbe/errors to v1.5.2`

❌ `- go mod update` — no information
✅ `- Update dependencies (sentry-go v0.36.2→v0.40.0, osv-scanner v2.2.4→v2.3.0)`

❌ `- refactor` — what was refactored?
✅ `- Refactor BackgroundRunner to use FuncRunner interface composition`

❌ `- add tests` — for what?
✅ `- Add comprehensive test suite for FuncRunner (8 new tests)`

❌ `- fix bug` — which bug?
✅ `- Fix WaiterUntil to handle equal times correctly (no longer waits when until == now)`

## Version Increment Rules

| Change type | Increment |
|-------------|-----------|
| Breaking API changes | Major (`vX.0.0`) — set manually |
| New features, API additions (backward compat) | Minor (`vX.Y.0`) |
| Bug fixes, dep updates, refactoring, docs | Patch (`vX.Y.Z`) |

## Merge Conflicts in Unreleased

Multiple feature branches writing to `## Unreleased` will conflict. Resolution is always: keep both bullet lists, remove markers.

```markdown
## Unreleased
- Feature A change
- Feature B change
```

## Validation

- [ ] Preamble present with SemVer link
- [ ] Feature branch uses `## Unreleased`, not a version number
- [ ] Each entry starts with a capital verb
- [ ] Dependency updates include version numbers
- [ ] No vague entries (`refactor`, `add tests`, `go mod update`)
- [ ] Newest version at top

## References

- [[Git Development Guide]] — branch and release workflow
- [[Git Commit Guide]] — commit message style
- `/commit` skill — automates Unreleased → version conversion
