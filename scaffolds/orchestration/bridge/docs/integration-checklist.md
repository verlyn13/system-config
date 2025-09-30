# Bridge Integration Checklist

## Steps

1) Start Bridge (dev, strict + CORS)

```
./scripts/run-bridge-dev.sh
```

2) Validate typed endpoints

```
node scripts/validate-endpoints.js
PROJECT_ID=<id> node scripts/validate-endpoints.js
```

3) Validate DS contracts (if DS available)

```
DS_BASE_URL=http://127.0.0.1:7777 DS_TOKEN=<token> node scripts/ds-validate.mjs
```

4) Discovery & Observers

```
./scripts/run-discovery.sh
./scripts/run-observers-all.sh
```

5) SSE watch

```
node scripts/sse-listen.js
```

