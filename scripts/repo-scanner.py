#!/usr/bin/env python3
"""
Repository Scanner - Comprehensive Git Status Check
Generated: 2025-09-26
"""

import os
import json
import subprocess
from pathlib import Path
from datetime import datetime
from collections import defaultdict

# Colors for output
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[0;34m'
NC = '\033[0m'  # No Color

def run_git_command(cmd, cwd):
    """Run a git command and return output"""
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            shell=True,
            timeout=5
        )
        return result.stdout.strip() if result.returncode == 0 else None
    except (subprocess.TimeoutExpired, Exception):
        return None

def scan_repository(repo_path):
    """Scan a single repository and return its status"""
    repo_name = repo_path.name
    profile = repo_path.parent.name

    # Get current branch
    current_branch = run_git_command("git branch --show-current", repo_path)
    if not current_branch:
        current_branch = "unknown"

    # Check for remote
    remote_output = run_git_command("git remote -v", repo_path)
    has_remote = bool(remote_output and "origin" in remote_output)

    # Get last commit date
    last_commit = run_git_command("git log -1 --format=%ci", repo_path)
    if not last_commit:
        last_commit = "unknown"

    # Check for uncommitted changes
    status_output = run_git_command("git status --porcelain", repo_path)
    uncommitted = len(status_output.splitlines()) if status_output else 0

    # Check for untracked files
    untracked_output = run_git_command("git ls-files --others --exclude-standard", repo_path)
    untracked = len(untracked_output.splitlines()) if untracked_output else 0

    # Check remote status
    behind = 0
    ahead = 0
    if has_remote:
        # Fetch quietly
        run_git_command("git fetch --quiet", repo_path)

        # Check behind/ahead
        behind_output = run_git_command(f"git rev-list HEAD..origin/{current_branch} 2>/dev/null | wc -l", repo_path)
        ahead_output = run_git_command(f"git rev-list origin/{current_branch}..HEAD 2>/dev/null | wc -l", repo_path)

        try:
            behind = int(behind_output.strip()) if behind_output else 0
            ahead = int(ahead_output.strip()) if ahead_output else 0
        except (ValueError, AttributeError):
            behind = 0
            ahead = 0

    # Determine status
    if uncommitted > 0:
        status = "uncommitted"
        status_symbol = f"{YELLOW}⚠️"
        status_msg = f"{uncommitted} uncommitted changes, {untracked} untracked files"
    elif behind > 0 and ahead > 0:
        status = "diverged"
        status_symbol = f"{RED}🔄"
        status_msg = f"diverged: {behind} behind, {ahead} ahead"
    elif behind > 0:
        status = "behind"
        status_symbol = f"{RED}⬇️"
        status_msg = f"{behind} commits behind remote"
    elif ahead > 0:
        status = "ahead"
        status_symbol = f"{BLUE}⬆️"
        status_msg = f"{ahead} commits ahead of remote"
    elif not has_remote:
        status = "no-remote"
        status_symbol = f"{YELLOW}🏝️"
        status_msg = "no remote configured"
    else:
        status = "clean"
        status_symbol = f"{GREEN}✓"
        status_msg = "clean"

    # Print status
    print(f"{status_symbol}  {profile}/{repo_name}{NC} - {status_msg}")

    return {
        "name": repo_name,
        "path": str(repo_path),
        "profile": profile,
        "branch": current_branch,
        "status": status,
        "uncommitted": uncommitted,
        "untracked": untracked,
        "behind": behind,
        "ahead": ahead,
        "has_remote": has_remote,
        "last_commit": last_commit
    }

def main():
    """Main scanning function"""
    print(f"{BLUE}=== Repository Scanner ==={NC}")
    print(f"{BLUE}Scanning all Git repositories in ~/Development...{NC}\n")

    dev_dir = Path.home() / "Development"
    report_dir = dev_dir / "personal" / "system-setup-update" / "07-reports"
    report_dir.mkdir(parents=True, exist_ok=True)

    # Initialize counters
    stats = defaultdict(int)
    all_repos = []

    # Scan all profiles
    for profile_dir in sorted(dev_dir.iterdir()):
        if not profile_dir.is_dir() or profile_dir.name.startswith('.'):
            continue

        print(f"\n{BLUE}Scanning {profile_dir.name} profile...{NC}")

        for repo_dir in sorted(profile_dir.iterdir()):
            if repo_dir.is_dir() and (repo_dir / ".git").exists():
                repo_info = scan_repository(repo_dir)
                all_repos.append(repo_info)
                stats[repo_info["status"]] += 1
                stats["total"] += 1

    # Save JSON report
    json_report_path = report_dir / f"repo-scan-{datetime.now().strftime('%Y-%m-%d')}.json"
    with open(json_report_path, 'w') as f:
        json.dump(all_repos, f, indent=2)

    # Generate markdown summary
    summary_path = report_dir / f"repo-scan-summary-{datetime.now().strftime('%Y-%m-%d')}.md"
    with open(summary_path, 'w') as f:
        f.write(f"# Repository Scan Report\n")
        f.write(f"**Date**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"**Total Repositories**: {stats['total']}\n\n")

        f.write("## Summary Statistics\n\n")
        f.write("| Status | Count | Percentage |\n")
        f.write("|--------|-------|------------|\n")

        total = stats['total']
        for status in ['clean', 'uncommitted', 'behind', 'ahead', 'diverged', 'no-remote']:
            count = stats.get(status, 0)
            percentage = (count / total * 100) if total > 0 else 0
            f.write(f"| {status.replace('-', ' ').title()} | {count} | {percentage:.1f}% |\n")

        # Add repos requiring attention
        f.write("\n## Repositories Requiring Attention\n\n")

        # Uncommitted changes
        uncommitted_repos = [r for r in all_repos if r['status'] == 'uncommitted']
        if uncommitted_repos:
            f.write("### ⚠️ Uncommitted Changes\n")
            for repo in uncommitted_repos:
                f.write(f"- **{repo['profile']}/{repo['name']}**: {repo['uncommitted']} uncommitted, {repo['untracked']} untracked\n")

        # Behind remote
        behind_repos = [r for r in all_repos if r['status'] == 'behind']
        if behind_repos:
            f.write("\n### ⬇️ Behind Remote\n")
            for repo in behind_repos:
                f.write(f"- **{repo['profile']}/{repo['name']}**: {repo['behind']} commits behind\n")

        # Diverged
        diverged_repos = [r for r in all_repos if r['status'] == 'diverged']
        if diverged_repos:
            f.write("\n### 🔄 Diverged from Remote\n")
            for repo in diverged_repos:
                f.write(f"- **{repo['profile']}/{repo['name']}**: {repo['behind']} behind, {repo['ahead']} ahead\n")

    # Print summary
    print(f"\n{BLUE}=== Scan Complete ==={NC}")
    print(f"Total repositories: {BLUE}{stats['total']}{NC}")
    print(f"Clean: {GREEN}{stats.get('clean', 0)}{NC}")
    print(f"With uncommitted changes: {YELLOW}{stats.get('uncommitted', 0)}{NC}")
    print(f"Behind remote: {RED}{stats.get('behind', 0)}{NC}")
    print(f"Ahead of remote: {BLUE}{stats.get('ahead', 0)}{NC}")
    print(f"Diverged: {RED}{stats.get('diverged', 0)}{NC}")
    print(f"No remote: {YELLOW}{stats.get('no-remote', 0)}{NC}")
    print(f"\nDetailed reports saved to:")
    print(f"  JSON: {BLUE}{json_report_path}{NC}")
    print(f"  Summary: {BLUE}{summary_path}{NC}")

    return all_repos, stats

if __name__ == "__main__":
    main()