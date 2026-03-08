# Implementation Plan: SystemConfig → system-config

Migration from current repo layout to the structure defined in `system-plan-draft.md`
(DEVMACHINE-SPEC) and `MIGRATION-PLAN.md` (Filesystem Migration Spec).

```yaml
status: IN PROGRESS
current_phase: "Phase 1 complete — Phase 2 next"
specs:
  - system-plan-draft.md        # DEVMACHINE-SPEC — shell, chezmoi, iTerm2, homebrew, mise
  - MIGRATION-PLAN.md           # ~/Organizations/the-nash-group/.archive/planning/
governance: the-covenant principles apply
verify_file_count: "git ls-files | wc -l"   # do not hardcode — run at execution time
verify_change_count: "git status --porcelain | wc -l"  # must be 0 before Phase 0
phases: "Pre-0 through 5, plus deferred migration"
```

---

## Document Hierarchy

```
DEVMACHINE-SPEC (system-plan-draft.md)     ← SOURCE OF TRUTH
  ↓ derives
MIGRATION-PLAN.md                          ← DERIVED (open question resolutions, filesystem)
  ↓ derives
IMPLEMENTATION-PLAN.md (this document)     ← DERIVED (execution sequence)
```

When this plan contradicts a spec, the spec wins. When the spec needs to change, it
changes first, then this plan is regenerated. (Principle 16: These Principles Are Living
Law — humans evolve the system, machines execute it.)

---

## Gap Resolutions

Ten gaps were identified by federation review. Each is resolved below with binding
decisions. These resolutions are integrated into the relevant plan sections.

### G-01: Migration Section 5 Deferred but Untracked

**Resolution**: Path A — defer with explicit tracking.

MIGRATION-PLAN Section 5 (task IDs M-1 through M-7: repo inventory, classification,
per-repo migration procedure) is **deferred**. It is not blocking: shell stabilization,
doctor harness, and iTerm2 profiles don't require repos to be in their final locations.

Tracking: A "Deferred Work" section is added to this plan (bottom) with each M-task listed,
its blocking condition, and the document that governs it. MIGRATION-PLAN Section 5 status
should be updated to `status: deferred` in that document.

Principle: P8 (Fail Fast) — deferring is an honest governance decision. Silently dropping is not.

### G-02: Phase Dependency Model Contradictory

**Resolution**: Decompose to task-level DAG. Phases 5 and 6 from v2 are merged into a
single Phase 5 with internal task ordering.

The corrected DAG:

```
Pre-0 → Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5
                                                               ├── P5-1..P5-3 (macOS integration, no deps beyond P4)
                                                               ├── P5-4..P5-6 (governance wiring, no deps beyond P4)
                                                               └── P5-7 (full ng-doctor, depends on all above)
```

No phase says "depends on X but can run in parallel with X." Dependencies are structural.

### G-03: Missing Doctor Checks

**Resolution**: Add `gopass_installed` to tools category, `dynamic_profiles_dir_exists` to
iterm2 category. Both are defined in DEVMACHINE-SPEC Section 7 and were omitted from the plan.

Principle: P11 (If It's Not Measured, It Doesn't Exist).

### G-04: Missing Principle Citations on OQ-03, OQ-04, OQ-06, OQ-08

**Resolution**: Citations added to the OQ section below. Each resolution now traces to a
specific Covenant principle.

### G-05: tmux Decision Drift

**Resolution**: DROP the tmux shell integration module from both fish and zsh. tmux remains
in the Brewfile (it's a tool). `dot_tmux.conf.tmpl` (tmux's own config) moves to `home/`.
The 274-line fish tmux convenience module (`06-tmux.fish.tmpl`) is deleted — it's
over-engineered convenience functions, not shell integration.

This is a single decision recorded here. Both specs should be updated to match if they
say otherwise.

Principle: Principle 15 (Three Circles) — tmux is an application, not a shell integration
concern. Its config file is L1 (user-level). Shell functions wrapping it are L0 (optional
convenience) and don't belong in managed config.

### G-06: Missing FILESYSTEM-MIGRATION-SPEC.md Artifact

**Resolution**: Marked as `# DEFERRED` in the target layout. Created when migration work
(G-01) begins. Not blocking any current phase.

### G-07: Incomplete Post-Migration Verification

**Resolution**: Verification for repo migration tasks (spot-checks, old-path scans) is
deferred alongside the migration tasks themselves (G-01). The post-migration verification
sequence in this plan covers only what this plan executes. When M-1..M-7 become in-scope,
their verification (MIGRATION-PLAN Section 7) becomes in-scope with them.

### G-08: Stale Counts

**Resolution**: All hardcoded counts replaced with verification commands. The plan uses
`verify:` directives that the agent runs at execution time, not constants to trust.

### G-09: Incomplete Disposition Table

**Resolution**: Complete disposition table added (Appendix A). Every tracked file and every
untracked file in the repo is explicitly dispositioned: KEEP, MOVE, DELETE, or DEFER, with
a one-line rationale and spec/OQ citation.

### G-10: Actions Without Spec Traceability

**Resolution**: Every destructive action (delete, move, rename) in the plan now cites one of:
a spec clause, an OQ resolution, or a Covenant principle. Uncitable actions are flagged as
EVALUATE with a resolution gate.

---

## Resolved Open Questions

All 8 open questions are resolved with principle-grounded rationale. These decisions are
**binding** for all phases.

### OQ-01: Fish conf.d Tool-Specific Files

**Decision**: Triage into three categories.

| Category | Tools | Rationale |
|----------|-------|-----------|
| **Keep as numbered module** | orbstack (40), tailscale (41) | User-level foundation — always installed. |
| **Move to direnv** | sentry, supabase, vercel, infisical | Project-specific — activate at project boundary. |
| **Drop** | windsurf, codex, GAM, tmux | Agent tools use Agentic profile. tmux is an app, not a shell concern. GAM: inactive. |

Additional fish-only modules retained:
- `25-keybindings.fish` — fish-specific interactive keybindings (no zsh equivalent needed)
- `30-iterm2.fish` — iTerm2 shell integration (fish-only, human-only)
- `50-system-update.fish` — `system-update` command alias

**Principle**: P15 (Three Circles). L1 tools get shell modules. Project-level tools activate
via direnv at project boundary. Agent tools get no fish config — they use the Agentic zsh profile.

**Fish conf.d final count**: 14 files (8 core + keybindings + iterm2 + orbstack + tailscale + system-update + 99-local).
**zshrc.d/ final count**: 14 files (11 core + orbstack + tailscale + 99-local).

### OQ-02: iTerm2 Theme Dedup

**Decision**: Keep 3, drop the rest.

| Keep | Drop | Reason |
|------|------|--------|
| tokyonight-moon | tokyonight-profile, tokyonightmoon-profile, tokyonightsoftdark | Redundant variants |
| tokyonight-storm | tokyonightstorm-profile | Duplicate |
| wild-cherry | Default.json, iterm2-profile.json, iTerm2State.itermexport | Default ships with iTerm2; export is a snapshot, not IaC |

**Principle**: P5 (Fortress Defined by Blueprints). Point-in-time exports are not reproducible config.

### OQ-03: ai-tools/ Directory

**Decision**: Split by concern, then delete the directory.

- `mcp-servers.json` → `home/dot_config/claude/mcp-servers.json.tmpl` (chezmoi-managed)
- `sync-to-tools.sh` → `scripts/sync-mcp.sh`
- `ai-tools/README.md` → content merged into `docs/tools.md`

**Principle**: P5 (Fortress Defined by Blueprints) + SSoT. MCP config is user-level config
that belongs in XDG (`~/.config/claude/`). Chezmoi makes it templatable for machine-specific
paths. A standalone `ai-tools/` directory for a single concern duplicates what XDG + scripts/
already provide.

### OQ-04: Project Scaffolding Templates

**Decision**: Move to `~/Organizations/the-nash-group/.org/templates/projects/`.

**Principle**: P15 (Three Circles). Project scaffolding generates new repos — that's
organizational tooling (.org/), not machine config (system-config). The machine config repo
manages what's ON the machine. The org repo manages what PROJECTS look like. `.org/templates/`
already exists.

**Method**: Cross-repo: `cp` + `git rm` from system-config.

### OQ-05: Uncommitted Changes

**Decision**: Commit current state first, tag pre-migration checkpoint, then begin.

Steps:
1. Review all changed files: `git status; git diff --stat`
2. Stage and commit in logical groups
3. `git tag pre-migration-$(date +%Y%m%d)`
4. Verify: `git status --porcelain | wc -l` must be 0

**Principle**: P8 (Fail Fast, Recover Faster). Starting structural migration with uncommitted
files is operating in a degraded state. The tag enables rollback.

**Constraint**: No migration phase starts with uncommitted changes.

### OQ-06: Repo Rename Timing

**Decision**: Before Phase 0. First structural action taken.

**Principle**: P8 (Fail Fast) + P13 (Code Without Docs Is Incomplete). The machine config
repo IS the governance tooling — it must be the exemplar. Running ng-doctor checks against
a non-compliant repo name while enforcing naming standards elsewhere is a contradiction that
will cause the naming validator to either fail on its own repo (noisy) or exempt its own repo
(dishonest). Neither is acceptable.

GitHub rename is non-destructive (automatic redirects).

### OQ-07: run_once Script Consolidation

**Decision**: Four run_once_before scripts survive. Everything Homebrew handles goes in the Brewfile.

| Script | Purpose |
|--------|---------|
| `00-filesystem-scaffold.sh.tmpl` | Creates ~/Organizations, ~/Development, XDG dirs |
| `01-homebrew.sh.tmpl` | Installs Homebrew itself |
| `02-brew-packages.sh.tmpl` | `brew bundle` from declarative Brewfile |
| `03-mise-global.sh.tmpl` | Global mise setup |

All `run_once_10` through `run_once_21` individual installer scripts: DELETE.

**Principle**: P5 (Fortress Defined by Blueprints). The Brewfile is declarative ("what").
Individual installer scripts are imperative ("how"). `brew bundle` is the idempotent
applicator. run_once scripts exist ONLY for bootstrapping steps that can't be expressed
as templates or formulas.

### OQ-08: Chezmoi Source Path

**Decision**: Point chezmoi directly at `home/` in the repo. Delete the sync script.

Implementation: symlink `~/.local/share/chezmoi` → `system-config/home/` (or `chezmoi init --source`).

**Principle**: SSoT (There Can Be Only One) + P5 (Fortress Defined by Blueprints). A sync
script between repo and chezmoi source means two copies of every template — two sources of
truth. chezmoi was designed for the source directory to BE a git repo (or subdirectory of
one). Working with the tool, not against it.

After this change: edit template → `chezmoi apply` → `git commit`. No sync step.

`sync-chezmoi-templates.sh`: DELETE (per this resolution).

---

## Current vs. Target: Summary of Deltas

| Dimension | Current State | Target State | Verify |
|-----------|--------------|--------------|--------|
| **Repo name** | `SystemConfig` at `~/SystemConfig` | `system-config` at `~/Organizations/jefahnierocks/system-config` | `basename $(git rev-parse --show-toplevel)` |
| **Top-level dirs** | 6 numbered + docs/ + scripts/ + ai-tools/ | home/ + iterm2/ + scripts/ + policies/ + docs/ | `ls -d */` |
| **Login shell** | `/bin/zsh` (already correct) | `/bin/zsh` | `dscl . -read /Users/$USER UserShell` |
| **Fish role** | Primary interactive, 20+ conf.d files | iTerm2 profile only, 14 conf.d files | `ls home/dot_config/fish/conf.d/ \| wc -l` |
| **Shell architecture** | Monolithic zshrc, no zshrc.d/ | Modular zshrc.d/ (14 modules), NG_MODE gating | `ls home/dot_config/zshrc.d/ \| wc -l` |
| **Agentic mode** | Not implemented | NG_MODE env var gates interactive features | `NG_MODE=agentic zsh -lic 'which grep'` |
| **chezmoi source** | `~/.local/share/chezmoi` (copy via sync) | `home/` in repo (direct, no sync) | `chezmoi source-path` |
| **Shared shell data** | Duplicated across templates | `.chezmoidata.yaml` (single source) | `test -f home/.chezmoidata.yaml` |
| **iTerm2 profiles** | 7+ JSON files at repo root | `iterm2/profiles/` (3) + `iterm2/themes/` (3) | `ls iterm2/{profiles,themes}/ \| wc -l` |
| **Version pinning** | .nvmrc + .node-version + .mise.toml | .mise.toml only | `test ! -f .nvmrc && test ! -f .node-version` |
| **Verification** | doctor-path.sh (PATH only) | ng-doctor (8 categories, 37 checks) | `ng-doctor \| grep -c '✓\|✗\|⊘'` |
| **Doc structure** | Numbered dirs + 28-file docs/ | Flat `docs/` (7 consolidated files) | `ls docs/*.md \| wc -l` |

---

## Phase Pre-0: Clean Baseline — COMPLETE

**Status**: Complete. Commits 5881ed6 through 95fe4a5. Rollback tag: `pre-migration-20260306`.

**Goal**: Commit all pending changes, tag rollback point, rename repo, move to target location.

**Rationale**: P8 (Fail Fast) — no structural migration with dirty working tree. OQ-05 + OQ-06.

### Tasks

| ID | Action | Spec Citation | Details |
|----|--------|---------------|---------|
| PRE-1 | Review uncommitted changes | OQ-05 | `git status; git diff --stat`. Understand scope. |
| PRE-2 | Commit in logical groups | OQ-05 | Group 1: `chore: consolidate update scripts into system-update.sh`. Group 2: `chore: remove dot_claude chezmoi templates`. Group 3: `chore: pending doc and config updates`. |
| PRE-3 | Tag pre-migration state | OQ-05 | `git tag pre-migration-$(date +%Y%m%d)` |
| PRE-4 | Verify clean working tree | OQ-05 | `git status --porcelain \| wc -l` → must be 0 |
| PRE-5 | Rename repo on GitHub | OQ-06, P8 | Settings → General → Repository name → `system-config` |
| PRE-6 | Update local remote URL | OQ-06 | `git remote set-url origin git@github.com:<org>/system-config.git` |
| PRE-7 | Move local directory | OQ-06 | `mv ~/SystemConfig ~/Organizations/jefahnierocks/system-config` |
| PRE-8 | Update cross-references | OQ-06 | `grep -r 'SystemConfig'` in repo → replace. CLAUDE.md, AGENTS.md, CI workflows. |
| PRE-9 | Update chezmoi if needed | OQ-06 | `chezmoi source-path` — update if it references old path. |
| PRE-10 | Commit rename | OQ-06 | `chore: rename repository to system-config` |

### Verify
```bash
git status --porcelain | wc -l           # 0
basename $(git rev-parse --show-toplevel) # system-config
git remote get-url origin                 # contains system-config
```

---

## Phase 0: Doctor Harness — COMPLETE

**Status**: Complete. P0-3 (chezmoi rewire) completed at end of Phase 1. Commit c855a4e.

**Goal**: Build `ng-doctor` so every subsequent phase is testable.

**Spec**: DEVMACHINE-SPEC Section 7 + MIGRATION-PLAN Section 7.

### Tasks

| ID | Action | Spec Citation | Status | Details |
|----|--------|---------------|--------|---------|
| P0-1 | Create `home/` directory | Section 2 target layout | DONE | New chezmoi source root. |
| P0-2 | Create `home/dot_local/bin/ng-doctor.tmpl` | Section 7 | DONE | Pass/fail/skip framework. 8 categories, 37 checks (see matrix below). All checks can return skip if prereqs aren't met yet. |
| P0-2a | Install ng-doctor manually | — | DONE | `chezmoi execute-template` + patch SYSTEM_CONFIG_DIR. Needed because chezmoi not yet rewired. |
| P0-3 | Wire chezmoi to `home/` | OQ-08, SSoT | DONE | Completed at end of Phase 1. `sourceDir` in chezmoi.toml points directly at `system-config/home/`. Dotfiles repo snapshotted (commit dd25ea1) and preserved at `~/.local/share/chezmoi/`. |
| P0-4 | Verify harness | Section 7, P0-2 | DONE | 23 pass, 8 fail (expected), 8 skip. Shellcheck clean. |

### Dotfiles Repo State

The separate dotfiles repo (`~/.local/share/chezmoi/`, github: verlyn13/dotfiles) was
snapshotted (commit dd25ea1) before the chezmoi rewire. It remains at its original
location. Chezmoi `sourceDir` now points at `system-config/home/` instead. The dotfiles
repo retains SSH, GPG, git configs, Brewfiles, iTerm2 DynamicProfiles — content NOT
managed by system-config.

### ng-doctor Check Matrix (37 checks, 8 categories)

```
CATEGORY      CHECK                            SPEC SECTION   PHASE DELIVERED
─────────     ─────                            ────────────   ──────────────
shell         login_shell_is_zsh               AD-01          Pre-0 (already done)
shell         homebrew_bash_installed           AD-03          4
shell         fish_installed                    AD-02          4
shell         zshenv_is_minimal                 3.1            1
shell         zshrc_loads_modules               3.3            1
shell         zshrc_d_modules_present           3.4            1
shell         bash_config_minimal               3.6            1

path          homebrew_on_path                  3.2            1
path          local_bin_on_path                 3.2            1
path          mise_shims_on_path                3.2            1
path          no_duplicate_path_entries         3.4 (01-path)  1

tools         mise_installed                    5              4
tools         mise_activated                    5              4
tools         direnv_installed                  5              4
tools         direnv_hooked                     5              4
tools         chezmoi_installed                 5              4
tools         starship_installed                5              4
tools         gopass_installed                  5              4

iterm2        dynamic_profiles_dir_exists       4              2
iterm2        dev_profile_installed             4              2
iterm2        agentic_profile_installed         4              2
iterm2        human_fish_profile_installed      4              2

agentic       agentic_mode_loads_minimal        3.4 (30-ag)    1
agentic       agentic_prompt_is_static          3.4 (30-ag)    1
agentic       agentic_startup_under_200ms       3.4 (30-ag)    2

filesystem    xdg_dirs_exist                    AD-06          4
filesystem    organizations_dir_exists          Migration §4   4
filesystem    development_dir_exists            Migration §4   4
filesystem    system_config_in_correct_location Migration §7   Pre-0
filesystem    chezmoi_source_is_repo            OQ-08          0
filesystem    no_repos_in_desktop_documents     Migration §7   DEFERRED
filesystem    spotlight_exclusions_set          Phase 5        5

hygiene       no_orphan_lockfiles               Section 2      3
hygiene       no_nvmrc_in_systemconfig          AD-04          3
hygiene       no_node_version_in_systemconfig   AD-04          3
hygiene       chezmoi_source_clean              Section 2      3
hygiene       git_ignorecase_false              Phase 5        5

governance    org_claude_md_present             Migration §6   5
governance    subsidiary_yaml_present           Migration §6   5
```

### Verify
```bash
which ng-doctor                          # ~/.local/bin/ng-doctor
ng-doctor 2>&1 | head -5                 # runs without error
chezmoi source-path                      # .../system-config/home
```

---

## Phase 1: Shell Stabilization — COMPLETE

**Status**: Complete. Commit c855a4e. ng-doctor: 29 pass, 7 fail (Phase 2/3), 3 skip.

**Goal**: Modular zshrc.d/ with NG_MODE gating. Slimmed fish conf.d. Shared `.chezmoidata.yaml`.

**Spec**: DEVMACHINE-SPEC Sections 3.1–3.6, 6. OQ-01.

**Depends on**: Phase 0 (complete). P0-3 (chezmoi rewire) completed at end of this phase.

### Tasks

| ID | Action | Spec Citation | Status | Details |
|----|--------|---------------|--------|---------|
| P1-1 | Verify login shell | AD-01 | DONE | Already `/bin/zsh`. Confirmed via ng-doctor. |
| P1-2 | Create `home/.chezmoidata.yaml` | Section 6 | DONE | XDG paths, PATH prepends, aliases, coreutil_aliases, homebrew prefix. Both zsh and fish render from this. |
| P1-3 | Create `home/dot_zshenv.tmpl` | Section 3.1 | DONE | XDG exports only. 11 lines (6 non-comment). No PATH, no brew, no stdout. |
| P1-4 | Create `home/dot_zprofile.tmpl` | Section 3.2 | DONE | Homebrew shellenv, ~/.local/bin, mise shims. |
| P1-5 | Create `home/dot_zshrc.tmpl` | Section 3.3 | DONE | Thin loader (16 lines) + compdef stub for agentic mode. |
| P1-6 | Create zshrc.d/ modules (13 files) | Section 3.4, OQ-01 | DONE | `00-xdg`, `01-path`, `02-mise`, `03-direnv`, `10-aliases`, `15-coreutil-aliases` (GATED), `20-interactive` (GATED), `21-completion` (GATED), `22-prompt` (GATED), `30-agentic` (AGENTIC-ONLY), `40-orbstack`, `41-tailscale`, `99-local`. |
| P1-7 | Create fish conf.d/ modules (13 files) | Section 3.5, OQ-01 | DONE | `00-xdg`, `01-path`, `02-mise`, `03-direnv`, `10-aliases`, `15-coreutil-aliases`, `20-prompt`, `25-keybindings`, `30-iterm2`, `40-orbstack`, `41-tailscale`, `50-system-update`, `99-local`. Plus `config.fish.tmpl`. Note: grep→rg alias omitted in fish (breaks iTerm2 shell integration). |
| P1-8 | Create minimal bash config | Section 3.6 | DONE | `dot_bash_profile.tmpl` + `dot_bashrc.tmpl`. XDG, Homebrew, mise, direnv. |
| P1-9 | Move remaining chezmoi templates | Section 2 map | DONE | `git mv` .chezmoiignore, dot_envrc.tmpl, starship, direnv, mise, system-update. DELETE dot_tmux.conf.tmpl. |
| P1-10 | Delete old fish conf.d files | OQ-01, P15 | DONE | 10 dropped + 11 superseded = 21 files deleted. Orphaned live files cleaned from ~/.config/fish/conf.d/. |
| P1-11 | Delete old monolithic dot_zshrc.tmpl | Section 3.3 | DONE | + dot_bashrc.tmpl. Decomposition complete. |
| P1-12 | Run ng-doctor | — | DONE | shell 7/7, path 4/4, agentic 2/3 (startup 557ms > 200ms target). |

### ng-doctor Post-Phase 1 (2026-03-07)

```
29 passed, 7 failed, 3 skipped — exit code 1

Remaining failures (Phase 2/3):
  iterm2:     agentic_profile_installed, human_fish_profile_installed (Phase 2)
  agentic:    agentic_startup_under_200ms (557ms — may improve with iTerm2 profile, Phase 2)
  hygiene:    no_orphan_lockfiles (package-lock.json), no_nvmrc, no_node_version (Phase 3)
              chezmoi_source_clean (Phase 1 work committed, but system-config has untracked changes)
```

### Fixes Applied During Phase 1

- **compdef stub**: mise/direnv emit `compdef` calls but compinit skipped in agentic mode. Added noop stub in dot_zshrc.tmpl before module loading.
- **grep→rg in fish**: iTerm2 shell integration uses `grep -cvE` internally. Aliasing `grep` to `rg` in fish broke it. Omitted grep alias from fish coreutil-aliases (cat/find still aliased).
- **.chezmoiignore `*.local`**: Pattern matched `~/.local/` directory, blocking ng-doctor deployment. Changed to specific file patterns.
- **ng-doctor zshrc.d path**: Was checking `~/.config/zsh/zshrc.d`, corrected to `~/.config/zshrc.d`.
- **ng-doctor executable**: Renamed to `executable_ng-doctor.tmpl` for chezmoi to deploy with +x.
- **chezmoi rewire**: Used `sourceDir` in chezmoi.toml (top-level, not under `[git]`) instead of symlink, so `{{ .chezmoi.workingTree }}` resolves to repo root.

### Key Complexity
- **Decomposing dot_zshrc.tmpl**: The 8.7KB monolithic file must be analyzed, classified into
  zshrc.d/ modules, and any logic that doesn't fit must be addressed. This is the hardest task.
- **Template rendering**: Both zsh and fish must render shared values from `.chezmoidata.yaml`
  using Go template syntax with per-shell output.

### Verify
```bash
zsh -lic 'echo ok'                       # exit 0
NG_MODE=agentic zsh -lic 'echo ok'       # exit 0
fish -lic 'echo ok'                      # exit 0
bash -lic 'echo ok'                      # exit 0
NG_MODE=agentic zsh -lic 'which grep'    # /usr/bin/grep (not rg)
NG_MODE=agentic zsh -lic 'echo $PROMPT'  # %~ %#
ng-doctor | grep -E 'shell|path|agentic' # all ✓
```

---

## Phase 2: iTerm2 Profiles — NEXT

**Status**: Not started. This is the next phase to execute.

**Goal**: Three-profile system via Dynamic Profiles.

**Spec**: DEVMACHINE-SPEC Section 4. OQ-02.

**Depends on**: Phase 1 (complete).

### Tasks

| ID | Action | Spec Citation | Details |
|----|--------|---------------|---------|
| P2-1 | Create `iterm2/profiles/` (3 files) | Section 4 | `dev-zsh.json`, `agentic-zsh.json`, `human-fish.json`. |
| P2-2 | Create `iterm2/themes/` (3 files) | OQ-02 | Move+rename: tokyonight-moon, tokyonight-storm, wild-cherry. |
| P2-3 | Create `scripts/install-iterm2-profiles.sh` | Section 4 | Symlinks into DynamicProfiles/. Idempotent. |
| P2-4 | Create `iterm2/README.md` | Section 2 layout | Setup instructions. |
| P2-5 | Delete root-level iTerm2 files | OQ-02, P5 | `git rm`: Default.json, iterm2-profile.json, tokyonight-profile.json, tokyonightmoon-profile.json, tokyonightsoftdark.json, tokyonightstorm-profile.json, wild-cherry-profile.json, iTerm2State.itermexport. |
| P2-6 | Verify agentic profile | Section 4 | Startup < 200ms. POSIX coreutils in PATH. Static prompt. |
| P2-7 | Run ng-doctor | — | iterm2, agentic categories: all green. |

### Verify
```bash
ls iterm2/profiles/*.json | wc -l       # 3
ls iterm2/themes/*.json | wc -l         # 3
ls -1 *.json 2>/dev/null                 # empty (no root-level JSONs)
test ! -f iTerm2State.itermexport        # deleted
ng-doctor | grep -E 'iterm2|agentic'    # all ✓
```

---

## Phase 3: Repo Structure Cleanup

**Goal**: Flatten numbered dirs. Consolidate docs. Delete dead files. Split ai-tools/.

**Spec**: DEVMACHINE-SPEC Section 2 migration map. OQ-03.

**Depends on**: Phase 2.

### Tasks

| ID | Action | Spec Citation | Details |
|----|--------|---------------|---------|
| **Dead file deletion** | | | |
| P3-1 | Delete orphaned files | AD-04, Section 2 | `git rm`: package-lock.json, .nvmrc, .node-version. |
| P3-2 | Delete empty stub dirs | Section 2 deletes | `02-configuration/editors/`, `02-configuration/shells/`, `03-automation/hooks/`, `03-automation/workflows/`. Anti-pattern §10: "Maintain empty placeholder directories." |
| P3-3 | Clean .gemini temp | Anti-pattern §10 | `git rm .gemini/tmp/audit_script.sh`. Verify `.gemini/tmp/` in .gitignore. Anti-pattern: "Commit temp files to AI tool config directories." |
| P3-4 | Delete REPO-STRUCTURE.md | Section 2 deletes | Replaced by AGENTS.md + README.md. |
| P3-5 | Delete INDEX.md | Section 2 deletes | One index (README), not two. |
| P3-6 | Delete .meta/ | P3 (No Code Unchallenged) | Orphaned automation metadata (sync-info.json, labels.yaml). No active consumer. |
| **ai-tools/ split** | | | |
| P3-7 | Move MCP config to chezmoi | OQ-03, P5 | `ai-tools/mcp-servers.json` → `home/dot_config/claude/mcp-servers.json.tmpl`. |
| P3-8 | Move sync script | OQ-03, P5 | `ai-tools/sync-to-tools.sh` → `scripts/sync-mcp.sh`. |
| P3-9 | Delete ai-tools/ | OQ-03 | After moves complete. |
| **Structural moves** | | | |
| P3-10 | Move policies | Section 2 map | `04-policies/opa/` → `policies/opa/`. `version-policy.md` → `policies/`. Delete `validate-policy.py` + `policy-as-code.yaml` (redundant with .org/ tooling). |
| P3-11 | Move useful automation scripts | Section 2 map | Review `03-automation/scripts/`: keep useful → `scripts/`, delete rest. Delete `03-automation/launchd/` (inactive). |
| P3-12 | Move project scaffolding | OQ-04, P15 | `06-templates/projects/` → `~/Organizations/the-nash-group/.org/templates/projects/` (cp + git rm). |
| P3-13 | Move codex config | OQ-03 | `06-templates/dotfiles/codex/config.toml` → `home/dot_config/codex/config.toml.tmpl` or DELETE if codex config is now managed differently. |
| **Docs consolidation** | | | |
| P3-14 | Create `docs/setup.md` | Section 2 layout | Merge: 01-setup/* (6 files). Single walkthrough. |
| P3-15 | Create `docs/shells.md` | Section 2 layout | Shell architecture from DEVMACHINE-SPEC §3 + relevant existing docs. |
| P3-16 | Create `docs/terminals.md` | Section 2 layout | Merge: 02-configuration/terminals/* (3 files) + iTerm2 docs. |
| P3-17 | Create `docs/tools.md` | Section 2 layout | Merge: 02-configuration/tools/* (4 files) + 05-reference/mcp-examples.md + ai-tools/README.md + CLI setup docs. |
| P3-18 | Create `docs/secrets.md` | Section 2 layout | Merge: GOPASS-DEFINITIVE-GUIDE, SECRETS-MANAGEMENT-GUIDE, SECRETS-MANAGEMENT-ENHANCED. |
| P3-19 | Create `docs/maintenance.md` | Section 2 layout | Merge: MAINTENANCE-GUIDE + automation docs + system-update docs. |
| P3-20 | Create `docs/agent-handoff.md` | Section 2 layout | Merge: AGENT-HANDOFF.md + relevant content. |
| P3-21 | Delete emptied source dirs | Section 2 deletes | `01-setup/`, `02-configuration/`, `03-automation/`, `04-policies/`, `05-reference/`, `06-templates/`. Plus all now-redundant docs/* originals. |
| **Scripts cleanup** | | | |
| P3-22 | Delete sync-chezmoi-templates.sh | OQ-08, SSoT | No longer needed — chezmoi points directly at home/. |
| P3-23 | Delete superseded scripts | OQ-07 | daily-update.sh, update-all.sh, update-*.sh (11 files) — consolidated into system-update.sh. deploy-shell-config.sh — replaced by chezmoi apply. |
| P3-24 | Evaluate remaining scripts | P3 (No Code Unchallenged) | doctor-path.sh, doctor-env.sh, system-health.sh → likely superseded by ng-doctor (DELETE). verify-shell-safety.fish, repair-shell-env.sh → likely superseded by shell stabilization (DELETE). system-audit-collect.sh, verify-orbstack-config.sh → one-time tools (DELETE). terraform-auth-setup.sh → KEEP if actively used. iterm2-setup.sh → evaluate overlap with install-iterm2-profiles.sh. |
| **Meta updates** | | | |
| P3-25 | Rename system-plan-draft.md → DEVMACHINE-SPEC.md | Section 2 layout | Per target layout. |
| P3-26 | Delete .envrc + .env.example | P6 (Env vars risk) | Repo has no direnv needs post-restructure. .env.example is orphaned (no package.json). |
| P3-27 | Update .mise.toml | OQ-07, AD-04 | Pin only shellcheck + shfmt (repo-local). Remove node, bun. |
| P3-28 | Update .gitignore | Section 3, Migration §3 | Add: `.gemini/tmp/`, `.nvmrc`, `.node-version`. Remove obsolete patterns. |
| P3-29 | Update AGENTS.md | — | Rewrite directory layout, path references, commands, SSOT table. |
| P3-30 | Update CLAUDE.md | — | Verify imports AGENTS.md correctly. |
| P3-31 | Update README.md | — | New structure, shell architecture, getting-started. |
| P3-32 | Run ng-doctor | — | hygiene category: all green. |

### Verify
```bash
ls -d [0-9]*/ 2>/dev/null               # empty (no numbered dirs)
ls ai-tools/ 2>/dev/null                 # empty (directory gone)
test ! -f package-lock.json              # deleted
test ! -f .nvmrc                         # deleted
test ! -f .node-version                  # deleted
ls docs/*.md | wc -l                     # 7
ng-doctor | grep hygiene                 # all ✓
```

---

## Phase 4: Homebrew, mise, and Chezmoi Bootstrap

**Goal**: Declarative Brewfile. mise as sole version authority. Git config. Bootstrap scripts.

**Spec**: DEVMACHINE-SPEC Section 5. OQ-07.

**Depends on**: Phase 3.

### Tasks

| ID | Action | Spec Citation | Details |
|----|--------|---------------|---------|
| P4-1 | Create `home/run_once_before/00-filesystem-scaffold.sh.tmpl` | Migration §4, P5 | Creates ~/Organizations, ~/Development, XDG dirs. Time Machine exclusions. Idempotent. |
| P4-2 | Create `home/run_once_before/01-homebrew.sh.tmpl` | Section 5, OQ-07 | Installs Homebrew if absent. Only script that runs before brew is available. |
| P4-3 | Create `home/run_once_before/02-brew-packages.sh.tmpl` | Section 5, OQ-07, P5 | Declarative Brewfile from Section 5 manifest. `brew bundle --no-lock`. |
| P4-4 | Create `home/run_once_before/03-mise-global.sh.tmpl` | Section 5, OQ-07 | Global mise: node=lts, python=latest. |
| P4-5 | Create `home/dot_config/mise/config.toml.tmpl` | Section 5 | Global mise config. `experimental = true`. |
| P4-6 | Create `home/dot_config/git/config.tmpl` | Section 6, .chezmoidata | Global gitconfig from chezmoidata: user, signing, default branch, ignorecase=false. |
| P4-7 | Create `home/dot_config/git/ignore.tmpl` | Section 2 layout | Global gitignore. |
| P4-8 | Delete old run_once scripts | OQ-07, P5 | All `run_once_03`, `run_once_10`–`run_once_21`. Replaced by Brewfile. |
| P4-9 | Delete old dot_claude templates | Section 2 deletes | Already staged for deletion. Confirm removal from home/. |
| P4-10 | Run ng-doctor | — | tools, filesystem categories: all green. |

### Verify
```bash
test -f home/run_once_before/00-filesystem-scaffold.sh.tmpl
test -f home/run_once_before/02-brew-packages.sh.tmpl
ls home/run_once_before/*.tmpl | wc -l   # 4
ls home/run_once_*.tmpl 2>/dev/null | wc -l  # 0 (old ones deleted)
ng-doctor | grep -E 'tools|filesystem'   # all ✓
```

---

## Phase 5: macOS Integration + Governance Wiring

**Goal**: Spotlight/TM exclusions, CLAUDE.md hierarchy, .subsidiary.yaml, full doctor pass.

**Spec**: DEVMACHINE-SPEC Phase 5, MIGRATION-PLAN Sections 6–7.

**Depends on**: Phase 4.

All tasks in this phase are independent of each other (no internal ordering required)
except P5-7 which depends on all others completing first.

### Tasks

| ID | Action | Spec Citation | Depends On | Details |
|----|--------|---------------|------------|---------|
| P5-1 | Document Spotlight exclusions | DEVMACHINE Phase 5 | P4 | ~/Organizations, ~/Development, ~/.local/share/mise. Document manual GUI steps in docs/maintenance.md. |
| P5-2 | Script Time Machine exclusions | DEVMACHINE Phase 5 | P4 | `tmutil addexclusion` in scaffold script or separate run_once. |
| P5-3 | Verify git ignorecase | DEVMACHINE Phase 5 | P4 | Handled by git config template (P4-6). ng-doctor verifies. |
| P5-4 | Create/update `~/Organizations/CLAUDE.md` | Migration §6.1 | P4 | Org router: subsidiaries, governance levels, the-covenant link. |
| P5-5 | Create subsidiary CLAUDE.md files | Migration §6.1 | P4 | happy-patterns, jefahnierocks, litecky-editing, seven-springs. the-nash-group already has one. |
| P5-6 | Create `.subsidiary.yaml` files | Migration §6.2 | P4 | Per subsidiary: governance_level, github_org, repo_prefix, standards. |
| P5-7 | Run full ng-doctor | All sections | P5-1..P5-6 | All 8 categories green. Final validation. |

### Verify
```bash
ng-doctor                                # ALL categories green (exit 0)
chezmoi source-path                      # .../system-config/home
chezmoi verify                           # no drift
zsh -lic 'mise current'                  # matches fish -lic 'mise current'
test -f ~/Organizations/CLAUDE.md        # governance wiring
```

---

## Deferred Work

The following work from MIGRATION-PLAN Section 5 is explicitly **deferred**. It is not
blocking system-config restructuring. The filesystem scaffold (Phase 4) creates the
target directories. Repo moves are a follow-on effort.

**Tracking**: Governed by MIGRATION-PLAN Section 5. Becomes in-scope when system-config
is stable (all ng-doctor checks green) and a natural break in active development occurs.

| Task ID | Action | Blocking Condition | Governing Doc |
|---------|--------|--------------------|---------------|
| M-1 | Verify clean working tree (per repo) | Per-repo, at migration time | Migration §5.3 |
| M-2 | Move directory | Per-repo, after M-1 | Migration §5.3 |
| M-3 | Verify git works post-move | Per-repo, after M-2 | Migration §5.3 |
| M-4 | Update absolute path references | Per-repo, after M-2 | Migration §5.3 |
| M-5 | Update worktrees | Per-repo, if worktrees exist | Migration §5.4 |
| M-6 | Update IDE project references | Per-repo, after M-2 | Migration §5.3 |
| M-7 | Verify build/test | Per-repo, after M-4 | Migration §5.3 |

**Also deferred**:
- `FILESYSTEM-MIGRATION-SPEC.md` artifact: created when migration begins (G-06)
- `no_repos_in_desktop_documents` ng-doctor check: validates post-migration (G-07)
- `no_stale_worktree_refs` ng-doctor check: validates post-migration (G-07)
- Legacy cruft cleanup in ~/Organizations/ (NashGroup/, HappyPatterns/, business-org/, etc.)
- Per-repo verification from MIGRATION-PLAN Section 7 (spot-checks, old-path scans)

---

## Execution DAG

```
Pre-0  commit + tag + rename + move
  │
  ▼
Phase 0  ng-doctor harness + home/ + chezmoi wiring
  │
  ▼
Phase 1  .chezmoidata.yaml + zshrc.d/ (14) + fish conf.d/ (14) + bash
  │
  ▼
Phase 2  iterm2/profiles/ (3) + iterm2/themes/ (3) + install script
  │
  ▼
Phase 3  flatten dirs + consolidate docs (7) + delete dead files + split ai-tools/
  │
  ▼
Phase 4  run_once_before/ (4) + Brewfile + mise config + git config
  │
  ▼
Phase 5  macOS integration (P5-1..3) + governance (P5-4..6) → full ng-doctor (P5-7)
  │
  ▼
DEFERRED  repo migration (M-1..M-7) — tracked, not scheduled
```

Strictly sequential. No "depends but also parallel." Each phase gate: ng-doctor
for the relevant categories passes before proceeding.

---

## Risk Register

| ID | Risk | Severity | Mitigation | Rollback |
|----|------|----------|------------|----------|
| R-1 | Worktree corruption during repo move (Pre-0) | High | `git worktree list` before moving. Remove, move, re-create. | `git worktree repair` (Git 2.36+) |
| R-2 | chezmoi source-path breaks after move | High | Update symlink immediately after move. | `chezmoi init --source {path}` |
| R-3 | zshrc decomposition introduces regressions | Medium | Diff old zshrc output vs new modular. Test interactive + agentic + script modes. | `git checkout pre-migration -- 06-templates/chezmoi/dot_zshrc.tmpl` |
| R-4 | Docs consolidation loses valuable content | Medium | Git history preserves all. Review consolidated docs before deleting sources. | `git show pre-migration:{path}` |
| R-5 | Hardcoded paths in other repos reference ~/SystemConfig | Medium | `grep -r 'SystemConfig' ~/Organizations/` after move. GitHub redirects handle remote URLs. | Find-replace |
| R-6 | IDE references break after move | Low | Open from new location; IDEs auto-update. | Re-open |
| R-7 | Spotlight re-indexes moved dirs | Low | Re-apply exclusions. `mdutil -i off {path}`. | — |
| R-8 | Active dev disrupted during migration | Medium | Migrate at natural break points. Never move with uncommitted changes. | Pre-migration tag |

---

## Appendix A: Complete File Disposition Table

Every tracked file and significant untracked file is dispositioned. Verb is one of:
**KEEP** (stays as-is), **MOVE** (relocated), **DELETE** (removed), **REPLACE** (new content at same or new path),
**DEFER** (handled in follow-on work).

### Root Files

| File | Verb | Target / Rationale | Citation |
|------|------|-------------------|----------|
| `AGENTS.md` | REPLACE | Rewrite for new structure | P3-29 |
| `CHANGELOG.md` | KEEP | — | Section 2 layout |
| `CLAUDE.md` | REPLACE | Update imports | P3-30 |
| `IMPLEMENTATION-PLAN.md` | KEEP | This document | — |
| `INDEX.md` | DELETE | Replaced by README | Section 2 deletes |
| `README.md` | REPLACE | Rewrite for new structure | P3-31 |
| `REPO-STRUCTURE.md` | DELETE | Replaced by AGENTS.md + README | Section 2 deletes |
| `system-plan-draft.md` | MOVE | → `DEVMACHINE-SPEC.md` | Section 2 layout, P3-25 |
| `.envrc` | DELETE | Repo has no direnv needs post-restructure | P3-26, P6 |
| `.env.example` | DELETE | Orphaned (no package.json) | P3-26 |
| `.gitignore` | REPLACE | Update patterns | P3-28 |
| `.mise.toml` | REPLACE | shellcheck + shfmt only | P3-27, OQ-07 |
| `.node-version` | DELETE | mise is sole authority | AD-04, OQ-07 |
| `.nvmrc` | DELETE | mise is sole authority | AD-04, OQ-07 |
| `package-lock.json` | DELETE | Orphaned (no package.json) | Section 2 deletes |
| `Default.json` | DELETE | iTerm2 ships its own default | OQ-02 |
| `iterm2-profile.json` | DELETE | Replaced by structured profiles | OQ-02 |
| `iTerm2State.itermexport` | DELETE | Snapshot, not IaC | OQ-02, P5 |
| `tokyonight-profile.json` | DELETE | Redundant with moon | OQ-02 |
| `tokyonightmoon-profile.json` | MOVE | → `iterm2/themes/tokyonight-moon.json` | OQ-02 |
| `tokyonightsoftdark.json` | DELETE | Too similar to moon | OQ-02 |
| `tokyonightstorm-profile.json` | MOVE | → `iterm2/themes/tokyonight-storm.json` | OQ-02 |
| `wild-cherry-profile.json` | MOVE | → `iterm2/themes/wild-cherry.json` | OQ-02 |

### .claude/

| File | Verb | Rationale | Citation |
|------|------|-----------|----------|
| `.claude/README.md` | KEEP | Project config docs | — |
| `.claude/settings.json` | KEEP | Project permissions (untracked, new) | — |
| `.claude/settings.local.json` | KEEP | Local overrides (gitignored) | — |
| `.claude/claude-wrapper.sh` | DELETE | Obsolete (already staged) | Pre-0 commit |
| `.claude/config.json` | DELETE | Obsolete (already staged) | Pre-0 commit |
| `.claude/environment.sh` | DELETE | Obsolete (already staged) | Pre-0 commit |

### .gemini/

| File | Verb | Rationale | Citation |
|------|------|-----------|----------|
| `.gemini/GEMINI.md` | KEEP | Gemini CLI config | — |
| `.gemini/settings.json` | KEEP | Gemini CLI config | — |
| `.gemini/tmp/audit_script.sh` | DELETE | Temp file committed to VCS | P3-3, Anti-pattern §10 |

### .github/

| File | Verb | Rationale | Citation |
|------|------|-----------|----------|
| `.github/PULL_REQUEST_TEMPLATE.md` | KEEP | Update path refs if needed | — |
| `.github/workflows/labeler.yml` | KEEP | Update for new structure | — |
| `.github/workflows/repository-governance.yml` | KEEP | Update for new structure | — |
| `.github/workflows/shell-env-validate.yml` | KEEP | Update for new structure | — |

### .meta/

| File | Verb | Rationale | Citation |
|------|------|-----------|----------|
| `.meta/labels.yaml` | DELETE | Orphaned automation metadata | P3-6, P3 |
| `.meta/sync-info.json` | DELETE | Orphaned automation metadata | P3-6, P3 |

### 01-setup/ (6 files)

| File | Verb | Rationale | Citation |
|------|------|-----------|----------|
| `00-prerequisites.md` | DELETE | Merged into `docs/setup.md` | Section 2 deletes, P3-14 |
| `01-homebrew.md` | DELETE | Merged into `docs/setup.md` | Section 2 deletes, P3-14 |
| `02-chezmoi.md` | DELETE | Merged into `docs/setup.md` | Section 2 deletes, P3-14 |
| `03-iterm2.md` | DELETE | Merged into `docs/setup.md` | Section 2 deletes, P3-14 |
| `06-mcp-usage.md` | DELETE | Merged into `docs/tools.md` | Section 2 deletes, P3-17 |
| `07-infisical.md` | DELETE | Merged into `docs/setup.md` | Section 2 deletes, P3-14 |

### 02-configuration/ (7 files + 2 empty dirs)

| File | Verb | Rationale | Citation |
|------|------|-----------|----------|
| `editors/` (empty) | DELETE | Empty stub | Section 2, Anti-pattern §10 |
| `shells/` (empty) | DELETE | Empty stub | Section 2, Anti-pattern §10 |
| `terminals/ITERM2-CHEZMOI-INTEGRATION.md` | DELETE | Merged into `docs/terminals.md` | P3-16 |
| `terminals/iterm2-config.md` | DELETE | Merged into `docs/terminals.md` | P3-16 |
| `terminals/ITERM2-SETUP-STATUS.md` | DELETE | Merged into `docs/terminals.md` | P3-16 |
| `tools/codex-cli.md` | DELETE | Merged into `docs/tools.md` | P3-17 |
| `tools/mcp-server.md` | DELETE | Merged into `docs/tools.md` | P3-17 |
| `tools/mcp-telemetry.md` | DELETE | Merged into `docs/tools.md` | P3-17 |
| `tools/ssh-multi-account.md` | DELETE | Merged into `docs/tools.md` | P3-17 |

### 03-automation/ (9 files + 2 empty dirs)

| File | Verb | Rationale | Citation |
|------|------|-----------|----------|
| `hooks/` (empty) | DELETE | Empty stub | Section 2, Anti-pattern §10 |
| `workflows/` (empty) | DELETE | Empty stub | Section 2, Anti-pattern §10 |
| `mcp-dashboard-integration.md` | DELETE | Merged into `docs/tools.md` | P3-17 |
| `launchd/com.system.docsync.plist` | DELETE | Inactive launchd job | Section 2 deletes |
| `scripts/add-frontmatter.py` | DELETE | One-time utility, work complete | P3 |
| `scripts/apply-optimizations.sh` | DELETE | One-time utility | P3 |
| `scripts/doc-sync-engine.py` | DELETE | Superseded by chezmoi-direct approach | OQ-08 |
| `scripts/install-launchagent.sh` | DELETE | Companion to deleted plist | Section 2 |
| `scripts/setup-iterm2.sh` | DELETE | Superseded by `scripts/install-iterm2-profiles.sh` | Section 4 |
| `scripts/sync-system-state.sh` | DELETE | Superseded by chezmoi-direct approach | OQ-08 |
| `scripts/validate-iterm2.sh` | DELETE | Superseded by ng-doctor iterm2 checks | Section 7 |
| `scripts/validate-system.py` | DELETE | Superseded by ng-doctor | Section 7 |

### 04-policies/ (4 files)

| File | Verb | Rationale | Citation |
|------|------|-----------|----------|
| `opa/policy.rego` | MOVE | → `policies/opa/policy.rego` | Section 2 map |
| `policy-as-code.yaml` | DELETE | Redundant with .org/ tooling | P3-10 |
| `validate-policy.py` | DELETE | Redundant with .org/ validators | P3-10 |
| `version-policy.md` | MOVE | → `policies/version-policy.md` | P3-10 |

### 05-reference/ (1 file)

| File | Verb | Rationale | Citation |
|------|------|-----------|----------|
| `mcp-examples.md` | DELETE | Merged into `docs/tools.md` | Section 2 deletes, P3-17 |

### 06-templates/chezmoi/ — chezmoi templates

| File | Verb | Target | Citation |
|------|------|--------|----------|
| `.chezmoiignore` | MOVE | `home/.chezmoiignore` | P1-9 |
| `dot_bashrc.tmpl` | REPLACE | `home/dot_bashrc.tmpl` (rewritten per §3.6) | P1-8 |
| `dot_envrc.tmpl` | MOVE | `home/dot_envrc.tmpl` | P1-9 |
| `dot_tmux.conf.tmpl` | DELETE | tmux removed from this system | G-05 |
| `dot_zshrc.tmpl` | REPLACE | Decomposed into `home/dot_zshrc.tmpl` (thin) + `home/dot_config/zshrc.d/` | P1-5, P1-6, §3.3 |
| `dot_config/direnv/direnv.toml.tmpl` | MOVE | `home/dot_config/direnv/` | P1-9 |
| `dot_config/direnv/direnvrc.tmpl` | MOVE | `home/dot_config/direnv/` | P1-9 |
| `dot_config/fish/config.fish.tmpl` | REPLACE | `home/dot_config/fish/config.fish.tmpl` (rewritten) | P1-7 |
| `dot_config/mise/config.toml.tmpl` | REPLACE | `home/dot_config/mise/config.toml.tmpl` (rewritten per §5) | P4-5 |
| `dot_config/starship.toml.tmpl` | MOVE | `home/dot_config/starship.toml.tmpl` | P1-9 |
| `dot_config/system-update/config.tmpl` | MOVE | `home/dot_config/system-update/config.tmpl` | P1-9 |
| `README.md` | DELETE | Directory going away | Section 2 |

### 06-templates/chezmoi/ — fish conf.d/ (per OQ-01)

| File | Verb | Rationale | Citation |
|------|------|-----------|----------|
| `00-homebrew.fish.tmpl` | REPLACE | Absorbed into `home/.../00-xdg.fish.tmpl` + `01-path.fish.tmpl` | §3.5, OQ-01 |
| `01-mise.fish.tmpl` | REPLACE | → `home/.../02-mise.fish.tmpl` | §3.5 |
| `02-direnv.fish.tmpl` | REPLACE | → `home/.../03-direnv.fish.tmpl` | §3.5 |
| `03-starship.fish.tmpl` | REPLACE | → `home/.../20-prompt.fish.tmpl` | §3.5 |
| `04-paths.fish.tmpl` | REPLACE | → `home/.../01-path.fish.tmpl` (from chezmoidata) | §3.5, §6 |
| `05-keybindings.fish.tmpl` | REPLACE | → `home/.../25-keybindings.fish.tmpl` | OQ-01 |
| `06-tmux.fish.tmpl` | DELETE | Over-engineered convenience. tmux is an app, not a shell concern. | OQ-01, G-05, P15 |
| `08-iterm2-shell-integration.fish.tmpl` | REPLACE | → `home/.../30-iterm2.fish.tmpl` | OQ-01 |
| `10-claude.fish.tmpl` | DELETE | Agent tool — uses Agentic zsh profile | OQ-01, P15 |
| `12-codex.fish.tmpl` | DELETE | Agent tool — uses Agentic zsh profile | OQ-01, P15 |
| `13-windsurf.fish.tmpl` | DELETE | Agent tool — uses Agentic zsh profile | OQ-01, P15 |
| `14-sentry.fish.tmpl` | DELETE | Project-level → direnv | OQ-01, P15 |
| `15-vercel.fish.tmpl` | DELETE | Project-level → direnv | OQ-01, P15 |
| `16-supabase.fish.tmpl` | DELETE | Project-level → direnv | OQ-01, P15 |
| `17-orbstack.fish.tmpl` | REPLACE | → `home/.../40-orbstack.fish.tmpl` | OQ-01 |
| `18-tailscale.fish.tmpl` | REPLACE | → `home/.../41-tailscale.fish.tmpl` | OQ-01 |
| `19-infisical.fish.tmpl` | DELETE | Project-level → direnv | OQ-01, P15 |
| `20-gam.fish.tmpl` (untracked) | DELETE | Inactive | OQ-01 |
| `90-system-update.fish.tmpl` (untracked) | REPLACE | → `home/.../50-system-update.fish.tmpl` | OQ-01 |
| `dicee-auto.fish.tmpl` (untracked) | DELETE | Project-specific → project .envrc | OQ-01, P15 |

### 06-templates/chezmoi/ — dot_claude/ (16 files, all already staged for deletion)

| Files | Verb | Rationale | Citation |
|-------|------|-----------|----------|
| `dot_claude/CLAUDE.md`, `README.md`, `claude.json.tmpl`, `settings.json.tmpl`, `agents/*.md` (6), `commands/**/*.md` (7) | DELETE | Already staged. Global Claude config managed at ~/.claude/, not via chezmoi. | Pre-0 commit |

### 06-templates/chezmoi/ — run_once scripts

| File | Verb | Rationale | Citation |
|------|------|-----------|----------|
| `run_once_03-install-tools.sh.tmpl` | DELETE | Replaced by Brewfile | OQ-07, P5 |
| `run_once_10-install-claude.sh.tmpl` | DELETE | Replaced by Brewfile or npm -g | OQ-07, P5 |
| `run_once_12-install-codex.sh.tmpl` | DELETE | Replaced by Brewfile or npm -g | OQ-07, P5 |
| `run_once_13-install-windsurf.sh.tmpl` | DELETE | Replaced by Brewfile (cask) | OQ-07, P5 |
| `run_once_14-install-sentry.sh.tmpl` | DELETE | Replaced by Brewfile | OQ-07, P5 |
| `run_once_15-install-vercel.sh.tmpl` | DELETE | Replaced by Brewfile or npm -g | OQ-07, P5 |
| `run_once_16-install-supabase.sh.tmpl` | DELETE | Replaced by Brewfile | OQ-07, P5 |
| `run_once_17-install-orbstack.sh.tmpl` | DELETE | Replaced by Brewfile (cask) | OQ-07, P5 |
| `run_once_18-install-tailscale.sh.tmpl` | DELETE | Replaced by Brewfile (cask) | OQ-07, P5 |
| `run_once_19-install-infisical.sh.tmpl` | DELETE | Replaced by Brewfile | OQ-07, P5 |
| `run_once_20-install-fisher-plugins.fish.tmpl` | DELETE | Fisher plugin management moves to docs/shells.md or a fish-specific run_once if needed | OQ-07 |
| `run_once_21-clear-mcp-auth-cache.sh.tmpl` (untracked) | DELETE | One-time fix, not ongoing config | P5 |

### 06-templates/ — other

| File | Verb | Rationale | Citation |
|------|------|-----------|----------|
| `dotfiles/codex/config.toml` | MOVE | → `home/dot_config/codex/config.toml` (or DELETE if stale) | P3-13, OQ-03 |
| `projects/mise.toml.sample` | MOVE | → `~/Organizations/the-nash-group/.org/templates/projects/` | OQ-04, P15 |
| `projects/new-project.fish` | MOVE | → `.org/templates/projects/` | OQ-04, P15 |
| `projects/obs-hints.README.md` | MOVE | → `.org/templates/projects/` | OQ-04, P15 |
| `projects/project.manifest.yaml.sample` | MOVE | → `.org/templates/projects/` | OQ-04, P15 |
| `projects/README.md` | MOVE | → `.org/templates/projects/` | OQ-04, P15 |

### ai-tools/ (3 files)

| File | Verb | Rationale | Citation |
|------|------|-----------|----------|
| `mcp-servers.json` | MOVE | → `home/dot_config/claude/mcp-servers.json.tmpl` | OQ-03, P5 |
| `sync-to-tools.sh` | MOVE | → `scripts/sync-mcp.sh` | OQ-03, P5 |
| `README.md` | DELETE | Content merged into `docs/tools.md` | OQ-03, P3-17 |

### docs/ (28 tracked + 4 untracked)

| File | Verb | Target | Citation |
|------|------|--------|----------|
| `claude-cli-setup.md` | DELETE | → `docs/tools.md` | P3-17 |
| `claude-code-cli-settings-official.md` (untracked) | DELETE | → `docs/tools.md` | P3-17 |
| `claude-desktop-setup.md` (untracked) | DELETE | → `docs/tools.md` | P3-17 |
| `CLAUDE-CONFIG-CHEZMOI-MIGRATION.md` | DELETE | → `docs/setup.md` | P3-14 |
| `CLAUDE-CONFIG-SETUP-COMPLETE.md` | DELETE | → `docs/tools.md` | P3-17 |
| `CLAUDE-CONFIG-UPDATE-GUIDE.md` | DELETE | → `docs/tools.md` | P3-17 |
| `codex-cli-setup.md` | DELETE | → `docs/tools.md` | P3-17 |
| `codex-cli-config-docs.md` (untracked) | DELETE | → `docs/tools.md` | P3-17 |
| `codex-cli-mcp.md` (untracked) | DELETE | → `docs/tools.md` | P3-17 |
| `copilot-cli-setup.md` | DELETE | → `docs/tools.md` | P3-17 |
| `direnv-setup.md` | DELETE | → `docs/tools.md` | P3-17 |
| `fish-vs-bash-reference.md` | DELETE | → `docs/shells.md` | P3-15 |
| `guides/AGENT-HANDOFF.md` | DELETE | → `docs/agent-handoff.md` | P3-20 |
| `guides/ENVRC-MIGRATION-GUIDE.md` | DELETE | → `docs/tools.md` | P3-17 |
| `guides/GOPASS-DEFINITIVE-GUIDE.md` | DELETE | → `docs/secrets.md` | P3-18 |
| `guides/MAINTENANCE-GUIDE.md` | DELETE | → `docs/maintenance.md` | P3-19 |
| `guides/SECRETS-MANAGEMENT-ENHANCED.md` | DELETE | → `docs/secrets.md` | P3-18 |
| `guides/SECRETS-MANAGEMENT-GUIDE.md` | DELETE | → `docs/secrets.md` | P3-18 |
| `INDEX.md` | DELETE | Replaced by flat structure | Section 2 |
| `ITERM2-APS-SETUP-GUIDE.md` | DELETE | → `docs/terminals.md` | P3-16 |
| `ITERM2-BEACON-QUICK-START.md` | DELETE | → `docs/terminals.md` | P3-16 |
| `ITERM2-BEACON-SOLUTION.md` | DELETE | → `docs/terminals.md` | P3-16 |
| `iterm2-modern-setup.md` | DELETE | → `docs/terminals.md` | P3-16 |
| `ITERM2-PROFILE-STYLE-GUIDE.md` | DELETE | → `docs/terminals.md` | P3-16 |
| `MODERN-SHELL-COMPLETE-GUIDE.md` | DELETE | → `docs/shells.md` | P3-15 |
| `modern-shell-setup-2025.md` | DELETE | → `docs/shells.md` | P3-15 |
| `MODERN-SHELL-SETUP-SUMMARY.md` | DELETE | → `docs/shells.md` | P3-15 |
| `orbstack-safety-review.md` | DELETE | → `docs/tools.md` | P3-17 |
| `orbstack-setup.md` | DELETE | → `docs/tools.md` | P3-17 |
| `policies/ports-and-env.md` | DELETE | → `docs/tools.md` or `policies/` | P3-17 |
| `PROJECT-SETUP.md` | DELETE | → `docs/setup.md` | P3-14 |
| `sentry-cli-setup.md` | DELETE | → `docs/tools.md` | P3-17 |
| `SHELL-CONFIG-SAFETY.md` | DELETE | → `docs/shells.md` | P3-15 |
| `system-registry.example.yaml` | DELETE | Superseded by .org/ schemas | P3 |
| `terraform-cli-setup.md` | DELETE | → `docs/tools.md` | P3-17 |
| `vercel-cli-setup.md` | DELETE | → `docs/tools.md` | P3-17 |

### scripts/ (tracked: 22 files + untracked: system-update.sh, system-update.d/)

| File | Verb | Rationale | Citation |
|------|------|-----------|----------|
| `system-update.sh` (untracked) | KEEP | Main update orchestrator | AGENTS.md |
| `system-update.d/` (untracked) | KEEP | Drop-in plugins | AGENTS.md |
| `sync-chezmoi-templates.sh` | DELETE | chezmoi points at home/ directly | OQ-08, SSoT |
| `doctor-path.sh` | DELETE | Superseded by ng-doctor | Section 7, P11 |
| `doctor-env.sh` | DELETE | Superseded by ng-doctor | Section 7, P11 |
| `system-health.sh` | DELETE | Superseded by ng-doctor | Section 7, P11 |
| `iterm2-setup.sh` | DELETE | Superseded by install-iterm2-profiles.sh | Section 4 |
| `deploy-shell-config.sh` | DELETE | Replaced by chezmoi apply | OQ-08 |
| `repair-shell-env.sh` | DELETE | Superseded by shell stabilization | Phase 1 |
| `verify-shell-safety.fish` | DELETE | Superseded by ng-doctor | Section 7 |
| `verify-orbstack-config.sh` | DELETE | One-time verification | P3 |
| `system-audit-collect.sh` | DELETE | One-time audit tool | P3 |
| `terraform-auth-setup.sh` | KEEP | Active utility — not superseded | — |
| `daily-update.sh` | DELETE | Consolidated into system-update.sh | OQ-07, Pre-0 |
| `update-all.sh` | DELETE | Consolidated into system-update.sh | OQ-07, Pre-0 |
| `update-claude-cli.sh` | DELETE | Consolidated into system-update.sh | OQ-07, Pre-0 |
| `update-codex-cli.sh` | DELETE | Consolidated | OQ-07 |
| `update-copilot-cli.sh` | DELETE | Consolidated | OQ-07 |
| `update-infisical-cli.sh` | DELETE | Consolidated | OQ-07 |
| `update-orbstack.sh` | DELETE | Consolidated | OQ-07 |
| `update-sentry-cli.sh` | DELETE | Consolidated | OQ-07 |
| `update-supabase-cli.sh` | DELETE | Consolidated | OQ-07 |
| `update-terraform-cli.sh` | DELETE | Consolidated | OQ-07 |
| `update-vercel-cli.sh` | DELETE | Consolidated | OQ-07 |

---

## Appendix B: Target Repo Structure (Post-Migration)

```
system-config/
├── AGENTS.md
├── CLAUDE.md
├── README.md
├── CHANGELOG.md
├── DEVMACHINE-SPEC.md
├── IMPLEMENTATION-PLAN.md
├── # FILESYSTEM-MIGRATION-SPEC.md        # DEFERRED: created when migration begins
│
├── home/                                  # chezmoi source (symlinked from ~/.local/share/chezmoi)
│   ├── .chezmoi.toml.tmpl
│   ├── .chezmoidata.yaml
│   ├── .chezmoiignore
│   ├── dot_zshenv.tmpl
│   ├── dot_zprofile.tmpl
│   ├── dot_zshrc.tmpl
│   ├── dot_bash_profile.tmpl
│   ├── dot_bashrc.tmpl
│   ├── dot_envrc.tmpl
│   ├── dot_config/
│   │   ├── fish/
│   │   │   ├── config.fish.tmpl
│   │   │   └── conf.d/                   # 14 modules
│   │   │       ├── 00-xdg.fish.tmpl
│   │   │       ├── 01-path.fish.tmpl
│   │   │       ├── 02-mise.fish.tmpl
│   │   │       ├── 03-direnv.fish.tmpl
│   │   │       ├── 10-aliases.fish.tmpl
│   │   │       ├── 15-coreutil-aliases.fish.tmpl
│   │   │       ├── 20-prompt.fish.tmpl
│   │   │       ├── 25-keybindings.fish.tmpl
│   │   │       ├── 30-iterm2.fish.tmpl
│   │   │       ├── 40-orbstack.fish.tmpl
│   │   │       ├── 41-tailscale.fish.tmpl
│   │   │       ├── 50-system-update.fish.tmpl
│   │   │       └── 99-local.fish.tmpl
│   │   ├── zshrc.d/                       # 14 modules
│   │   │   ├── 00-xdg.zsh.tmpl
│   │   │   ├── 01-path.zsh.tmpl
│   │   │   ├── 02-mise.zsh.tmpl
│   │   │   ├── 03-direnv.zsh.tmpl
│   │   │   ├── 10-aliases.zsh.tmpl
│   │   │   ├── 15-coreutil-aliases.zsh.tmpl   # GATED: interactive-only
│   │   │   ├── 20-interactive.zsh.tmpl         # GATED: interactive-only
│   │   │   ├── 21-completion.zsh.tmpl          # GATED: interactive-only
│   │   │   ├── 22-prompt.zsh.tmpl              # GATED: interactive-only
│   │   │   ├── 30-agentic.zsh.tmpl             # GATED: agentic-only
│   │   │   ├── 40-orbstack.zsh.tmpl
│   │   │   ├── 41-tailscale.zsh.tmpl
│   │   │   └── 99-local.zsh.tmpl
│   │   ├── mise/config.toml.tmpl
│   │   ├── git/config.tmpl
│   │   ├── git/ignore.tmpl
│   │   ├── claude/mcp-servers.json.tmpl
│   │   ├── starship.toml.tmpl
│   │   ├── direnv/direnvrc.tmpl
│   │   ├── direnv/direnv.toml.tmpl
│   │   └── system-update/config.tmpl
│   ├── dot_local/bin/
│   │   └── ng-doctor.tmpl
│   └── run_once_before/
│       ├── 00-filesystem-scaffold.sh.tmpl
│       ├── 01-homebrew.sh.tmpl
│       ├── 02-brew-packages.sh.tmpl
│       └── 03-mise-global.sh.tmpl
│
├── iterm2/
│   ├── profiles/
│   │   ├── dev-zsh.json
│   │   ├── agentic-zsh.json
│   │   └── human-fish.json
│   ├── themes/
│   │   ├── tokyonight-moon.json
│   │   ├── tokyonight-storm.json
│   │   └── wild-cherry.json
│   └── README.md
│
├── scripts/
│   ├── system-update.sh
│   ├── system-update.d/
│   ├── install-iterm2-profiles.sh
│   ├── sync-mcp.sh
│   └── terraform-auth-setup.sh
│
├── policies/
│   └── opa/
│       └── policy.rego
│
├── docs/
│   ├── setup.md
│   ├── shells.md
│   ├── terminals.md
│   ├── tools.md
│   ├── secrets.md
│   ├── maintenance.md
│   └── agent-handoff.md
│
├── .claude/
│   ├── README.md
│   └── settings.json
├── .gemini/
│   ├── GEMINI.md
│   └── settings.json
├── .github/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/
│       ├── labeler.yml
│       ├── repository-governance.yml
│       └── shell-env-validate.yml
├── .gitignore
└── .mise.toml
```
