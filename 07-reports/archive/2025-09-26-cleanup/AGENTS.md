---
title: Agents
category: reference
component: agents
status: draft
version: 1.0.0
last_updated: 2025-09-26
tags: []
priority: medium
---

# Repository Guidelines

## Project Structure & Module Organization
All content lives as standalone Markdown references in the repo root. Flagship guides such as `mac-dev-env-setup.md`, `multi-account-setup.md`, and `renovate-config.md` capture installation flows, account practices, and automation policy. Create new material as `kebab-case.md` in the root unless a document clearly belongs beside an existing file; cross-link related guides so navigation stays linear. Include shell blocks and prerequisite callouts inline so the docs can be followed sequentially without context switching.

## Build, Test, and Development Commands
Use `markdownlint "**/*.md"` to enforce structural consistency before sending changes. Preview edits locally with `glow <file>` or your Markdown viewer of choice to confirm headings, tables, and code blocks render properly. When documenting shell steps, run them in a disposable environment and capture the exact command sequence; prefer `bash` compatible syntax and note required tools.

## Coding Style & Naming Conventions
Follow a conversational, second-person voice that mirrors existing guides. Headings use Title Case for top-level sections and sentence case for subsections; keep the hierarchy shallow (≤3 levels). Wrap narrative lines near 100 characters, but do not break code blocks. Fenced snippets should specify the language (e.g., ```bash). Highlight configuration files and paths with backticks, and favor ordered lists for chronological procedures.

## Testing Guidelines
Every command snippet must be executed or dry-run validated before publication; annotate commands that require elevated privileges or irreversible effects. When instructions depend on external services, note the minimum account role and required environment variables. If you add scripts or automation references, include a brief verification step that readers can run (e.g., `mise doctor`).

## Commit & Pull Request Guidelines
Match the existing Conventional Commit pattern (`type(scope): summary`), as seen in `chore(shell): checkpoint before loop remediation [auto]`. Keep commit scopes aligned with the dominant area touched (e.g., `docs`, `setup`). Pull requests should state the goal, outline testing/validation performed, and call out any follow-up work. Attach relevant screenshots or terminal transcripts when documenting UI-heavy flows or multi-step wizards.

## Security & Configuration Tips
Redact API keys, tenant IDs, and machine-specific secrets before pushing. When sharing configuration snippets, replace personal identifiers with placeholders like `<your-org>` and confirm the defaults are safe for unattended execution. Note any tools that phone home or require network access so downstream users can assess compliance obligations.
