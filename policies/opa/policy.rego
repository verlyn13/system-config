package system.integration

import rego.v1

default allow := false

# Input is a registry document (YAML->JSON) with services, contracts, paths, observer

required_services := {"bridge", "dashboard", "mcp", "ds"}

# Collect all violations
violations contains msg if {
  some s in required_services
  not input.services[s]
  msg := sprintf("missing service: %s", [s])
}

violations contains msg if {
  input.paths.primary_data == ""
  msg := "primary_data path must be set"
}

violations contains msg if {
  not input.observer
  msg := "observer block missing"
}

violations contains msg if {
  some o in input.observer.enum
  not o in ["git","mise","sbom","build","manifest"]
  msg := sprintf("invalid observer enum: %v", [o])
}

# Enforce alias rules if present
violations contains msg if {
  input.observer.internal_aliases.repo
  input.observer.internal_aliases.repo != "git"
  msg := "alias repo must map to git"
}

violations contains msg if {
  input.observer.internal_aliases.deps
  input.observer.internal_aliases.deps != "mise"
  msg := "alias deps must map to mise"
}

violations contains msg if {
  some k, v in input.observer.internal_aliases
  k in ["git","mise","sbom","build","manifest"]
  msg := sprintf("canonical name %s cannot be used as an alias key", [k])
}

violations contains msg if {
  not input.services.bridge.openapi
  msg := "bridge.openapi must be defined in registry"
}

allow if {
  count(violations) == 0
}
