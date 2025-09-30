# DS CLI Integration Checklist

## Steps

1) Start DS (secure)

```
DS_TOKEN=<token> DS_CORS=1 mise run serve-secure
```

2) Self-status and capabilities

```
curl -sS http://127.0.0.1:7777/api/self-status | jq .
curl -sS http://127.0.0.1:7777/v1/health | jq .
curl -sS http://127.0.0.1:7777/v1/capabilities | jq .
```

3) Verify contracts script (if present)

```
./scripts/verify-ds-services.sh http://127.0.0.1:7777
```

4) Example client

```
go run ./examples/go-client
```

