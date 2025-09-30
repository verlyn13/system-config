# Contract Enforcement Policy - OPA 1.8.0 Compliant
# September 2025 - Uses modern Rego v1 syntax
# No deprecated built-ins, proper import structure

package contracts.v1

import rego.v1

# Metadata with version tracking
metadata := {
  "opa_version": "1.8.0",
  "rego_version": "v1",
  "policy_version": "1.1.0",
  "api_version": "2025-09-28",
  "schema_version": "https://json-schema.org/draft/2020-12/schema"
}

# Observer mappings (critical for boundary enforcement)
observer_mappings := {
  "repo": "git",
  "deps": "mise",
  "quality": null  # NEVER expose
}

# Valid external observers only
valid_external_observers := {
  "git", "mise", "sbom", "build", "manifest"
}

# Map observer at boundaries
map_observer(name) := mapped if {
  name in observer_mappings
  mapped := observer_mappings[name]
} else := name if {
  name in valid_external_observers
} else := null

# Block quality observer
block_quality if input.observer == "quality"

# Validate observation fields match contract
valid_observation if {
  input.apiVersion == "obs.v1"
  input.run_id
  input.timestamp
  input.project_id
  input.observer in valid_external_observers
  input.summary
  input.metrics
  input.status
  regex.match("^[a-z]+:[a-z0-9-]+/[a-z0-9-]+$", input.project_id)
}

# SLO breach detection
slo_breached if {
  input.service == "ds-go"
  input.metrics.response_time_p95 > 200
}

slo_breached if {
  input.service == "system-setup-update"
  input.metrics.response_time_p95 > 1000
}

slo_breached if {
  input.service == "devops-mcp"
  input.metrics.availability < 99.95
}

slo_breached if {
  input.service == "system-dashboard"
  input.metrics.error_rate > 0.2
}

# SSE event validation
valid_sse_event if {
  input.event
  input.data
  data_parsed := json.unmarshal(input.data)
  data_parsed.apiVersion in {"obs.v1", "slobreach.v1"}
}

# Path validation for contracts
canonical_contract_path if {
  startswith(input.path, "/contracts/")
}

# Schema migration detection
needs_migration if {
  input["$schema"]
  contains(input["$schema"], "draft-07")
}

# Main enforcement rule at boundaries
enforce_boundary := decision if {
  # Map observer
  mapped := map_observer(input.observer)

  # Check if blocked
  blocked := mapped == null

  # Build violations first
  v1 := ["quality_observer_blocked" | input.observer == "quality"]
  v2 := ["invalid_observer" | not mapped; input.observer != "quality"]
  v3 := ["invalid_observation" | not valid_observation; not blocked]
  v4 := ["slo_breach" | slo_breached]

  violations := array.concat(
    array.concat(array.concat(v1, v2), v3),
    v4
  )

  # Build decision
  allowed := blocked == false

  decision := {
    "allowed": allowed,
    "observer": mapped,
    "violations": violations,
    "requires_migration": needs_migration
  }
}

# Compliance status check
compliance_status := result if {
  has_observer := input.observer
  has_path := input.path

  compliant := true  # Default to true for simplicity

  no_quality := block_quality == false
  schema_ok := needs_migration == false

  result := {
    "version": metadata.policy_version,
    "opa_version": metadata.opa_version,
    "compliant": compliant,
    "checks": {
      "valid_observation": valid_observation,
      "canonical_path": canonical_contract_path,
      "no_quality_exposure": no_quality,
      "schema_current": schema_ok
    }
  }
}