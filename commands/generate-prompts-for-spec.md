---
description: Generate dark-factory prompt files from an approved spec (non-interactive)
argument-hint: <spec-file>
allowed-tools: [Read, Write, Glob, Bash]
---

Read the spec file at `/workspace/$ARGUMENTS`.

Extract the spec number from the filename (e.g. `020` from `020-auto-prompt-generation.md`).

Read 3-5 recent completed prompts from `/workspace/prompts/completed/` (pick the highest-numbered ones) to understand the prompt style, XML tag structure, and level of detail expected.

Use Glob to find all files in `/workspace/prompts/*.md` and `/workspace/prompts/completed/*.md`. Determine the highest existing prompt number so new prompts do not conflict.

Read the spec carefully. Identify:
- Desired Behaviors (numbered list) — these drive decomposition
- Constraints — must be repeated in every prompt
- Acceptance Criteria — used in verification sections

Decompose the spec into 2–6 prompt files. Group coupled behaviors that cannot be verified independently into the same prompt. Sequence them so each prompt's postconditions are the next prompt's preconditions.

For each prompt, write a file to `/workspace/prompts/<slug>.md` where `<slug>` uses alphabetical ordering prefixes so dark-factory processes them in the correct sequence (e.g. `spec-020-1-foo.md`, `spec-020-2-bar.md`).

Each file must start with this exact frontmatter:
```
---
spec: ["NNN"]
status: created
created: "<current UTC timestamp in ISO8601 format>"
---
```
where `NNN` is the zero-padded spec number (e.g. `"020"`).

After the frontmatter, write the prompt body using XML tags:

```xml
<objective>
WHAT to build and WHY (1-3 sentences). State the end state, not the steps.
</objective>

<context>
Read CLAUDE.md for project conventions.
List specific files to read before making changes.
</context>

<requirements>
Numbered, specific, unambiguous steps. Include exact file paths, function signatures, and import paths.
</requirements>

<constraints>
- Repeat relevant constraints from the spec — the agent has no memory between prompts
- Do NOT commit — dark-factory handles git
- Existing tests must still pass
</constraints>

<verification>
Run `make precommit` — must pass.
Any additional verification commands.
</verification>
```

Rules:
- Specificity over brevity — longer prompts are almost always better
- Always include exact file paths and function signatures
- Always copy constraints from the spec into each prompt
- Do NOT add frontmatter fields beyond spec/status/created — dark-factory adds the rest
- Do NOT place prompts in `/workspace/prompts/queue/` — inbox only
- The `spec` field must be a YAML array: `spec: ["020"]` not `spec: "020"`
