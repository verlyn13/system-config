# System Hardening Checklist

**Focus**: Local-Only System Reliability & Self-Management
**Last Updated**: 2025-09-28

## ✅ Completed Hardening

### Data Persistence & Recovery
- [x] **Audit Checkpointing** - Every 60s (SQLite WAL persistence)
- [x] **Registry Persistence** - Project discovery writes to disk
- [x] **Configuration Backup** - Git-tracked in system-setup-update

### Resource Management
- [x] **Audit Retention** - Automatic cleanup every 6 hours
- [x] **Repository Cache Pruning** - Daily cleanup of old caches
- [x] **Log Rotation** - NDJSON files with size limits

### Input Validation
- [x] **Observer Validation** - Only allows git|mise|build|sbom
- [x] **Path Validation** - Observers validate allowed roots
- [x] **URL Redaction** - Credentials removed from logs
- [x] **Schema Validation** - JSON Schema for all contracts

### Performance Optimization
- [x] **Targeted Observers** - Run only requested checks
- [x] **Project Filtering** - Query optimization for large lists
- [x] **Discovery Caching** - Registry file updated hourly
- [x] **Timeout Protection** - All observers have 5s timeout

### Telemetry & Monitoring
- [x] **Enhanced Attributes** - Detectors and observer tracking
- [x] **OTLP Integration** - Logs, metrics, traces to local collector
- [x] **Event Streaming** - SSE for real-time updates
- [x] **Health Endpoints** - Multiple health check APIs

## 🔄 In Progress

### Database Optimization
- [ ] **Daily SQLite VACUUM** - Scheduled database optimization
- [ ] **WAL Compaction** - For sqlite_wasm persistence
- [ ] **Index Optimization** - Performance tuning for queries

### Self-Diagnostics
- [ ] **Self-Status Resource** - devops://self_status endpoint
  - Config modification time
  - OTLP reachability status
  - Recent audit errors
  - Last maintenance timestamp

### Resilience Improvements
- [ ] **Retry Logic** - Exponential backoff for git operations
- [ ] **Circuit Breakers** - Prevent cascade failures
- [ ] **Graceful Degradation** - Continue with partial data

### Log Management
- [ ] **Size Capping** - Prevent oversized OTLP events
- [ ] **Drop Counter** - Track discarded oversized logs
- [ ] **Log Compression** - Archive old observation logs

## 📋 Maintenance Schedule

### Every Minute
- Audit checkpoint (data persistence)

### Every Hour
- Project discovery (workspace scan)
- Observer runs (configured projects)
- SLO evaluation (threshold checks)

### Every 6 Hours
- Audit retention (cleanup old records)

### Daily
- Repository cache pruning
- SQLite VACUUM (planned)
- Log rotation and compression

### Weekly
- Full system validation
- Metric aggregation
- Trend analysis

## 🛠 Manual Maintenance

### Trigger Maintenance Tasks
```bash
# Via MCP tool
mcp call server_maintain

# Via HTTP API
curl -X POST http://localhost:7171/api/tools/server_maintain

# Via CLI script
./scripts/maintenance-run.sh
```

### Check System Health
```bash
# Overall health
curl http://localhost:7171/api/health

# Project health
curl http://localhost:7171/api/tools/project_health

# Telemetry info
curl http://localhost:7171/api/telemetry-info
```

### Force Discovery
```bash
# Re-discover all projects
curl http://localhost:7171/api/discover

# With custom depth
curl -X POST http://localhost:7171/api/tools/project_discover \
  -d '{"maxDepth": 3}'
```

## 🚨 Monitoring Points

### Critical Metrics
1. **Checkpoint Success Rate** - Should be 100%
2. **Discovery Project Count** - Should be stable (~37)
3. **Observer Latency** - Should be <5s per observer
4. **Audit Size** - Should stay under 100MB

### Alert Conditions
- Checkpoint failures > 0
- Project count drops > 10%
- Observer timeouts > 20%
- Audit size > 200MB

### Log Patterns to Watch
```bash
# Check for errors
grep "error" ~/.local/share/devops-mcp/logs/*.ndjson

# Check maintenance status
grep "server_maintain" ~/.local/share/devops-mcp/logs/*.ndjson

# Check observer failures
grep "observer.*fail" ~/.local/share/devops-mcp/logs/*.ndjson
```

## 🔒 Security Hardening (Local Focus)

### Already Implemented
- [x] Path traversal prevention
- [x] Credential redaction in logs
- [x] Input validation on all endpoints
- [x] Sandbox constraints for observers

### Not Required (Local-Only)
- ~~Authentication/Authorization~~ - Local system only
- ~~HTTPS/TLS~~ - Localhost only
- ~~Rate limiting~~ - Single user
- ~~CORS headers~~ - Local access only

## 📊 Performance Baselines

### Expected Performance
- **Discovery**: <2s for 40 projects
- **Observer Run**: <5s per observer
- **API Response**: <100ms for cached data
- **Checkpoint**: <50ms per operation

### Current Performance
- Discovery: ~1.5s ✅
- Observer Run: 2-4s ✅
- API Response: ~20ms ✅
- Checkpoint: ~30ms ✅

## 🔄 Recovery Procedures

### If Discovery Fails
```bash
# Manual discovery
bash scripts/project-discover.sh

# Check registry
cat ~/.local/share/devops-mcp/project-registry.json | jq '.discovered'
```

### If Observers Hang
```bash
# Kill hung processes
pkill -f "observer.sh"

# Run with timeout
timeout 5 bash observers/repo-observer.sh PROJECT_PATH PROJECT_ID
```

### If Database Corrupted
```bash
# Backup current
cp ~/.local/share/devops-mcp/audit.db{,.backup}

# Reset database
rm ~/.local/share/devops-mcp/audit.db
# Will recreate on next run
```

## ✅ Validation Tests

```bash
# Run all validation tests
./scripts/validate-system.sh

# Test observers
./test-observers.sh

# Test discovery
node test-project-discovery.js

# Test maintenance
curl -X POST http://localhost:7171/api/tools/server_maintain
```

## 📈 Success Metrics

- **Uptime**: System available 99.9% of time
- **Data Loss**: Zero data loss events
- **Auto-Recovery**: 100% of transient failures
- **Maintenance**: All tasks complete successfully
- **Performance**: All operations within baselines

---

*This checklist ensures the system is hardened for reliable, autonomous operation as a local development environment manager.*