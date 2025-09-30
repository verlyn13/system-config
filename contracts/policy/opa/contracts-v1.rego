# Contract-First Architecture Policy
# OPA 1.8.0 compatible (September 2025)
# Using Rego v1 syntax

package contracts.v1

import rego.v1

# Contract metadata
contract_metadata := {
  "version": "v1.1.0",
  "schema": "obs.v1",
  "api_version": "2025-09-28",
  "opa_version": "1.8.0",
  "policy_version": "1.0.0",
  "rego_version": "v1"
}

# Observer mappings (internal -> external)
observer_mapping := {
  "repo": "git",
  "deps": "mise",
  "quality": null  # Never exposed
}

# Valid external observers
valid_external_observers contains observer if {
  observer in {"git", "mise", "sbom", "build", "manifest"}
}

# Valid internal observers
valid_internal_observers contains observer if {
  observer in {"repo", "deps", "quality"}
}

valid_internal_observers contains observer if {
  observer in valid_external_observers
}

# Map observer name function
map_observer(name) := mapped if {
  name in observer_mapping
  mapped := observer_mapping[name]
} else := name if {
  name in valid_external_observers
} else := null

# Check if observer allowed externally
allow_external(observer) if {
  observer in valid_external_observers
}

# Block quality observer at boundaries
block_quality if {
  input.observer == "quality"
}

# Validate observation structure
valid_observation if {
  input.id
  input.timestamp
  input.observer
  input.subject
  input.operation
  input.outcome
}

# Calculate observation quality score
observation_quality := 100 - penalty if {
  penalty := 0 +
    count([1 | not input.context]) * 10 +
    count([1 | not input.outcome.metrics]) * 5 +
    count([1 | not input.outcome.artifacts]) * 5
} else := 100

# Validate observation
validate_observation := {
  "valid": is_valid,
  "quality_score": observation_quality,
  "violations": violations
} if {
  structure_ok := valid_observation
  observer_ok := input.observer in valid_internal_observers | valid_external_observers
  is_valid := structure_ok
  is_valid := observer_ok

  violations := array.concat(
    ["invalid_structure" | not structure_ok],
    ["invalid_observer" | not observer_ok]
  )
}

# SLO thresholds
slo_thresholds := {
  "response_time_p95": 500,
  "response_time_p99": 1000,
  "error_rate": 1.0,
  "availability": 99.9
}

# Check SLO breaches
check_slo_breaches(metrics) := breaches if {
  breaches := [
    {"metric": "response_time_p95", "value": metrics.response_time_p95, "threshold": slo_thresholds.response_time_p95} |
    metrics.response_time_p95 > slo_thresholds.response_time_p95
  ]
}

# Enforce at boundary
enforce_boundary := {
  "allowed": allowed,
  "observer": mapped_observer,
  "violations": violations
} if {
  # Check if quality observer (blocked)
  quality_blocked := input.observer == "quality"

  # Map observer name
  mapped_observer := map_observer(input.observer)

  # Determine if allowed
  allowed := not quality_blocked
  allowed := mapped_observer != null

  # Build violations
  violations := array.concat(
    ["quality_observer_blocked" | quality_blocked],
    ["invalid_observer_mapping" | not allowed; not quality_blocked]
  )
}

# Schema validation
valid_schema_version if {
  input["$schema"] == "https://json-schema.org/draft/2020-12/schema"
}

# Migration detection
needs_migration if {
  input["$schema"]
  contains(input["$schema"], "draft-07")
}

# Path validation
canonical_contract_path if {
  startswith(input.path, "/contracts/")
}

# Service compliance check
service_compliant if {
  valid_schema_version
  canonical_contract_path
  count(slo_thresholds) > 0
}

# Overall compliance status
compliance_status := {
  "version": contract_metadata.version,
  "opa_version": contract_metadata.opa_version,
  "rego_version": contract_metadata.rego_version,
  "compliant": service_compliant,
  "checks": {
    "schema_version": valid_schema_version,
    "path_compliance": canonical_contract_path,
    "slo_defined": count(slo_thresholds) > 0
  }
}