#!/usr/bin/env python3
"""
Organize and update repositories
- Pull latest changes
- Add mise configuration
- Setup .envrc files
- Identify inactive projects
Generated: 2025-09-26
"""

import os
import json
import subprocess
from pathlib import Path
from datetime import datetime, timedelta

def run_command(cmd, cwd):
    """Run a command and return success status"""
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            shell=True,
            timeout=30
        )
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)

def pull_latest(repo_path):
    """Pull latest changes from remote"""
    # First, stash any uncommitted changes
    success, _, _ = run_command("git stash", repo_path)

    # Pull latest
    success, stdout, stderr = run_command("git pull --rebase", repo_path)

    # If we stashed, try to pop
    if success:
        run_command("git stash pop", repo_path)

    return success

def add_mise_config(repo_path):
    """Add .mise.toml configuration if needed"""
    mise_path = repo_path / ".mise.toml"

    # Skip if already exists
    if mise_path.exists():
        return False

    # Detect project type
    project_type = detect_project_type(repo_path)

    if project_type == "node":
        config = """[tools]
node = "24"
bun = "latest"

[tasks]
test = "bun test"
lint = "bun run lint"
dev = "bun run dev"
build = "bun run build"
"""
    elif project_type == "python":
        config = """[tools]
python = "3.13"

[tasks]
test = "pytest"
lint = "ruff check ."
format = "ruff format ."
dev = "python -m uvicorn main:app --reload"
"""
    elif project_type == "go":
        config = """[tools]
go = "latest"

[tasks]
test = "go test ./..."
lint = "golangci-lint run"
build = "go build -o bin/app"
run = "go run ."
"""
    else:
        return False

    mise_path.write_text(config)
    # Trust the new config to avoid prompts
    run_command("mise trust .mise.toml", repo_path)
    return True

def add_envrc(repo_path):
    """Add .envrc for direnv integration"""
    envrc_path = repo_path / ".envrc"

    # Skip if already exists
    if envrc_path.exists():
        return False

    content = """# direnv configuration
# Generated: 2025-09-26

# Load mise integration and activate tools (no external calls)
use_mise() {
  direnv_load mise direnv exec
}
use mise

# Project-specific environment variables
# export API_KEY=\"your-key-here\"
# export DATABASE_URL=\"postgresql://localhost/dbname\"

# Add local bin to PATH
PATH_add bin
PATH_add node_modules/.bin

# Load env files if present (safe)
dotenv_if_exists .env.local
dotenv_if_exists .env
"""

    envrc_path.write_text(content)

    # Allow direnv
    run_command("direnv allow", repo_path)

    return True

def detect_project_type(repo_path):
    """Detect the type of project"""
    if (repo_path / "package.json").exists():
        return "node"
    elif (repo_path / "requirements.txt").exists() or (repo_path / "pyproject.toml").exists():
        return "python"
    elif (repo_path / "go.mod").exists():
        return "go"
    elif (repo_path / "Cargo.toml").exists():
        return "rust"
    else:
        return "unknown"

def is_inactive(repo_info):
    """Determine if a repository is inactive"""
    # Parse last commit date
    try:
        if repo_info['last_commit'] != 'unknown':
            last_commit = datetime.fromisoformat(repo_info['last_commit'].replace(' ', 'T').split('+')[0])
            days_old = (datetime.now() - last_commit).days

            # Consider inactive if no commits in 90 days
            return days_old > 90
    except:
        pass

    return False

def main():
    """Main organization function"""
    print("🔄 Organizing and updating repositories\n")

    # Load scan results
    report_dir = Path.home() / "Development" / "personal" / "system-setup-update" / "07-reports"
    scan_report = report_dir / f"repo-scan-{datetime.now().strftime('%Y-%m-%d')}.json"

    if not scan_report.exists():
        print("❌ No scan report found. Please run repo-scanner.py first.")
        return

    with open(scan_report) as f:
        repos = json.load(f)

    # Statistics
    stats = {
        'pulled': 0,
        'pull_failed': 0,
        'mise_added': 0,
        'envrc_added': 0,
        'inactive': 0
    }

    # Process each repository
    results = []
    for repo in repos:
        repo_path = Path(repo['path'])

        # Skip if path doesn't exist
        if not repo_path.exists():
            continue

        print(f"Processing {repo['profile']}/{repo['name']}...")

        result = {
            'name': repo['name'],
            'profile': repo['profile'],
            'path': repo['path'],
            'actions': []
        }

        # Pull latest if has remote and is behind
        if repo['has_remote'] and repo['behind'] > 0:
            print(f"  ⬇️  Pulling latest changes...")
            if pull_latest(repo_path):
                result['actions'].append('pulled')
                stats['pulled'] += 1
            else:
                result['actions'].append('pull_failed')
                stats['pull_failed'] += 1

        # Add mise configuration
        if add_mise_config(repo_path):
            print(f"  📦 Added .mise.toml")
            result['actions'].append('mise_added')
            stats['mise_added'] += 1

        # Add envrc
        if add_envrc(repo_path):
            print(f"  🔧 Added .envrc")
            result['actions'].append('envrc_added')
            stats['envrc_added'] += 1

        # Check if inactive
        if is_inactive(repo):
            print(f"  💤 Marked as inactive")
            result['actions'].append('inactive')
            stats['inactive'] += 1

        results.append(result)

    # Generate organization report
    report_file = report_dir / f"organization-report-{datetime.now().strftime('%Y-%m-%d')}.md"
    with open(report_file, 'w') as f:
        f.write(f"# Repository Organization Report\n")
        f.write(f"**Date**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")

        f.write("## Actions Performed\n\n")
        f.write(f"- **Pulled Latest**: {stats['pulled']} repositories\n")
        f.write(f"- **Pull Failed**: {stats['pull_failed']} repositories\n")
        f.write(f"- **Mise Config Added**: {stats['mise_added']} repositories\n")
        f.write(f"- **Envrc Added**: {stats['envrc_added']} repositories\n")
        f.write(f"- **Inactive Projects**: {stats['inactive']} repositories\n\n")

        # List inactive projects
        inactive_repos = [r for r in results if 'inactive' in r['actions']]
        if inactive_repos:
            f.write("## Inactive Projects (>90 days)\n\n")
            f.write("These projects should be considered for archiving:\n\n")
            for repo in inactive_repos:
                f.write(f"- **{repo['profile']}/{repo['name']}**\n")

        # List failed pulls
        failed_repos = [r for r in results if 'pull_failed' in r['actions']]
        if failed_repos:
            f.write("\n## Failed Updates\n\n")
            f.write("These repositories need manual attention:\n\n")
            for repo in failed_repos:
                f.write(f"- **{repo['profile']}/{repo['name']}**\n")

    # Save detailed results
    results_file = report_dir / f"organization-results-{datetime.now().strftime('%Y-%m-%d')}.json"
    with open(results_file, 'w') as f:
        json.dump(results, f, indent=2)

    print(f"\n📊 Organization complete!")
    print(f"   Pulled: {stats['pulled']} repositories")
    print(f"   Failed: {stats['pull_failed']} pulls")
    print(f"   Mise configs: {stats['mise_added']} added")
    print(f"   Envrc files: {stats['envrc_added']} added")
    print(f"   Inactive: {stats['inactive']} projects")
    print(f"\n📝 Reports saved to: {report_dir}")

if __name__ == "__main__":
    main()
