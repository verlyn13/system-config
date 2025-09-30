# Dashboard Integration Checklist

## Steps

1) Generate Bridge client (optional if already vendored)

```
./scripts/generate-openapi-client.sh src/generated/bridge-client http://127.0.0.1:7171/openapi.yaml
```

2) Start dev server

```
npm run dev
```

3) Validate pages

- Contracts: schemas + registry (ETag-aware fetch, raw toggle)
- Docs: DS/MCP status cards
- Projects grid/table: readiness chips
- Project detail: Manifest/Integration with checkedAt and summary chips

4) SSE validation

- Connect EventSource to `/api/events/stream`
- Validate `ProjectObsCompleted` and `SLOBreach` via Ajv before rendering

