---
title: Agent Handoff — Current State
category: guide
component: agentic-handoff
status: active
version: 2.0.0
last_updated: 2026-02-23
tags: [agentic, handoff, ops, state]
priority: high
---

# Agent Handoff — Current State

**Last updated**: 2026-02-23 by Claude Code (claude-sonnet-4-6)
**Branch**: main (all changes uncommitted — working tree only)

---

## Work Completed This Session (2026-02-23)

### 1. SSOT Architecture Established
- Added `## Source of Truth` section to `AGENTS.md` with the SSOT table, workflow rule, iTerm2 policy, and project-scope guide.
- `system-config/06-templates/chezmoi/` is now the declared SSOT for shell integration, run_once installers, and global tool configs.
- Workflow: edit in system-config → `sync-chezmoi-templates.sh` → `chezmoi apply`.

### 2. `sync-chezmoi-templates.sh` Rewritten
- Dynamic file discovery via `find` (was a hardcoded list of ~15 files).
- `--check` flag: diffs only, no writes, exits 1 if divergence found. Suitable for pre-commit hooks.
- `--force` flag: overwrite even when dotfiles file is newer.
- Reverse-divergence warning: skips files where dotfiles is newer unless `--force`.
- Backup behavior (`*.bak.YYYYMMDD-HHMMSS`) preserved.
- shellcheck-clean.

### 3. Three Pending Chezmoi Templates Applied
| Template | Destination | Effect |
|---|---|---|
| `10-claude.fish.tmpl` (129L) | `~/.local/share/chezmoi/…/10-claude.fish.tmpl` | `CLAUDE_BIN` → `~/.local/bin/claude`, adds `MCP_TOOL_TIMEOUT`, `claude_check_updates`, PATH-fallback |
| `run_once_10-install-claude.sh.tmpl` | `~/.local/share/chezmoi/…` | Native curl installer, removes npm fallback |
| `run_once_21-clear-mcp-auth-cache.sh.tmpl` | `~/.local/share/chezmoi/…` (new) | Clears `~/.mcp-auth/` stale OAuth cache |

`chezmoi apply` was run — all three took effect on the live system. `~/.mcp-auth/` was deleted.

### 4. `system-update.sh` Improvements
| Change | Location | Why |
|---|---|---|
| Remove unused `C_CYAN` | color codes block | SC2034 |
| `# shellcheck disable=SC2059` on `consolef`/`transcriptf` | line ~243 | Intentional printf wrappers |
| `display_dir` sed → parameter expansion | `print_summary`, `print_json_summary` | SC2001 |
| `gh extension upgrade --all 2>/dev/null` → `2>&1` | `step_gh_extensions` | Errors were silently lost |
| `step_claude_code`: `if claude update; then … else …` | `step_claude_code` | Cleaner update-vs-current detection |
| Claude Code summarizer: "updated to X" vs "up to date (X)" | `summarize_step` | Accurate status after actual update |
| Remove dead `All tools are up to date` from warn pattern | `run_step` warn classifier | mise exits 0 for that case |
| `# shellcheck shell=bash` on all 7 plugins | `system-update.d/*.sh` | SC2148 |

### 5. `~/.config/system-update/config` Deployed
The chezmoi template `06-templates/chezmoi/dot_config/system-update/config.tmpl` was synced to dotfiles source and applied. `~/.config/system-update/config` now exists with documented defaults.

---

## Current System State

### Tool Locations
| Tool | Path | Version |
|------|------|---------|
| Claude Code CLI | `~/.local/bin/claude` → `~/.local/share/claude/versions/2.1.50` | 2.1.50 |
| Fish | `/opt/homebrew/bin/fish` | — |
| mise | `~/.local/bin/mise` | 2026.2.19 |
| node | via mise | 25.6.1 |
| npm | via mise | 11.9.0 |
| gh | `/opt/homebrew/bin/gh` | 2.87.3 |
| brew | `/opt/homebrew/bin/brew` | 5.0.15 |

### Key Live Files (all current as of this session)
| File | State |
|------|-------|
| `~/.config/fish/conf.d/10-claude.fish` | Updated — new CLAUDE_BIN, MCP_TOOL_TIMEOUT |
| `~/.config/system-update/config` | New — deployed today |
| `~/.mcp-auth/` | **Deleted** — MCP servers re-download mcp-remote on first connection |
| `~/system-config/scripts/system-update.sh` | Updated — 7 improvements |
| `~/system-config/scripts/sync-chezmoi-templates.sh` | Rewritten — dynamic, --check, --force |

### Chezmoi Status
`chezmoi status` shows many pending items — **do not run `chezmoi apply` blindly**. The pending items include:
- Several Fish conf.d files where dotfiles source diverges from live system (`DA` = diverged, agent modified)
- Multiple `run_once_*` installer scripts that would re-run on full apply (`R`):
  - `run_once_03-install-tools.sh` — installs core tools
  - `run_once_12-install-codex.sh` — installs Codex CLI
  - `run_once_17-install-orbstack.sh` — installs OrbStack
  - `run_once_18-install-tailscale.sh` — installs Tailscale
  - `run_once_19-install-infisical.sh` — installs Infisical
  - `run_once_20-install-fisher-plugins.fish` — installs Fisher plugins
- `dot_envrc`, `.zshrc` changes

To apply only a specific target safely:
```bash
chezmoi apply ~/.config/<specific-file>
```

To preview everything: `chezmoi diff`

### Sync Script Divergence Warnings
Running `sync-chezmoi-templates.sh --check` will show these **expected** divergences (dotfiles newer than system-config — pre-existing, out of scope):
- `dot_bashrc.tmpl`, `dot_config/direnv/*`, `dot_config/fish/conf.d/00-homebrew.fish.tmpl`, `dot_config/fish/conf.d/02-direnv.fish.tmpl`, `dot_config/fish/conf.d/10-claude.fish.tmpl` (just applied today, now newer), `dot_config/fish/conf.d/90-system-update.fish.tmpl`, `dot_config/fish/config.fish.tmpl`, `dot_config/mise/config.toml.tmpl`, `dot_config/starship.toml.tmpl`

These represent the inverse-SSOT problem: files that were edited directly in dotfiles without flowing through system-config. Resolving them (deciding which version is authoritative) is a separate task.

---

## Uncommitted Changes in This Repo

All changes from this session are **unstaged and uncommitted**. Run `git status` to see the full list. Key modified files:
- `AGENTS.md` — SSOT section added
- `.claude/README.md` — SSOT workflow reference added
- `scripts/sync-chezmoi-templates.sh` — rewritten
- `scripts/system-update.sh` — 7 improvements
- `scripts/system-update.d/*.sh` — shellcheck directives added

Untracked files that likely belong in a future commit:
- `06-templates/chezmoi/dot_config/fish/conf.d/90-system-update.fish.tmpl`
- `06-templates/chezmoi/dot_config/fish/conf.d/dicee-auto.fish.tmpl`
- `06-templates/chezmoi/dot_config/system-update/` — new directory
- `06-templates/chezmoi/run_once_21-clear-mcp-auth-cache.sh.tmpl`
- `ai-tools/` — MCP server config
- `AGENTS.md` (this file was just created/tracked)
- `docs/guides/AGENT-HANDOFF.md` (this file)

---

## Known Issues / Gotchas

1. **`~/.mcp-auth` is gone**: On first `claude` session after restart, MCP connections will re-download `mcp-remote` (~2s delay). Not a failure.

2. **Inverse-sync problem**: Several dotfiles source files are newer than their system-config counterparts. These represent templates that were edited directly in `~/.local/share/chezmoi/` rather than through the system-config SSOT workflow. Do not `--force` overwrite without reviewing diffs.

3. **Stale docs**: `README.md` still has many broken references (see below). `docs/CLAUDE-CONFIG-UPDATE-GUIDE.md` documents a template structure (`dot_claude/`) that was entirely deleted in commit `41d95ab`. Do not follow its instructions.

4. **Gopass guide**: `docs/guides/GOPASS-DEFINITIVE-GUIDE.md` does exist (confirmed). The AGENTS.md reference is correct.

5. **`.mise.toml` in repo root**: Pins Node/Python/etc. for work in this repo. Not the global mise config.

---

## Recommended Next Steps

1. **Commit all session changes** with `git add` + conventional commit
2. **Resolve inverse-sync divergences**: for each `[warning]` file in `sync-chezmoi-templates.sh --check`, decide which version is authoritative and flow it through the SSOT
3. **Review and apply remaining chezmoi changes**: the `run_once_*` scripts for orbstack, tailscale, etc. — confirm tools are already installed before triggering
4. **Archive `docs/CLAUDE-CONFIG-UPDATE-GUIDE.md`**: it describes a deleted template structure; replace or mark as deprecated
5. **Phase 10 (System Optimization)**: not started — profiling, startup time, etc.
