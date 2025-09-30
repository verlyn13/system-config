#!/bin/bash
set -euo pipefail

# Test observer outputs against schemas
echo "Testing Observer Outputs"
echo "========================"

PROJECT_PATH="$(pwd)"
PROJECT_ID="system-setup-update"

# Test each observer
echo -e "\n1. Testing repo-observer..."
if bash ./observers/repo-observer.sh "$PROJECT_PATH" "$PROJECT_ID" 2>/dev/null | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
    echo "✅ repo-observer: Valid JSON output"
else
    echo "❌ repo-observer: Invalid output"
    bash ./observers/repo-observer.sh "$PROJECT_PATH" "$PROJECT_ID" 2>&1 | head -5
fi

echo -e "\n2. Testing deps-observer..."
if bash ./observers/deps-observer.sh "$PROJECT_PATH" "$PROJECT_ID" 2>/dev/null | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
    echo "✅ deps-observer: Valid JSON output"
else
    echo "❌ deps-observer: Invalid output"
    bash ./observers/deps-observer.sh "$PROJECT_PATH" "$PROJECT_ID" 2>&1 | head -5
fi

echo -e "\n3. Testing build-observer..."
if bash ./observers/build-observer.sh "$PROJECT_PATH" "$PROJECT_ID" 2>/dev/null | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
    echo "✅ build-observer: Valid JSON output"
else
    echo "❌ build-observer: Invalid output"
    bash ./observers/build-observer.sh "$PROJECT_PATH" "$PROJECT_ID" 2>&1 | head -5
fi

echo -e "\n4. Testing quality-observer..."
if bash ./observers/quality-observer.sh "$PROJECT_PATH" "$PROJECT_ID" 2>/dev/null | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
    echo "✅ quality-observer: Valid JSON output"
else
    echo "❌ quality-observer: Invalid output"
    bash ./observers/quality-observer.sh "$PROJECT_PATH" "$PROJECT_ID" 2>&1 | head -5
fi

echo -e "\n5. Testing sbom-observer..."
if bash ./observers/sbom-observer.sh "$PROJECT_PATH" "$PROJECT_ID" 2>/dev/null | python3 -c "import sys, json; json.load(sys.stdin)" 2>/dev/null; then
    echo "✅ sbom-observer: Valid JSON output"
else
    echo "❌ sbom-observer: Invalid output"
    bash ./observers/sbom-observer.sh "$PROJECT_PATH" "$PROJECT_ID" 2>&1 | head -5
fi

echo -e "\n========================"
echo "Observer Validation Complete"