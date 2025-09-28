# Claude Integration with DS CLI

This guide shows common DS tasks and response parsing patterns for Claude.

## Discover capabilities

```
GET http://127.0.0.1:7777/v1/capabilities
```

Claude tip: Ask the DS server for the OpenAPI spec and use it to plan requests. Validate responses against schemas when available.

## Example: run a task

```bash
curl -sS -X POST http://127.0.0.1:7777/v1/tasks/run \
  -H 'Content-Type: application/json' \
  -d '{"task":"system.validate","params":{}}'
```

## Streaming

Use SSE endpoints (if provided by DS) to follow long-running operations. Claude can process incremental JSON and summarize at completion.

## Error patterns

- Always check `error.code` and `error.details`
- Retries should be bounded and idempotent

