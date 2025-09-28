#!/usr/bin/env python3
"""
Backup uncommitted changes from repositories
Generated: 2025-09-26
"""

import os
import json
import shutil
import subprocess
from pathlib import Path
from datetime import datetime

def create_backup(repo_info, backup_root):
    """Create a backup of uncommitted changes for a repository"""
    repo_path = Path(repo_info['path'])
    repo_name = repo_info['name']
    profile = repo_info['profile']

    # Skip if path doesn't exist or is broken symlink
    if not repo_path.exists():
        print(f"    ⚠️  Skipping {profile}/{repo_name} - path doesn't exist")
        return False

    # Resolve symlinks
    if repo_path.is_symlink():
        repo_path = repo_path.resolve()
        if not repo_path.exists():
            print(f"    ⚠️  Skipping {profile}/{repo_name} - broken symlink")
            return False

    print(f"  📦 Backing up {profile}/{repo_name} ({repo_info['uncommitted']} uncommitted)...")

    # Create backup directory
    backup_path = backup_root / profile / repo_name
    backup_path.mkdir(parents=True, exist_ok=True)

    # Save git diff and status
    os.chdir(repo_path)

    # Git diff for uncommitted changes
    diff_file = backup_path / "uncommitted.diff"
    subprocess.run(["git", "diff"], stdout=open(diff_file, 'w'), stderr=subprocess.DEVNULL)

    # Git diff for staged changes
    staged_file = backup_path / "staged.diff"
    subprocess.run(["git", "diff", "--cached"], stdout=open(staged_file, 'w'), stderr=subprocess.DEVNULL)

    # Git status
    status_file = backup_path / "status.txt"
    subprocess.run(["git", "status", "--porcelain"], stdout=open(status_file, 'w'), stderr=subprocess.DEVNULL)

    # Copy untracked files if reasonable number
    if repo_info['untracked'] > 0 and repo_info['untracked'] < 100:
        untracked_dir = backup_path / "untracked_files"
        untracked_dir.mkdir(exist_ok=True)

        # Get list of untracked files
        result = subprocess.run(
            ["git", "ls-files", "--others", "--exclude-standard"],
            capture_output=True, text=True, cwd=repo_path
        )

        if result.returncode == 0:
            for file in result.stdout.strip().split('\n'):
                if file:
                    src = repo_path / file
                    if src.exists() and src.is_file():
                        dst = untracked_dir / file
                        dst.parent.mkdir(parents=True, exist_ok=True)
                        try:
                            shutil.copy2(src, dst)
                        except Exception:
                            pass  # Skip files we can't copy

    return True

def main():
    """Main backup function"""
    print("🔒 Creating backup of repositories with uncommitted changes")

    # Setup paths
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_root = Path.home() / "Backups" / f"repos-{timestamp}"
    backup_root.mkdir(parents=True, exist_ok=True)

    report_dir = Path.home() / "Development" / "personal" / "system-setup-update" / "07-reports"
    scan_report = report_dir / f"repo-scan-{datetime.now().strftime('%Y-%m-%d')}.json"

    if not scan_report.exists():
        print("❌ No scan report found. Please run repo-scanner.py first.")
        return

    # Load scan results
    with open(scan_report) as f:
        repos = json.load(f)

    # Filter repos with uncommitted changes
    repos_to_backup = [r for r in repos if r['uncommitted'] > 0]

    print(f"Found {len(repos_to_backup)} repositories with uncommitted changes")
    print(f"Backup location: {backup_root}\n")

    # Backup each repository
    backed_up = 0
    skipped = 0

    for repo in repos_to_backup:
        # Skip the massive maat-framework repo
        if repo['name'] == 'maat-framework' and repo['uncommitted'] > 1000:
            print(f"  ⚠️  Skipping maat-framework (too many files: {repo['uncommitted']} uncommitted)")
            skipped += 1
            continue

        if create_backup(repo, backup_root):
            backed_up += 1
        else:
            skipped += 1

    # Generate report
    report_file = report_dir / f"backup-report-{datetime.now().strftime('%Y-%m-%d')}.md"
    with open(report_file, 'w') as f:
        f.write(f"# Repository Backup Report\n")
        f.write(f"**Date**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"**Backup Location**: `{backup_root}`\n\n")
        f.write(f"## Summary\n")
        f.write(f"- **Repositories Backed Up**: {backed_up}\n")
        f.write(f"- **Repositories Skipped**: {skipped}\n")
        f.write(f"- **Total Size**: {sum(f.stat().st_size for f in backup_root.rglob('*') if f.is_file()) / 1024 / 1024:.2f} MB\n\n")

        f.write("## Backed Up Repositories\n\n")
        f.write("| Repository | Uncommitted | Untracked |\n")
        f.write("|------------|-------------|----------|\n")

        for repo in repos_to_backup:
            if repo['name'] != 'maat-framework' or repo['uncommitted'] <= 1000:
                f.write(f"| {repo['profile']}/{repo['name']} | {repo['uncommitted']} | {repo['untracked']} |\n")

    print(f"\n✅ Backup complete!")
    print(f"   Backed up: {backed_up} repositories")
    print(f"   Skipped: {skipped} repositories")
    print(f"   Location: {backup_root}")
    print(f"   Report: {report_file}")
    print(f"\n📝 Next: Review changes and decide what to commit/stash")

if __name__ == "__main__":
    main()