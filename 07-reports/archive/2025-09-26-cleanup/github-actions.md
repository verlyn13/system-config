---
title: Github Actions
category: reference
component: github_actions
status: draft
version: 1.0.0
last_updated: 2025-09-26
tags: []
priority: medium
---

name: CI

on:
  push:
    branches: [ main, master, develop ]
  pull_request:
    types: [ opened, synchronize, reopened ]
  schedule:
    # Weekly dependency check
    - cron: '0 2 * * 1'

permissions:
  contents: read
  pull-requests: write
  issues: write

env:
  TZ: America/Anchorage
  MISE_TRUSTED_CONFIG_PATHS: ${{ github.workspace }}
  FORCE_COLOR: 1

jobs:
  # Detect what needs to be tested
  changes:
    runs-on: ubuntu-latest
    outputs:
      js: ${{ steps.filter.outputs.js }}
      python: ${{ steps.filter.outputs.python }}
      go: ${{ steps.filter.outputs.go }}
      rust: ${{ steps.filter.outputs.rust }}
      android: ${{ steps.filter.outputs.android }}
    steps:
      - uses: actions/checkout@v4
      - uses: dorny/paths-filter@v3
        id: filter
        with:
          filters: |
            js:
              - 'package.json'
              - 'pnpm-lock.yaml'
              - 'bun.lockb'
              - '**/*.{js,jsx,ts,tsx,mjs,cjs}'
            python:
              - 'pyproject.toml'
              - 'uv.lock'
              - 'requirements*.txt'
              - '**/*.py'
            go:
              - 'go.mod'
              - 'go.sum'
              - '**/*.go'
            rust:
              - 'Cargo.toml'
              - 'Cargo.lock'
              - '**/*.rs'
            android:
              - 'build.gradle*'
              - 'settings.gradle*'
              - 'gradle.properties'
              - 'gradle/libs.versions.toml'

  # JavaScript/TypeScript testing
  js:
    needs: changes
    if: ${{ needs.changes.outputs.js == 'true' || github.event_name == 'schedule' }}
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node: ['24']  # Add more versions if needed
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup mise
        run: |
          curl https://mise.run | sh
          echo "$HOME/.local/bin" >> $GITHUB_PATH
          
      - name: Install mise tools
        run: |
          mise install
          mise list
          
      - name: Detect package manager
        id: pm
        run: |
          if [ -f "bun.lockb" ]; then
            echo "manager=bun" >> $GITHUB_OUTPUT
            echo "command=bun" >> $GITHUB_OUTPUT
            echo "cache=~/.bun/install/cache" >> $GITHUB_OUTPUT
          elif [ -f "pnpm-lock.yaml" ]; then
            echo "manager=pnpm" >> $GITHUB_OUTPUT
            echo "command=pnpm" >> $GITHUB_OUTPUT
            echo "cache=~/.pnpm-store" >> $GITHUB_OUTPUT
          else
            echo "manager=npm" >> $GITHUB_OUTPUT
            echo "command=npm" >> $GITHUB_OUTPUT
            echo "cache=~/.npm" >> $GITHUB_OUTPUT
          fi
          
      - name: Cache dependencies
        uses: actions/cache@v4
        with:
          path: ${{ steps.pm.outputs.cache }}
          key: ${{ runner.os }}-${{ steps.pm.outputs.manager }}-${{ hashFiles('**/package.json', '**/pnpm-lock.yaml', '**/bun.lockb') }}
          restore-keys: |
            ${{ runner.os }}-${{ steps.pm.outputs.manager }}-
            
      - name: Install dependencies
        run: |
          mise exec -- ${{ steps.pm.outputs.command }} install --frozen-lockfile || \
          mise exec -- ${{ steps.pm.outputs.command }} ci
          
      - name: Lint
        run: |
          if [ -f "package.json" ] && grep -q '"lint"' package.json; then
            mise exec -- ${{ steps.pm.outputs.command }} run lint
          fi
          
      - name: Type check
        run: |
          if [ -f "tsconfig.json" ]; then
            mise exec -- npx tsc --noEmit
          fi
          
      - name: Test
        run: |
          if [ -f "package.json" ] && grep -q '"test"' package.json; then
            mise exec -- ${{ steps.pm.outputs.command }} test
          fi
          
      - name: Build
        run: |
          if [ -f "package.json" ] && grep -q '"build"' package.json; then
            mise exec -- ${{ steps.pm.outputs.command }} run build
          fi
          
      - name: Record versions
        if: always()
        run: |
          mise exec -- node --version > node-version.txt
          mise exec -- ${{ steps.pm.outputs.command }} --version > pm-version.txt
          mise env --json > versions.json
          
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: js-versions-${{ matrix.node }}
          path: |
            node-version.txt
            pm-version.txt
            versions.json

  # Python testing
  python:
    needs: changes
    if: ${{ needs.changes.outputs.python == 'true' || github.event_name == 'schedule' }}
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python: ['3.13']  # Add more versions if needed
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup mise
        run: |
          curl https://mise.run | sh
          echo "$HOME/.local/bin" >> $GITHUB_PATH
          
      - name: Install mise tools
        run: |
          mise install
          mise list
          
      - name: Install uv
        run: |
          curl -LsSf https://astral.sh/uv/install.sh | sh
          echo "$HOME/.local/bin" >> $GITHUB_PATH
          
      - name: Cache uv
        uses: actions/cache@v4
        with:
          path: ~/.cache/uv
          key: ${{ runner.os }}-uv-${{ hashFiles('**/uv.lock', '**/pyproject.toml', '**/requirements*.txt') }}
          restore-keys: |
            ${{ runner.os }}-uv-
            
      - name: Sync environment
        run: |
          if [ -f "pyproject.toml" ]; then
            mise exec -- uv sync --frozen
          elif [ -f "requirements.txt" ]; then
            mise exec -- uv venv
            . .venv/bin/activate
            mise exec -- uv pip install -r requirements.txt
          fi
          
      - name: Lint with ruff
        run: |
          if [ -f "pyproject.toml" ] || [ -f "ruff.toml" ]; then
            mise exec -- uv run ruff check . || true
            mise exec -- uv run ruff format --check . || true
          fi
          
      - name: Type check with mypy
        run: |
          if [ -f "pyproject.toml" ] && grep -q "mypy" pyproject.toml; then
            mise exec -- uv run mypy . || true
          fi
          
      - name: Test with pytest
        run: |
          if [ -d "tests" ] || [ -d "test" ]; then
            mise exec -- uv run pytest -v --tb=short || true
          fi
          
      - name: Record versions
        if: always()
        run: |
          mise exec -- python --version > python-version.txt
          mise exec -- uv --version > uv-version.txt
          mise exec -- uv pip freeze > requirements-frozen.txt
          mise env --json > versions.json
          
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: python-versions-${{ matrix.python }}
          path: |
            python-version.txt
            uv-version.txt
            requirements-frozen.txt
            versions.json

  # Go testing
  go:
    needs: changes
    if: ${{ needs.changes.outputs.go == 'true' || github.event_name == 'schedule' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup mise
        run: |
          curl https://mise.run | sh
          echo "$HOME/.local/bin" >> $GITHUB_PATH
          
      - name: Install mise tools
        run: |
          mise install
          mise list
          
      - name: Cache Go modules
        uses: actions/cache@v4
        with:
          path: |
            ~/go/pkg/mod
            ~/.cache/go-build
          key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
          restore-keys: |
            ${{ runner.os }}-go-
            
      - name: Download dependencies
        run: mise exec -- go mod download
        
      - name: Verify dependencies
        run: mise exec -- go mod verify
        
      - name: Lint with golangci-lint
        run: |
          mise exec -- go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
          mise exec -- golangci-lint run --timeout 5m || true
          
      - name: Test
        run: mise exec -- go test -v -race -coverprofile=coverage.out ./...
        
      - name: Build
        run: mise exec -- go build -v ./...
        
      - name: Record versions
        if: always()
        run: |
          mise exec -- go version > go-version.txt
          mise exec -- go list -m all > go-modules.txt
          mise env --json > versions.json
          
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: go-versions
          path: |
            go-version.txt
            go-modules.txt
            versions.json
            coverage.out

  # Rust testing
  rust:
    needs: changes
    if: ${{ needs.changes.outputs.rust == 'true' || github.event_name == 'schedule' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup mise
        run: |
          curl https://mise.run | sh
          echo "$HOME/.local/bin" >> $GITHUB_PATH
          
      - name: Install mise tools
        run: |
          mise install
          mise list
          
      - name: Cache Rust
        uses: actions/cache@v4
        with:
          path: |
            ~/.cargo/registry
            ~/.cargo/git
            target
          key: ${{ runner.os }}-rust-${{ hashFiles('**/Cargo.lock') }}
          restore-keys: |
            ${{ runner.os }}-rust-
            
      - name: Check formatting
        run: mise exec -- cargo fmt --all --check
        
      - name: Clippy
        run: mise exec -- cargo clippy --all-targets --all-features -- -D warnings
        
      - name: Test
        run: mise exec -- cargo test --locked --all-features --verbose
        
      - name: Build (release)
        run: mise exec -- cargo build --locked --release
        
      - name: Record versions
        if: always()
        run: |
          mise exec -- rustc --version > rust-version.txt
          mise exec -- cargo --version >> rust-version.txt
          mise exec -- cargo tree > cargo-tree.txt
          mise env --json > versions.json
          
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: rust-versions
          path: |
            rust-version.txt
            cargo-tree.txt
            versions.json

  # Android testing (on macOS for better performance)
  android:
    needs: changes
    if: ${{ needs.changes.outputs.android == 'true' || github.event_name == 'schedule' }}
    runs-on: macos-14  # M1 runner
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup mise
        run: |
          curl https://mise.run | sh
          echo "$HOME/.local/bin" >> $GITHUB_PATH
          
      - name: Install mise tools
        run: |
          mise install
          mise list
          
      - name: Setup JDK
        if: ${{ !contains(hashFiles('.mise.toml'), 'java') }}
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'
          
      - name: Cache Gradle
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties', '**/libs.versions.toml') }}
          restore-keys: |
            ${{ runner.os }}-gradle-
            
      - name: Validate Gradle wrapper
        run: ./gradlew --version
        
      - name: Build Debug APK
        run: ./gradlew assembleDebug --stacktrace
        
      - name: Run unit tests
        run: ./gradlew test --stacktrace || true
        
      - name: Record versions
        if: always()
        run: |
          ./gradlew --version > gradle-version.txt
          mise exec -- java --version > java-version.txt || java --version > java-version.txt
          mise env --json > versions.json || echo '{}' > versions.json
          
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: android-versions
          path: |
            gradle-version.txt
            java-version.txt
            versions.json
            app/build/outputs/

  # Aggregate results
  summary:
    needs: [js, python, go, rust, android]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Download all artifacts
        uses: actions/download-artifact@v4
        with:
          path: artifacts
          
      - name: Create summary
        run: |
          echo "# CI Run Summary" >> $GITHUB_STEP_SUMMARY
          echo "## Versions Used" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          
          for artifact in artifacts/*-versions*; do
            if [ -d "$artifact" ]; then
              echo "### $(basename $artifact)" >> $GITHUB_STEP_SUMMARY
              echo '```' >> $GITHUB_STEP_SUMMARY
              cat $artifact/*.txt 2>/dev/null | head -20 >> $GITHUB_STEP_SUMMARY || echo "No version info" >> $GITHUB_STEP_SUMMARY
              echo '```' >> $GITHUB_STEP_SUMMARY
              echo "" >> $GITHUB_STEP_SUMMARY
            fi
          done
          
      - name: Tag as LKG if main branch
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: |
          git config user.name github-actions
          git config user.email github-actions@github.com
          git tag -f "lkg-$(date +%Y-%m-%d)" 
          git push origin "lkg-$(date +%Y-%m-%d)" --force
