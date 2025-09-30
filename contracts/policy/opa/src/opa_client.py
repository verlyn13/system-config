"""
OPA Client for Python
Contract validation and enforcement client
"""

import requests
from typing import Dict, Any, Optional, List
from dataclasses import dataclass


@dataclass
class ValidationResult:
    """Result of a validation operation"""
    valid: bool
    violations: List[str] = None
    data: Dict[str, Any] = None


class OPAClient:
    """OPA Policy Client for contract enforcement"""

    def __init__(self, opa_url: str = "http://localhost:8181"):
        self.opa_url = opa_url
        self.policy_path = "/v1/data/contracts/v1"

    def validate_observation(self, observation: Dict[str, Any]) -> ValidationResult:
        """
        Validate an observation against contracts

        Args:
            observation: The observation to validate

        Returns:
            ValidationResult with validity and any violations
        """
        response = requests.post(
            f"{self.opa_url}{self.policy_path}/observations/validate",
            json={"input": observation}
        )
        result = response.json().get("result", {})

        return ValidationResult(
            valid=result.get("valid", False),
            violations=result.get("violations", []),
            data=result
        )

    def map_observer(self, observer_name: str) -> Optional[str]:
        """
        Map internal observer names to external names

        Args:
            observer_name: Internal observer name

        Returns:
            External observer name or None if not mapped
        """
        response = requests.post(
            f"{self.opa_url}{self.policy_path}/observers/map_to_external",
            json={"input": {"observer": observer_name}}
        )
        return response.json().get("result")

    def check_slo_compliance(self, metrics: Dict[str, Any]) -> ValidationResult:
        """
        Check SLO compliance for given metrics

        Args:
            metrics: Metrics to check against SLOs

        Returns:
            ValidationResult with breach information
        """
        response = requests.post(
            f"{self.opa_url}{self.policy_path}/slo/check_breaches",
            json={"input": metrics}
        )
        result = response.json().get("result", {})

        return ValidationResult(
            valid=not result.get("has_breaches", False),
            violations=result.get("breaches", []),
            data=result
        )

    def validate_sse_event(self, event: Dict[str, Any]) -> ValidationResult:
        """
        Validate SSE event before streaming

        Args:
            event: SSE event to validate

        Returns:
            ValidationResult with validation details
        """
        response = requests.post(
            f"{self.opa_url}{self.policy_path}/streaming/validate_sse_event",
            json={"input": event}
        )
        result = response.json().get("result", {})

        return ValidationResult(
            valid=result.get("valid", False),
            violations=result.get("violations", []),
            data=result
        )

    def check_migration_required(self, current_version: str, target_version: str) -> bool:
        """
        Check if migration is needed between versions

        Args:
            current_version: Current contract version
            target_version: Target contract version

        Returns:
            True if migration is required
        """
        response = requests.post(
            f"{self.opa_url}{self.policy_path}/migration/check_required",
            json={
                "input": {
                    "current_version": current_version,
                    "target_version": target_version
                }
            }
        )
        result = response.json().get("result", {})
        return result.get("migration_required", False)

    def validate_schema(self, schema: Dict[str, Any]) -> ValidationResult:
        """
        Validate schema compliance

        Args:
            schema: JSON Schema to validate

        Returns:
            ValidationResult with compliance information
        """
        response = requests.post(
            f"{self.opa_url}{self.policy_path}/schemas/validate_version",
            json={"input": schema}
        )
        result = response.json().get("result", {})

        return ValidationResult(
            valid=result.get("valid", False),
            violations=result.get("violations", []),
            data=result
        )

    def enforce_at_boundary(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Enforce contracts at service boundary

        Args:
            data: Data crossing service boundary

        Returns:
            Transformed data with contracts enforced
        """
        # Map observer names if present
        if "observer" in data:
            mapped = self.map_observer(data["observer"])
            if mapped:
                data["observer"] = mapped

        # Validate observation if present
        if "observation" in data:
            validation = self.validate_observation(data["observation"])
            if not validation.valid:
                raise ValueError(f"Contract violation: {validation.violations}")

        return data


# Flask/FastAPI integration example
def create_contract_middleware(opa_client: OPAClient):
    """
    Create middleware for Flask/FastAPI contract enforcement

    Args:
        opa_client: Configured OPA client instance

    Returns:
        Middleware function
    """
    def contract_middleware(request_data: Dict[str, Any]) -> Dict[str, Any]:
        try:
            return opa_client.enforce_at_boundary(request_data)
        except ValueError as e:
            raise ValueError(f"Contract validation failed: {e}")

    return contract_middleware