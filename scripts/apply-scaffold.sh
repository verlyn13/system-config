#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <target-repo-path> <template>" >&2
  echo "Templates: bridge | ds-cli | dashboard | mcp" >&2
  exit 1
fi

TARGET=$1
TEMPLATE=$2
ROOT_DIR="$(cd "$(dirname "$0")"/.. && pwd)"

case "$TEMPLATE" in
  bridge|ds-cli|dashboard|mcp) ;;
  *) echo "Unknown template: $TEMPLATE" >&2; exit 1;;
esac

echo "Applying shared .github scaffolding to $TARGET" >&2
mkdir -p "$TARGET/.github/ISSUE_TEMPLATE" "$TARGET/.github/workflows"
cp -R "$ROOT_DIR/scaffolds/orchestration/shared/.github/ISSUE_TEMPLATE/." "$TARGET/.github/ISSUE_TEMPLATE/"
cp "$ROOT_DIR/scaffolds/orchestration/shared/.github/PULL_REQUEST_TEMPLATE.md" "$TARGET/.github/PULL_REQUEST_TEMPLATE.md"
cp "$ROOT_DIR/scaffolds/orchestration/shared/.github/labeler.yml" "$TARGET/.github/labeler.yml"
cp "$ROOT_DIR/scaffolds/orchestration/shared/.github/workflows/labeler.yml" "$TARGET/.github/workflows/labeler.yml"

echo "Applying $TEMPLATE runbook to $TARGET" >&2
mkdir -p "$TARGET/docs"
cp "$ROOT_DIR/scaffolds/orchestration/$TEMPLATE/docs/integration-checklist.md" "$TARGET/docs/integration-checklist.md"

echo "Done. Review changes and commit in $TARGET." >&2

