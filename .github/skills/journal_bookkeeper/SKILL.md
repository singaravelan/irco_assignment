---
name: journal_bookkeeper
description: Record important project decisions in the evidence decision log. Use when the user or AI makes a consequential architectural, implementation, data, infrastructure, security, or delivery decision.
---

# Journal Bookkeeper

Maintain `evidence/decision-log.json` as an append-only record of important project decisions.

## When to record a decision

Record decisions that materially constrain future work, such as:

- Choosing an architecture, technology, schema, deployment strategy, or interface.
- Accepting a significant trade-off or changing project scope.
- Selecting an approach after evaluating alternatives.
- Establishing a security, data-quality, performance, or operational requirement.
- Discarding a previously chosen approach for a documented reason.

Do not log routine edits, tool output, unapproved suggestions, or implementation details that do not affect future choices.

## Log format

Read and validate the existing JSON before editing it. Preserve every previous entry. If the file is missing, create this structure:

```json
{
  "schemaVersion": 1,
  "entries": []
}
```

Append one object for each decision:

```json
{
  "id": "decision-YYYYMMDD-NNN",
  "timestamp": "YYYY-MM-DDTHH:mm:ssZ",
  "decision": "A concise description of what was decided.",
  "source": "user",
  "rationale": "Why this decision was made.",
  "alternatives": ["An alternative that was considered, if any."],
  "evidence": ["Relevant file paths, commands, issue or PR references, or results."]
}
```

Use `source: "user"` when the user made or explicitly approved the decision. Use `source: "ai"` when the AI makes a documented decision during implementation. Use the current UTC time for `timestamp`, and a monotonically increasing three-digit sequence for entries on the same date.

## Updating rules

1. Summarize the decision precisely; do not copy a lengthy conversation.
2. Explain the rationale and include material trade-offs or rejected alternatives.
3. Link only relevant evidence; use repository-relative paths.
4. Append the entry without changing previous entries.
5. Validate the finished file as JSON.

If an existing log is malformed, report the parse error and do not overwrite it.
