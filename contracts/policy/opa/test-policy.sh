#!/bin/bash

echo "Testing OPA Contract Policies"
echo "=============================="

# Test 1: Check metadata
echo -e "\n1. Testing contract metadata:"
opa eval -d working.rego "data.contracts.v1.contract_metadata" --format pretty

# Test 2: Test observer mapping - repo -> git
echo -e "\n2. Testing observer mapping (repo -> git):"
echo '{"observer": "repo"}' | opa eval -d working.rego "data.contracts.v1.map_observer" -I --format raw

# Test 3: Test observer mapping - deps -> mise
echo -e "\n3. Testing observer mapping (deps -> mise):"
echo '{"observer": "deps"}' | opa eval -d working.rego "data.contracts.v1.map_observer" -I --format raw

# Test 4: Test quality observer blocking
echo -e "\n4. Testing quality observer blocking:"
echo '{"observer": "quality"}' | opa eval -d working.rego "data.contracts.v1.block_quality" -I --format raw

# Test 5: Test valid external observer
echo -e "\n5. Testing valid external observer (git):"
echo '{"observer": "git"}' | opa eval -d working.rego "data.contracts.v1.allow_external" -I --format raw

# Test 6: Test observation validation
echo -e "\n6. Testing observation validation:"
echo '{"id": "123", "timestamp": "2025-09-28T10:00:00Z", "observer": "git"}' | \
  opa eval -d working.rego "data.contracts.v1.valid_observation" -I --format raw

echo -e "\n✅ Policy tests completed"