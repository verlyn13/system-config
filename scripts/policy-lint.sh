#!/usr/bin/env bash
#
# Validate host-capability-substrate policy YAML owned by system-config.
#
# This is the system-config-side lint surface only: it checks canonical YAML
# structure and activation-grade local invariants. HCS-side snapshot/Zod
# cross-reference lint remains separate.

set -euo pipefail

if [[ $# -eq 0 ]]; then
    set -- "docs/host-capability-substrate/tiers.yaml.v0.2.0-skeleton.yaml"
fi

ruby - "$@" <<'RUBY'
require 'yaml'

EXPECTED_SCHEMA_VERSION = '0.2.0'
REQUIRED_ROOT_FIELDS = %w[
  schema_version
  policy_version
  kind
  status
  last_updated
].freeze

@failed = false

def lint_error(path, message)
  warn "#{path}: #{message}"
  @failed = true
end

def present?(value)
  !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
end

def mapping?(value)
  value.is_a?(Hash)
end

def each_forbidden_pattern(policy)
  patterns = policy['non_escalable_forbidden_patterns']
  return enum_for(:each_forbidden_pattern, policy) unless block_given?
  return if patterns.nil?

  if patterns.is_a?(Array)
    patterns.each { |entry| yield entry }
  elsif patterns.is_a?(Hash)
    Array(patterns['patterns']).each { |entry| yield entry }
  else
    yield patterns
  end
end

def validate_forbidden_tier(path, policy)
  tiers = policy['tiers']
  return unless mapping?(tiers)

  forbidden = tiers['forbidden']
  if mapping?(forbidden)
    if forbidden['approval_required'] == true
      lint_error(path, 'tier forbidden must not carry approval_required: true')
    end
    if forbidden.key?('approval_required_details')
      lint_error(path, 'tier forbidden must not carry approval_required_details')
    end
    if forbidden['approval_path_allowed'] == true
      lint_error(path, 'tier forbidden must not allow an approval path')
    end
  end

  operation_defaults = policy['operation_class_defaults']
  return unless mapping?(operation_defaults)

  operation_defaults.each do |operation_class, entry|
    next unless mapping?(entry)
    next unless entry['default_tier'] == 'forbidden'

    if entry['approval_required'] == true || entry.key?('approval_required_details')
      lint_error(
        path,
        "operation_class #{operation_class} maps to forbidden but carries approval requirements",
      )
    end
  end
end

def validate_forbidden_patterns(path, policy)
  each_forbidden_pattern(policy) do |entry|
    unless mapping?(entry)
      lint_error(path, 'non_escalable_forbidden_patterns entries must be mappings')
      next
    end

    %w[approval_path approval_required approval_required_details].each do |field|
      if entry.key?(field)
        lint_error(
          path,
          "non_escalable_forbidden_patterns entry #{entry['pattern'].inspect} must not carry #{field}",
        )
      end
    end
  end
end

def validate_active_requirements(path, policy)
  return unless policy['status'] == 'active'

  notice = policy['non_authority_notice']
  unless mapping?(notice) && notice['live_policy'] == true
    lint_error(path, 'active policy must set non_authority_notice.live_policy: true')
  end

  provenance = policy['provenance']
  unless mapping?(provenance) && present?(provenance['approved_by']) && present?(provenance['approved_at'])
    lint_error(path, 'active policy must set provenance.approved_by and provenance.approved_at')
  end

  snapshot_binding = policy['snapshot_binding']
  unless mapping?(snapshot_binding) && present?(snapshot_binding['source_policy_sha256'])
    lint_error(path, 'active policy must set snapshot_binding.source_policy_sha256')
  end
end

ARGV.each do |path|
  begin
    policy = YAML.load_file(path)
  rescue Psych::Exception => e
    lint_error(path, "YAML parse failed: #{e.message}")
    next
  end

  unless mapping?(policy)
    lint_error(path, 'policy document must be a YAML mapping')
    next
  end

  REQUIRED_ROOT_FIELDS.each do |field|
    lint_error(path, "missing required root field #{field}") unless present?(policy[field])
  end

  if policy['schema_version'] != EXPECTED_SCHEMA_VERSION
    lint_error(
      path,
      "schema_version must be #{EXPECTED_SCHEMA_VERSION.inspect}; got #{policy['schema_version'].inspect}",
    )
  end

  validate_active_requirements(path, policy)
  validate_forbidden_tier(path, policy)
  validate_forbidden_patterns(path, policy)
end

exit(@failed ? 1 : 0)
RUBY
