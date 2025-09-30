package contracts.v1

import rego.v1

# Contract metadata
contract_metadata := {
  "version": "v1.1.0",
  "schema": "obs.v1",
  "api_version": "2025-09-28",
  "opa_version": "1.8.0",
  "policy_version": "1.0.0"
}

# Observer mappings
observer_mapping := {
  "repo": "git",
  "deps": "mise"
}

# Valid external observers
valid_external_observers := {"git", "mise", "sbom", "build", "manifest"}

# Map observer name
default map_observer := null

map_observer := result if {
  observer_mapping[input.observer]
  result := observer_mapping[input.observer]
}

map_observer := result if {
  not observer_mapping[input.observer]
  input.observer in valid_external_observers
  result := input.observer
}

# Check if observer is allowed
allow_external := true if input.observer in valid_external_observers

# Block quality observer
block_quality := true if input.observer == "quality"

# Simple validation example
valid_observation := true if {
  input.id
  input.timestamp
  input.observer
}

# Transform observation at boundary
transformed_observation := object.union(input, {"observer": map_observer}) if map_observer != input.observer else = input