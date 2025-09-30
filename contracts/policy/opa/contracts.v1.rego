# Contract-First Architecture Policy Framework
# OPA Rego implementation for mechanical contract enforcement
# Version: 1.1.0

package contracts.v1

import rego.v1
import data.contracts.schemas
import data.contracts.mappings

# ==============================================================================
# CORE CONTRACT METADATA
# ==============================================================================

# Contract version enforcement
contract_metadata := {
  "version": "v1.1.0",
  "schema": "obs.v1",
  "api_version": "2025-09-28",
  "policy_version": "1.0.0",
  "opa_version": "0.68.0"
}

# Schema version requirements
required_schema_version := "https://json-schema.org/draft/2020-12/schema"

# ==============================================================================
# OBSERVER POLICY FRAMEWORK
# ==============================================================================

package contracts.v1.observers

# Valid external observers (public API contract)
valid_external_observers := {"git", "mise", "sbom", "build", "manifest"}

# Valid internal observers (implementation detail)
valid_internal_observers := {"repo", "deps", "quality"} | valid_external_observers

# Observer mapping rules
observer_mapping := {
  "repo": "git",
  "deps": "mise",
  "quality": null  # Never mapped (internal only)
}

# Rule: Check if observer is valid for external API
default allow_external_observer = false

allow_external_observer if {
  input.observer in valid_external_observers
}

# Rule: Map internal observer to external
map_observer(internal) := external if {
  internal in observer_mapping
  external := observer_mapping[internal]
  external != null
}

map_observer(observer) := observer if {
  observer in valid_external_observers
}

# Rule: Block quality observer from external exposure
deny_external_quality if {
  input.context == "external_api"
  input.observer == "quality"
}

# Rule: Validate observer transformation at boundary
validate_boundary_crossing if {
  input.source == "internal"
  input.target == "external"
  internal_observer := input.observer
  external_observer := map_observer(internal_observer)
  external_observer != null
}

# ==============================================================================
# OBSERVATION VALIDATION POLICIES
# ==============================================================================

package contracts.v1.observations

# Rule: Validate observation structure
default valid_observation = false

valid_observation if {
  # Required fields check
  required_fields := {
    "apiVersion", "run_id", "timestamp", 
    "project_id", "observer", "summary", 
    "metrics", "status"
  }
  provided_fields := {key | input[key]}
  missing := required_fields - provided_fields
  count(missing) == 0
  
  # API version check
  input.apiVersion == "obs.v1"
  
  # Observer validation
  input.observer in contracts.v1.observers.valid_external_observers
  
  # Status validation
  input.status in {"ok", "warn", "fail"}
  
  # Project ID format
  regex.match("^[a-z]+:[a-z0-9-]+/[a-z0-9-]+$", input.project_id)
  
  # Timestamp format (ISO 8601)
  time.parse_rfc3339_ns(input.timestamp)
}

# Rule: Validate metrics structure
valid_metrics if {
  input.metrics != null
  type_name(input.metrics) == "object"
  
  # All metric values must be number, string, or boolean
  metric_types_valid := [valid |
    value := input.metrics[_]
    type := type_name(value)
    valid := type in {"number", "string", "boolean"}
  ]
  
  all(metric_types_valid)
}

# Rule: Calculate observation quality score
observation_quality_score := score if {
  scores := []
  
  # Base score for valid structure
  scores := array.concat(scores, [30 | valid_observation])
  
  # Score for valid metrics
  scores := array.concat(scores, [20 | valid_metrics])
  
  # Score for summary length
  scores := array.concat(scores, [10 | count(input.summary) <= 200])
  
  # Score for having duration_ms
  scores := array.concat(scores, [10 | input.duration_ms != null])
  
  # Score for recent timestamp (within 1 hour)
  current_time := time.now_ns()
  obs_time := time.parse_rfc3339_ns(input.timestamp)
  time_diff := (current_time - obs_time) / 1000000000  # Convert to seconds
  scores := array.concat(scores, [30 | time_diff <= 3600])
  
  score := sum(scores)
}

# ==============================================================================
# SLO BREACH DETECTION POLICIES
# ==============================================================================

package contracts.v1.slo

# SLO thresholds
slo_thresholds := {
  "latency_p95": {"value": 1000, "unit": "ms", "breach_type": "upper"},
  "error_rate": {"value": 0.01, "unit": "ratio", "breach_type": "upper"},
  "observation_age": {"value": 3600, "unit": "seconds", "breach_type": "upper"},
  "availability": {"value": 0.999, "unit": "ratio", "breach_type": "lower"}
}

# Rule: Check for SLO breaches
slo_breaches[breach] if {
  some metric_name, metric_value in input.metrics
  threshold := slo_thresholds[metric_name]
  
  # Check upper bound breaches
  threshold.breach_type == "upper"
  metric_value > threshold.value
  
  breach := {
    "apiVersion": "obs.v1",
    "timestamp": time.format(time.now_ns()),
    "project_id": input.project_id,
    "slo_name": metric_name,
    "breach_level": breach_level(metric_value, threshold.value),
    "actual_value": metric_value,
    "threshold_value": threshold.value,
    "message": sprintf("%s %v%s exceeds threshold %v%s", 
      [metric_name, metric_value, threshold.unit, threshold.value, threshold.unit])
  }
}

slo_breaches[breach] if {
  some metric_name, metric_value in input.metrics
  threshold := slo_thresholds[metric_name]
  
  # Check lower bound breaches
  threshold.breach_type == "lower"
  metric_value < threshold.value
  
  breach := {
    "apiVersion": "obs.v1",
    "timestamp": time.format(time.now_ns()),
    "project_id": input.project_id,
    "slo_name": metric_name,
    "breach_level": breach_level(threshold.value, metric_value),
    "actual_value": metric_value,
    "threshold_value": threshold.value,
    "message": sprintf("%s %v%s below threshold %v%s", 
      [metric_name, metric_value, threshold.unit, threshold.value, threshold.unit])
  }
}

# Helper: Determine breach severity
breach_level(actual, threshold) := "critical" if {
  threshold > 0
  actual / threshold > 2  # More than 2x threshold
}

breach_level(actual, threshold) := "warning" if {
  threshold > 0
  actual / threshold <= 2
}

# ==============================================================================
# PATH VALIDATION POLICIES
# ==============================================================================

package contracts.v1.paths

# Canonical paths definition
canonical_paths := {
  "primary": "~/.local/share/devops-mcp/",
  "registry": "~/.local/share/devops-mcp/project-registry.json",
  "observations": "~/.local/share/devops-mcp/observations/",
  "macos_fallback": "~/Library/Application Support/devops-mcp/observations/"
}

# Rule: Validate observation path
valid_observation_path if {
  path := input.path
  
  # Must be under canonical observation directory
  startswith(path, canonical_paths.observations)
  
  # Must follow project encoding pattern
  regex.match("observations/[a-z]+__[a-z0-9-]+__[a-z0-9-]+/", path)
  
  # Must end with valid filename
  regex.match("\\.(json|ndjson)$", path)
}

# Rule: Check if path requires migration
requires_path_migration if {
  path := input.path
  
  # Check for non-canonical paths
  non_canonical := [
    "/tmp/observations/",
    "~/observations/",
    "/.observations/"
  ]
  
  some prefix in non_canonical
  startswith(path, prefix)
}

# ==============================================================================
# SSE EVENT VALIDATION POLICIES
# ==============================================================================

package contracts.v1.sse

# Valid SSE event types
valid_event_types := {"ProjectObsCompleted", "SLOBreach"}

# Rule: Validate SSE event
default valid_sse_event = false

valid_sse_event if {
  input.event in valid_event_types
  input.data != null
  
  # Validate based on event type
  input.event == "ProjectObsCompleted"
  contracts.v1.observations.valid_observation with input as input.data
}

valid_sse_event if {
  input.event in valid_event_types
  input.data != null
  
  # Validate SLO breach event
  input.event == "SLOBreach"
  valid_slobreach with input as input.data
}

# Rule: Validate SLO breach structure
valid_slobreach if {
  required := {"apiVersion", "timestamp", "project_id", "slo_name", "breach_level"}
  provided := {key | input[key]}
  missing := required - provided
  count(missing) == 0
  
  input.apiVersion == "obs.v1"
  input.breach_level in {"warning", "critical"}
}

# ==============================================================================
# SCHEMA VERSION ENFORCEMENT POLICIES
# ==============================================================================

package contracts.v1.schemas

# Rule: Validate schema version
valid_schema_version if {
  input["$schema"] == required_schema_version
}

# Rule: Check for additionalProperties
strict_schema if {
  input.additionalProperties == false
}

# Rule: Validate schema ID format
valid_schema_id if {
  regex.match("^https://contracts\\.local/schemas/[a-z\\.]+\\.v1\\.json$", input["$id"])
}

# Rule: Complete schema validation
valid_contract_schema if {
  valid_schema_version
  strict_schema
  valid_schema_id
}

# ==============================================================================
# SERVICE COMPLIANCE POLICIES
# ==============================================================================

package contracts.v1.compliance

# Rule: Check service self-status compliance
compliant_self_status if {
  required := {
    "contractVersion", "schemaVersion", 
    "observerMapping", "paths", "timestamp"
  }
  
  provided := {key | input[key]}
  missing := required - provided
  count(missing) == 0
  
  input.contractVersion == contract_metadata.version
  input.schemaVersion == contract_metadata.schema
}

# Rule: Validate service observer mapping
valid_observer_mapping if {
  input.observerMapping.external == contracts.v1.observers.valid_external_observers
  
  # Check internal includes all required mappings
  required_internal := {"repo", "deps", "quality", "git", "mise", "sbom", "build", "manifest"}
  provided_internal := {x | x := input.observerMapping.internal[_]}
  
  missing := required_internal - provided_internal
  count(missing) == 0
}

# ==============================================================================
# MIGRATION POLICIES
# ==============================================================================

package contracts.v1.migration

# Rule: Check if data needs migration
needs_migration if {
  # Check for old schema version
  input["$schema"] == "http://json-schema.org/draft-07/schema#"
}

needs_migration if {
  # Check for internal observer names in external context
  input.context == "external"
  input.observer in {"repo", "deps", "quality"}
}

needs_migration if {
  # Check for missing apiVersion
  not input.apiVersion
}

# Rule: Generate migration report
migration_report := report if {
  issues := []
  
  # Check schema version
  issues := array.concat(issues, ["schema_version_outdated" | 
    input["$schema"] != required_schema_version])
  
  # Check observer naming
  issues := array.concat(issues, ["internal_observer_exposed" |
    input.context == "external"; input.observer in {"repo", "deps", "quality"}])
  
  # Check API version
  issues := array.concat(issues, ["missing_api_version" | 
    not input.apiVersion])
  
  # Check path compliance
  issues := array.concat(issues, ["non_canonical_path" | 
    contracts.v1.paths.requires_path_migration with input as {"path": input.path}])
  
  report := {
    "needs_migration": count(issues) > 0,
    "issues": issues,
    "severity": migration_severity(issues)
  }
}

# Helper: Determine migration severity
migration_severity(issues) := "critical" if {
  "schema_version_outdated" in issues
}

migration_severity(issues) := "high" if {
  "internal_observer_exposed" in issues
}

migration_severity(issues) := "medium" if {
  count(issues) > 0
}

# ==============================================================================
# ENFORCEMENT DECISIONS
# ==============================================================================

package contracts.v1.enforcement

import rego.v1

# Main enforcement decision
default allow = false
default violations = []

# Allow valid observations through
allow if {
  contracts.v1.observations.valid_observation
  not contracts.v1.observers.deny_external_quality
  not needs_blocking_migration
}

# Collect all violations
violations[v] if {
  not contracts.v1.observations.valid_observation
  v := {
    "type": "invalid_observation",
    "severity": "high",
    "message": "Observation failed validation"
  }
}

violations[v] if {
  contracts.v1.observers.deny_external_quality
  v := {
    "type": "quality_observer_exposed",
    "severity": "critical",
    "message": "Quality observer cannot be exposed externally"
  }
}

violations[v] if {
  needs_blocking_migration
  v := {
    "type": "migration_required",
    "severity": "high",
    "message": "Data requires migration before processing"
  }
}

# Check if migration is blocking
needs_blocking_migration if {
  report := contracts.v1.migration.migration_report
  report.severity in {"critical", "high"}
}

# Generate enforcement response
enforcement_response := {
  "allow": allow,
  "violations": violations,
  "contract_version": contract_metadata.version,
  "timestamp": time.format(time.now_ns()),
  "quality_score": contracts.v1.observations.observation_quality_score
}