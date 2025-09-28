#!/usr/bin/env python3

"""
Add frontmatter metadata to all documentation files
Version: 1.0.0
"""

import os
from pathlib import Path
from datetime import datetime
import re

REPO_ROOT = Path(__file__).parent.parent.parent

# Document metadata mappings
DOCUMENT_METADATA = {
    "README.md": {
        "title": "System Setup Documentation",
        "category": "reference",
        "component": "overview",
        "status": "active",
        "version": "2.0.0",
        "priority": "critical"
    },
    "INDEX.md": {
        "title": "Documentation Index",
        "category": "reference",
        "component": "navigation",
        "status": "active",
        "version": "2.0.0",
        "priority": "critical"
    },
    "REPO-STRUCTURE.md": {
        "title": "Repository Structure",
        "category": "reference",
        "component": "organization",
        "status": "active",
        "version": "2.0.0",
        "priority": "high"
    },
    "DOCUMENTATION-SYNC-ARCHITECTURE.md": {
        "title": "Documentation Sync Architecture",
        "category": "automation",
        "component": "sync-engine",
        "status": "active",
        "version": "2.0.0",
        "priority": "high"
    },
    "CLAUDE.md": {
        "title": "AI Assistant Context",
        "category": "reference",
        "component": "ai-context",
        "status": "active",
        "version": "1.0.0",
        "priority": "medium"
    },
    "01-setup/00-prerequisites.md": {
        "title": "macOS Development Environment Setup",
        "category": "setup",
        "component": "prerequisites",
        "status": "active",
        "version": "3.0.0",
        "priority": "critical",
        "dependencies": []
    },
    "02-configuration/terminals/iterm2-config.md": {
        "title": "iTerm2 Complete Configuration Guide",
        "category": "configuration",
        "component": "iterm2",
        "status": "active",
        "version": "2.0.0",
        "priority": "high",
        "dependencies": [
            {"doc": "01-setup/01-homebrew.md", "type": "required"},
            {"doc": "01-setup/02-chezmoi.md", "type": "required"}
        ]
    },
    "02-configuration/terminals/ITERM2-SETUP-STATUS.md": {
        "title": "iTerm2 Setup Status Report",
        "category": "report",
        "component": "iterm2",
        "status": "active",
        "version": "1.0.0",
        "priority": "medium"
    },
    "02-configuration/terminals/ITERM2-CHEZMOI-INTEGRATION.md": {
        "title": "iTerm2 Chezmoi Integration",
        "category": "configuration",
        "component": "iterm2",
        "status": "active",
        "version": "1.0.0",
        "priority": "medium"
    },
    "02-configuration/tools/ssh-multi-account.md": {
        "title": "SSH Multi-Account Configuration",
        "category": "configuration",
        "component": "ssh",
        "status": "active",
        "version": "1.0.0",
        "priority": "high"
    },
    "04-policies/version-policy.md": {
        "title": "Version Management Policy",
        "category": "policy",
        "component": "versions",
        "status": "active",
        "version": "1.0.0",
        "priority": "medium"
    },
    "06-templates/chezmoi/README.md": {
        "title": "Chezmoi Templates Documentation",
        "category": "template",
        "component": "chezmoi",
        "status": "active",
        "version": "1.0.0",
        "priority": "medium"
    },
    "07-reports/status/implementation-status.md": {
        "title": "Implementation Status Report",
        "category": "report",
        "component": "status",
        "status": "active",
        "version": "auto",
        "priority": "high",
        "auto_generated": True
    },
    "07-reports/status/tool-versions.md": {
        "title": "Tool Versions Report",
        "category": "report",
        "component": "versions",
        "status": "active",
        "version": "auto",
        "priority": "medium",
        "auto_generated": True
    },
    "07-reports/status/sync-summary.md": {
        "title": "System Synchronization Summary",
        "category": "report",
        "component": "sync",
        "status": "active",
        "version": "auto",
        "priority": "medium",
        "auto_generated": True
    },
    "SECRETS-MANAGEMENT-GUIDE.md": {
        "title": "Secrets Management Guide",
        "category": "reference",
        "component": "security",
        "status": "active",
        "version": "1.0.0",
        "priority": "critical"
    }
}

def add_frontmatter(file_path: Path, metadata: dict) -> None:
    """Add or update frontmatter in a markdown file"""

    # Read current content
    content = file_path.read_text()

    # Check if frontmatter already exists
    if content.startswith('---\n'):
        # Find end of frontmatter
        end_marker = content.find('\n---\n', 4)
        if end_marker != -1:
            # Remove existing frontmatter
            content = content[end_marker + 5:]

    # Build frontmatter
    frontmatter = "---\n"
    frontmatter += f"title: {metadata.get('title', 'Untitled')}\n"
    frontmatter += f"category: {metadata.get('category', 'reference')}\n"
    frontmatter += f"component: {metadata.get('component', 'general')}\n"
    frontmatter += f"status: {metadata.get('status', 'draft')}\n"
    frontmatter += f"version: {metadata.get('version', '1.0.0')}\n"
    frontmatter += f"last_updated: {datetime.now().strftime('%Y-%m-%d')}\n"

    # Add dependencies if present
    if 'dependencies' in metadata:
        frontmatter += "dependencies:\n"
        for dep in metadata['dependencies']:
            frontmatter += f"  - doc: {dep['doc']}\n"
            frontmatter += f"    type: {dep['type']}\n"

    # Add tags based on category and component
    tags = []
    if metadata.get('category') == 'setup':
        tags.extend(['installation', 'setup'])
    elif metadata.get('category') == 'configuration':
        tags.extend(['configuration', 'settings'])
    elif metadata.get('category') == 'policy':
        tags.extend(['policy', 'compliance'])
    elif metadata.get('category') == 'report':
        tags.extend(['report', 'status'])

    # Add component-specific tags
    component = metadata.get('component', '')
    if component == 'iterm2':
        tags.extend(['terminal', 'macos'])
    elif component == 'ssh':
        tags.extend(['security', 'remote-access'])
    elif component == 'chezmoi':
        tags.extend(['dotfiles', 'configuration-management'])

    frontmatter += f"tags: [{', '.join(tags)}]\n"

    # Add applies_to for setup/config docs
    if metadata.get('category') in ['setup', 'configuration']:
        frontmatter += "applies_to:\n"
        frontmatter += "  - os: macos\n"
        frontmatter += "    versions: [\"14.0+\", \"15.0+\"]\n"
        frontmatter += "  - arch: [\"arm64\", \"x86_64\"]\n"

    frontmatter += f"priority: {metadata.get('priority', 'medium')}\n"

    if metadata.get('auto_generated'):
        frontmatter += "auto_generated: true\n"

    frontmatter += "---\n\n"

    # Write updated content
    file_path.write_text(frontmatter + content)
    print(f"✅ Added frontmatter to {file_path.relative_to(REPO_ROOT)}")


def main():
    print("📝 Adding frontmatter to documentation files...")

    processed = 0
    skipped = 0

    for doc_path, metadata in DOCUMENT_METADATA.items():
        file_path = REPO_ROOT / doc_path

        if file_path.exists():
            add_frontmatter(file_path, metadata)
            processed += 1
        else:
            print(f"⚠️  File not found: {doc_path}")
            skipped += 1

    # Handle remaining files not in the mapping
    for md_file in REPO_ROOT.rglob('*.md'):
        rel_path = str(md_file.relative_to(REPO_ROOT))

        if rel_path not in DOCUMENT_METADATA:
            # Generate default metadata based on location
            if '01-setup' in rel_path:
                category = 'setup'
            elif '02-configuration' in rel_path:
                category = 'configuration'
            elif '03-automation' in rel_path:
                category = 'automation'
            elif '04-policies' in rel_path:
                category = 'policy'
            elif '05-reference' in rel_path:
                category = 'reference'
            elif '06-templates' in rel_path:
                category = 'template'
            elif '07-reports' in rel_path:
                category = 'report'
            else:
                category = 'reference'

            # Extract component from filename
            component = md_file.stem.lower().replace('-', '_')

            metadata = {
                'title': md_file.stem.replace('-', ' ').title(),
                'category': category,
                'component': component,
                'status': 'draft',
                'version': '1.0.0',
                'priority': 'medium'
            }

            add_frontmatter(md_file, metadata)
            processed += 1

    print(f"\n✨ Complete! Processed {processed} files, skipped {skipped}")


if __name__ == "__main__":
    main()