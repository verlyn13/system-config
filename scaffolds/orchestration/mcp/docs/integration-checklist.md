# MCP Server Integration Checklist

## Steps

1) Start MCP server

```
mise run serve
```

2) Discovery and aliases

```
curl -sS http://127.0.0.1:PORT/api/obs/discovery/services | jq .
curl -sS http://127.0.0.1:PORT/api/obs/discovery/openapi | jq .
```

3) Self-status

```
curl -sS http://127.0.0.1:PORT/api/self-status | jq .
```

4) OpenAPI served

```
curl -I http://127.0.0.1:PORT/openapi.yaml
```

