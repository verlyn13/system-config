package contracts.v1

import rego.v1

# Contract metadata
contract_metadata := {
  "version": "v1.1.0",
  "schema": "obs.v1",
  "api_version": "2025-09-28",
  "opa_version": "1.8.0"
}

# Observer mappings
observer_mapping := {
  "repo": "git",
  "deps": "mise",
  "quality": null
}

# Valid external observers
valid_external_observers := {"git", "mise", "sbom", "build", "manifest"}

# Map observer name
map_observer(name) := observer_mapping[name] if {
  name in observer_mapping
} else := name if {
  name in valid_external_observers
} else := null

# Validate observation
validate_observation(obs) := {
  "valid": is_valid,
  "observer": mapped
} if {
  has_id := obs.id != null
  has_timestamp := obs.timestamp != null
  has_observer := obs.observer != null
  is_valid := has_id
  is_valid := has_timestamp if is_valid
  is_valid := has_observer if is_valid
  mapped := map_observer(obs.observer)
}

# Check if observer is allowed externally
allow_external(observer) := observer in valid_external_observers

# Enforce at boundary - main entry point
enforce_boundary(payload) := {
  "allowed": allowed,
  "data": transformed
} if {
  # Block quality observer
  not payload.observer == "quality"

  # Map observer name
  mapped := map_observer(payload.observer)
  allowed := mapped != null

  # Transform data
  transformed := object.union(payload, {"observer": mapped})
}