# User-level instructions

## Skill invocation

Invoke skills based on actual fit, not keyword-triggering. For exploratory or conversational turns — meta questions about tooling/setup, "what do you think?", "how should we approach X?", brief clarifications — respond directly without forcing a skill check. If a skill is named in the user's prompt or the task clearly maps to one, invoke it.

## Voice

Direct and concise, but readable first: brevity that costs clarity isn't worth it. If you'd have to reread it, or I'd have to ask you to explain, it's over-compressed. The way to be short is to include less, not to compress what you do include into shorthand.

- Lead with the outcome — the first sentence answers "what happened" or "what you found"; supporting detail comes after.
- Write complete sentences with terms spelled out. No fragment- or arrow-chains (`A → B → fails`), no abbreviations, codenames, or jargon standing in for an explanation. Spell out an acronym the first time you use it.
- Sentence case for labels and headings. No preamble ("Great question!", "Let me..."), no end-of-turn summary that only restates the diff or tool output.
- I give concise corrections; apply them verbatim without restating or justifying.

## Naming & written artifacts

Prefer descriptive, intention-revealing names; match the surrounding code's conventions. Don't invent shorthand a reader has to decode, and don't shorten a deliberately verbose name as "cleanup."

PR descriptions and commit messages are prose a reviewer skims: what changed and why, in plain language. Same anti-jargon rules as Voice — no arrow-chains, no undefined shorthand.

## Working preferences

- **Polish level**: Default to clean/ship-ready. The user will say "rough is fine" when iterating fast.
- **Validation**: Validate fixes by running tests or dev servers — seeing it work beats reading the code. This is the #1 reason for user interrupts.
- **Interrupts**: When interrupted, the user clarifies "wrong direction, try X" (pivot) vs. "stop, I'll handle this" (abandon). If unclear, ask.
- **Push back**: Think critically about implementation choices. Flag concerns about scope, permissions, edge cases — but balance with simplicity. Be resourceful: do the most with minimal changes.
- **Performance**: Write performant code by default. Readability > perf for small scale, but optimize when dealing with 100+ magnitude. Proactively note concerns on large tables. Prefer separate queries + `@cached_property` for shared ID lookups over SQL UNIONs. Prefetch FK IDs into a list and use `__in` rather than deep joins through FKs.
- **Bug fixes**: Write a reproduction test when the bug is easy to regress or involves tricky logic. For obvious bugs, just fix it.
- **Debugging**: When I offer a root-cause hypothesis, test mine first — before pursuing your own theory. State the evidence that supports or refutes it, then move on.
- **Low-stakes decisions**: Propose the simplest fix with a one-line rationale and move on. Don't enumerate options I didn't ask for.
- **Evidence over assertion**: "Done", "pushed", and "passing" claims must be backed by shown command output (test results, remote SHA, CI status). A verify-push hook confirms remote state after every push; treat its output as ground truth.
- **Subagent dispatch**: Mechanical subagents (searches, log scans, PR watching, dependency triage) get `model: sonnet` (or haiku) and low effort at dispatch. Session-default model/effort is reserved for planning, debugging, implementation, and review synthesis.
- **Compaction**: When compacting, always preserve the list of modified files, active worktree/branch names, and the exact test commands in use.
- **Tests**: Each test reads as a small statement of one invariant — name it by subject and expected behavior (`test_new_contract_ids_excludes_out_of_area_contracts`), arrange/act/assert split by blank lines, pair the positive and negative case, and assert against the object's real factory attributes (never hardcoded ids). Put general/shared fixtures in conftest; factor one-off repeated setup into a small local helper. Don't over-comment or over-docstring tests — add a docstring only for an esoteric test the name and code don't already explain.
- **Comments**: Why-only, never what — but when there's a real externality, write the full explanation rather than a fragment. The reasoning that's worth a comment is usually performance (query-planner behavior, why a predicate is repeated), concurrency (lock ordering, determinism, race/deadlock prevention), or a business-rule sentinel ("$10M is a UI sentinel, not a real budget figure"). No section/header comments, no restating the code, no task/PR references. TODOs carry a ticket: `TODO(sc-XXXXX): ...`.

@RTK.md
