# system-update.d — Plugin Directory

Drop `*.sh` files here to extend `system-update` with additional update steps.

## Plugin Contract

Each plugin file is **sourced** (not executed) by the core script in lexical
order, after the built-in steps but before cleanup.

Define one or both of these functions (replace `<name>` with your plugin's
base filename without `.sh`):

| Function | Called when | Purpose |
|----------|-----------|---------|
| `run_<name>()` | Default update mode | Perform the actual update |
| `check_<name>()` | `--check` mode | Show status / what's outdated |

Optional metadata (recommended) to improve `--list` output and selection:

```bash
plugin_register "<name>" "<description>" "<requires>" "<default>"
```

- `description`: Friendly label shown in `--list` and status output.
- `requires`: Space-separated command list for availability checks.
- `default`: `true` or `false` (whether enabled by default).

## Available Helpers

Plugins have access to all core helpers:

- `log <level> <message>` — Console + log output (`info`, `ok`, `warn`, `error`, `debug`, `step`)
- `ndjson <level> <event> <msg> [extra_json]` — Structured log event
- `run_step "<name>" <command...>` — Wrap a command with timing and error handling
- `have <cmd>` — Check if a command exists (returns 0/1)
- `$MODE` — Current mode: `"update"` or `"check"`
- `$DEBUG` — `true` if `--debug` was passed
- `$SYSTEM_UPDATE_GO_TOOLS` — Optional array used by `go-tools` plugin

## Included Plugins

| Plugin | Description | Default | Requires |
|--------|-------------|---------|----------|
| `rustup` | Legacy rustup toolchains | disabled | `rustup` |
| `pipx` | pipx packages | enabled | `pipx` |
| `uv` | uv tools | enabled | `uv` |
| `brew-casks` | Homebrew casks | disabled | `brew` |
| `mas` | Mac App Store apps | disabled | `mas` |
| `gem` | Ruby gems | disabled | `gem` |
| `go-tools` | Go tools (go install) | disabled | `go` |
| `android-studio-canary` | Android Studio Preview | disabled | `curl python3` |

Enable disabled plugins via config or CLI:
```bash
# In ~/.config/system-update/config
SYSTEM_UPDATE_ENABLE=(android-studio-canary brew-casks)

# Or one-off via CLI
system-update --only android-studio-canary
```

`rustup` is kept only for legacy/manual installs. The normal Rust path on this
system should be the global `mise` config so `system-update` upgrades it during
the core `mise runtimes` step.

## Example

File: `scripts/system-update.d/90-cargo.sh`

```bash
plugin_register "90-cargo" "Cargo packages" "cargo" "true"

run_90-cargo() {
  if ! have cargo; then
    log info "cargo not found, skipping"
    return 0
  fi
  if have cargo-install-update; then
    cargo install-update -a
  else
    log warn "cargo-update not installed (cargo install cargo-update)"
  fi
}

check_90-cargo() {
  if ! have cargo; then return 0; fi
  cargo install --list
}
```
