# shellcheck shell=bash
plugin_register "r-packages" "CRAN packages in R user library" "Rscript" "false"

run_r-packages() {
  if ! have Rscript; then
    log info "Rscript not found, skipping"
    return 0
  fi
  Rscript --no-save --no-restore --no-init-file - <<'EOF'
user_lib <- Sys.getenv("R_LIBS_USER", unset = "")
if (!nzchar(user_lib)) user_lib <- tools::R_user_dir("library", which = "data")
user_lib <- path.expand(user_lib)
if (!dir.exists(user_lib)) dir.create(user_lib, recursive = TRUE)

# Scope to the user library only — site-library and base packages are
# managed by `brew upgrade r`.
update.packages(
  lib.loc    = user_lib,
  ask        = FALSE,
  checkBuilt = TRUE,
  repos      = "https://cloud.r-project.org"
)
EOF
}

check_r-packages() {
  if ! have Rscript; then
    return 0
  fi
  Rscript --no-save --no-restore --no-init-file - <<'EOF'
user_lib <- Sys.getenv("R_LIBS_USER", unset = "")
if (!nzchar(user_lib)) user_lib <- tools::R_user_dir("library", which = "data")
user_lib <- path.expand(user_lib)
if (!dir.exists(user_lib)) {
  cat("R user library not yet created:", user_lib, "\n")
  quit(status = 0)
}
old <- old.packages(lib.loc = user_lib, repos = "https://cloud.r-project.org")
if (is.null(old)) {
  cat("No outdated R packages in", user_lib, "\n")
} else {
  print(old[, c("Package", "Installed", "ReposVer")])
}
EOF
}
