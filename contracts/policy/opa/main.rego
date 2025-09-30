# Contract-First Architecture Policy Framework
# Main OPA policy for contract enforcement
# Version: 1.1.0

package contracts.v1

import rego.v1

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
# OBSERVER MAPPINGS
# ==============================================================================

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

# Map internal observer to external
map_observer(observer) := mapped if {
  mapped := observer_mapping[observer]
} else := observer if {
  observer in valid_external_observers
} else := null

# Check if observer is valid for external API
allow_external_observer if {
  input.observer in valid_external_observers
}

# ==============================================================================
# OBSERVATION VALIDATION
# ==============================================================================

# Validate observation structure
valid_observation if {
  input.id
  input.timestamp
  input.observer
  input.subject
  input.operation
  input.outcome
}

# Check observation quality
observation_quality_score := score if {
  score := 100
  # Deduct points for missing optional fields
  score := score - (10 * count([1 | not input.context]))
  score := score - (5 * count([1 | not input.outcome.metrics]))
  score := score - (5 * count([1 | not input.outcome.artifacts]))
}

# Validate observation against contracts
validate_observation := result if {
  valid := valid_observation
  observer_valid := input.observer in valid_internal_observers
  is_valid := valid
  is_valid := observer_valid

  violations_list := array.concat(
    ["invalid_structure" | not valid],
    ["invalid_observer" | not observer_valid]
  )

  result := {
    "valid": is_valid,
    "quality_score": observation_quality_score,
    "violations": violations_list
  }
}

# ==============================================================================
# SLO CHECKS
# ==============================================================================

# Default SLO thresholds
default_slos := {
  "response_time_p95": 500,
  "response_time_p99": 1000,
  "error_rate": 1.0,
  "availability": 99.9
}

# Check for SLO breaches
check_slo_breach(metrics) := breaches if {
  breaches := [
    {"metric": "response_time_p95", "threshold": default_slos.response_time_p95, "value": metrics.response_time_p95} |
    metrics.response_time_p95 > default_slos.response_time_p95
  ]
}

# ==============================================================================
# SSE EVENT VALIDATION
# ==============================================================================

# Validate SSE event structure
valid_sse_event if {
  input.event
  input.data
  input.id
  input.retry
}

# Validate SSE event for streaming
validate_sse_event := result if {
  valid := valid_sse_event
  has_observation := input.data.observation

  obs_validation := validate_observation with input as input.data.observation if has_observation

  sse_violations := array.concat(
    ["invalid_sse_structure" | not valid],
    obs_validation.violations if has_observation else []
  )

  sse_is_valid := valid
  sse_is_valid := not has_observation
  else := obs_validation.valid if has_observation

  result := {
    "valid": sse_is_valid,
    "violations": sse_violations
  }
}

# ==============================================================================
# SCHEMA VERSION VALIDATION
# ==============================================================================

# Check if schema uses correct version
valid_schema_version if {
  input["$schema"] == required_schema_version
}

# Detect outdated schemas
needs_schema_migration if {
  input["$schema"]
  input["$schema"] != required_schema_version
  contains(input["$schema"], "draft-07")
}

# ==============================================================================
# PATH VALIDATION
# ==============================================================================

# Check if path is in canonical location
canonical_path if {
  startswith(input.path, "/contracts/")
}

# Validate contract file locations
valid_contract_path if {
  canonical_path
  endswith(input.path, ".json") or endswith(input.path, ".rego") or endswith(input.path, ".yaml")
}

# ==============================================================================
# ENFORCEMENT AT BOUNDARIES
# ==============================================================================

# Enforce contracts at service boundary
enforce_at_boundary := result if {
  # Map observer if needed
  mapped_observer := map_observer(input.observer)

  # Block quality observer at boundaries
  blocked := input.observer == "quality"

  # Validate if not blocked
  validation := validate_observation with input as input if not blocked

  # Determine transformed data
  transformed_data := object.union(input, {"observer": mapped_observer}) if mapped_observer != input.observer else input

  # Build violations list
  boundary_violations := array.concat(
    ["quality_observer_blocked" | blocked],
    validation.violations if not blocked else []
  )

  is_allowed := not blocked
  is_allowed := validation.valid if not blocked

  result := {
    "allowed": is_allowed,
    "transformed": transformed_data,
    "violations": boundary_violations
  }
}

# ==============================================================================
# COMPLIANCE CHECK
# ==============================================================================

# Check overall compliance
compliance_status := result if {
  schema_ok := valid_schema_version
  path_ok := canonical_path
  compliant := schema_ok
  compliant := path_ok
  mapping_ok := count([1 | o := valid_internal_observers[_]; not map_observer(o)]) == 0
  slos_ok := count(default_slos) > 0

  result := {
    "compliant": compliant,
    "version": contract_metadata.version,
    "checks": {
      "schema_version": schema_ok,
      "observer_mapping": mapping_ok,
      "path_compliance": path_ok,
      "slo_defined": slos_ok
    }
  }
}