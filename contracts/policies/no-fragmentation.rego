package system.fragmentation

import rego.v1

# Policy to prevent service fragmentation
# Ensures no duplicate services or conflicting configurations

# Define known service types and their canonical locations
canonical_services := {
    "dashboard": {
        "location": "system-dashboard",
        "ports": [5173, 3001],
        "type": "web-ui"
    },
    "opa": {
        "location": "contracts/policies",
        "ports": [8181],
        "type": "policy-engine"
    },
    "mcp-monitor": {
        "location": "mcp-servers/system-monitor",
        "ports": [],
        "type": "mcp-server"
    }
}

# Check for duplicate services
duplicate_services contains msg if {
    some service_type
    services := [s |
        s := input.services[_]
        s.type == service_type
    ]
    count(services) > 1
    msg := sprintf("Multiple %s services found: %v", [service_type, services])
}

# Check for port conflicts
port_conflicts contains msg if {
    some port
    services := [s.name |
        s := input.services[_]
        port in s.ports
    ]
    count(services) > 1
    msg := sprintf("Port %d claimed by multiple services: %v", [port, services])
}

# Validate service locations
invalid_locations contains msg if {
    some service
    input.services[service].type in canonical_services
    canonical := canonical_services[input.services[service].type]
    input.services[service].location != canonical.location
    msg := sprintf("Service %s should be in %s, found in %s", [
        service,
        canonical.location,
        input.services[service].location
    ])
}

# Check for orphaned dashboards
orphaned_dashboards contains msg if {
    dashboard_dirs := input.dashboard_directories
    count(dashboard_dirs) > 1
    msg := sprintf("Multiple dashboard directories found: %v. Only one dashboard should exist.", dashboard_dirs)
}

# Deny if fragmentation detected
deny contains msg if {
    msg := duplicate_services[_]
}

deny contains msg if {
    msg := port_conflicts[_]
}

deny contains msg if {
    msg := invalid_locations[_]
}

deny contains msg if {
    msg := orphaned_dashboards[_]
}

# Allow if no fragmentation
allow if {
    count(deny) == 0
}

# Report fragmentation status
fragmentation_report := {
    "duplicate_services": duplicate_services,
    "port_conflicts": port_conflicts,
    "invalid_locations": invalid_locations,
    "orphaned_dashboards": orphaned_dashboards,
    "status": status
} if {
    status := "fragmented" if count(deny) > 0 else "clean"
}