package dashboard.config

import rego.v1

# Dashboard configuration validation
# Ensures all systems use the correct dashboard port

# The ONLY allowed dashboard port
dashboard_port := 8089

# Validate dashboard configuration
validate_config(config) := errors if {
    port_errs := port_errors(config)
    url_errs := url_errors(config)
    endpoint_errs := endpoint_errors(config)
    errors := array.concat(array.concat(port_errs, url_errs), endpoint_errs)
}

# Check port configuration
port_errors(config) := errors if {
    errors := [error |
        config.spec.server.port != dashboard_port
        error := sprintf("Dashboard must use port %d, found %d", [dashboard_port, config.spec.server.port])
    ]
}

# Check URL configuration
url_errors(config) := errors if {
    expected_url := sprintf("http://localhost:%d", [dashboard_port])
    errors := [error |
        config.spec.server.url != expected_url
        error := sprintf("Dashboard URL must be %s, found %s", [expected_url, config.spec.server.url])
    ]
}

# Check endpoint configuration
endpoint_errors(config) := errors if {
    base_url := sprintf("http://localhost:%d", [dashboard_port])
    ui_errors := [error | config.spec.endpoints.ui != base_url; error := sprintf("UI endpoint must be %s", [base_url])]
    api_errors := [error | config.spec.endpoints.api != sprintf("%s/api", [base_url]); error := sprintf("API endpoint must be %s/api", [base_url])]
    health_errors := [error | config.spec.endpoints.health != sprintf("%s/health", [base_url]); error := sprintf("Health endpoint must be %s/health", [base_url])]
    errors := array.concat(array.concat(ui_errors, api_errors), health_errors)
}

# Deny if configuration is invalid
deny contains msg if {
    input.kind == "DashboardConfiguration"
    errors := validate_config(input)
    count(errors) > 0
    msg := sprintf("Dashboard configuration errors: %v", [errors])
}

# Allow valid configurations
allow if {
    input.kind == "DashboardConfiguration"
    errors := validate_config(input)
    count(errors) == 0
}

# Validate references to dashboard in other configs
validate_dashboard_reference(ref) := valid if {
    valid := ref.port == dashboard_port
}

# Deny incorrect dashboard references
deny contains msg if {
    some i
    input.spec.integrations[i].type == "dashboard"
    not validate_dashboard_reference(input.spec.integrations[i])
    msg := sprintf("Dashboard integration must use port %d", [dashboard_port])
}