#!/usr/bin/env python3

"""
Documentation Synchronization Engine
Holistic, context-aware documentation updater that understands the complete system configuration
Version: 2.0.0
Last Updated: 2025-09-26
"""

import os
import json
import yaml
import subprocess
import hashlib
import datetime
import re
from pathlib import Path
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, asdict
import difflib

# Configuration paths
REPO_ROOT = Path(__file__).parent.parent.parent
CHEZMOI_SOURCE = Path.home() / ".local" / "share" / "chezmoi"
DOTFILES_SOURCE = Path.home() / "workspace" / "dotfiles"
CONFIG_HOME = Path.home() / ".config"


@dataclass
class SystemContext:
    """Complete system configuration context"""
    timestamp: str
    os_info: Dict[str, str]
    installed_tools: Dict[str, str]
    active_configs: Dict[str, Any]
    chezmoi_state: Dict[str, Any]
    documentation_state: Dict[str, Any]
    discrepancies: List[Dict[str, Any]]


class ConfigurationTracker:
    """Tracks and validates configuration state across the system"""

    def __init__(self):
        self.repo_root = REPO_ROOT
        self.reports_dir = REPO_ROOT / "07-reports" / "status"
        self.templates_dir = REPO_ROOT / "06-templates"
        self.meta_dir = REPO_ROOT / ".meta"
        self.context = None

    def capture_system_context(self) -> SystemContext:
        """Capture complete system context holistically"""
        print("🔍 Capturing holistic system context...")

        context = SystemContext(
            timestamp=datetime.datetime.now().isoformat(),
            os_info=self._get_os_info(),
            installed_tools=self._get_installed_tools(),
            active_configs=self._get_active_configs(),
            chezmoi_state=self._get_chezmoi_state(),
            documentation_state=self._get_documentation_state(),
            discrepancies=[]
        )

        self.context = context
        return context

    def _get_os_info(self) -> Dict[str, str]:
        """Get OS and hardware information"""
        info = {}
        try:
            # macOS specific
            info['os'] = subprocess.check_output(['sw_vers', '-productName'], text=True).strip()
            info['version'] = subprocess.check_output(['sw_vers', '-productVersion'], text=True).strip()
            info['arch'] = subprocess.check_output(['uname', '-m'], text=True).strip()
            info['hostname'] = subprocess.check_output(['hostname'], text=True).strip()

            # Check for specific hardware (M1/M2/M3)
            sysctl = subprocess.check_output(['sysctl', '-n', 'machdep.cpu.brand_string'], text=True).strip()
            if 'Apple M' in sysctl:
                info['processor'] = sysctl
                info['gpu_acceleration'] = 'metal'
        except Exception as e:
            print(f"Warning: Could not get OS info: {e}")

        return info

    def _get_installed_tools(self) -> Dict[str, str]:
        """Get versions of all installed development tools"""
        tools = {}

        # Core tools to check
        tool_commands = {
            'homebrew': ['brew', '--version'],
            'chezmoi': ['chezmoi', 'version'],
            'fish': ['fish', '--version'],
            'mise': ['mise', '--version'],
            'git': ['git', '--version'],
            'node': ['node', '--version'],
            'python': ['python3', '--version'],
            'iterm2': ['defaults', 'read', 'com.googlecode.iterm2', 'CFBundleShortVersionString'],
            'vscode': ['code', '--version'],
            'docker': ['docker', '--version']
        }

        for tool, cmd in tool_commands.items():
            try:
                version = subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL).strip()
                tools[tool] = version.split('\n')[0]  # First line only
            except (subprocess.CalledProcessError, FileNotFoundError):
                tools[tool] = 'not installed'

        return tools

    def _get_active_configs(self) -> Dict[str, Any]:
        """Get active configuration files and their states"""
        configs = {}

        # Check key configuration files
        config_paths = {
            'fish_config': CONFIG_HOME / 'fish' / 'config.fish',
            'iterm2_prefs': CONFIG_HOME / 'iterm2' / 'com.googlecode.iterm2.plist',
            'git_config': Path.home() / '.gitconfig',
            'ssh_config': Path.home() / '.ssh' / 'config',
            'mise_config': CONFIG_HOME / 'mise' / 'config.toml'
        }

        for name, path in config_paths.items():
            if path.exists():
                configs[name] = {
                    'exists': True,
                    'path': str(path),
                    'modified': datetime.datetime.fromtimestamp(path.stat().st_mtime).isoformat(),
                    'size': path.stat().st_size,
                    'checksum': self._calculate_checksum(path)
                }
            else:
                configs[name] = {'exists': False, 'path': str(path)}

        return configs

    def _get_chezmoi_state(self) -> Dict[str, Any]:
        """Get chezmoi management state"""
        state = {'managed': False}

        try:
            # Check if chezmoi is managing files
            managed_files = subprocess.check_output(['chezmoi', 'managed'], text=True).strip().split('\n')
            state['managed'] = True
            state['file_count'] = len(managed_files)

            # Get chezmoi data
            chezmoi_data = subprocess.check_output(['chezmoi', 'data', '--format', 'json'], text=True)
            state['data'] = json.loads(chezmoi_data)

            # Check for uncommitted changes
            status = subprocess.check_output(['chezmoi', 'status'], text=True).strip()
            state['has_changes'] = bool(status)
            state['changes'] = status.split('\n') if status else []

        except (subprocess.CalledProcessError, FileNotFoundError):
            state['error'] = 'chezmoi not configured'

        return state

    def _get_documentation_state(self) -> Dict[str, Any]:
        """Analyze documentation completeness and currency"""
        state = {'documents': {}}

        # Scan all markdown files
        for md_file in self.repo_root.rglob('*.md'):
            rel_path = md_file.relative_to(self.repo_root)

            # Parse frontmatter if exists
            content = md_file.read_text()
            frontmatter = self._parse_frontmatter(content)

            state['documents'][str(rel_path)] = {
                'has_metadata': bool(frontmatter),
                'status': frontmatter.get('status', 'unknown'),
                'last_updated': frontmatter.get('last_updated', 'unknown'),
                'version': frontmatter.get('version', 'unknown')
            }

        # Calculate statistics
        total_docs = len(state['documents'])
        with_metadata = sum(1 for d in state['documents'].values() if d['has_metadata'])
        active_docs = sum(1 for d in state['documents'].values() if d['status'] == 'active')

        state['statistics'] = {
            'total': total_docs,
            'with_metadata': with_metadata,
            'active': active_docs,
            'coverage_percent': (with_metadata / total_docs * 100) if total_docs else 0
        }

        return state

    def _parse_frontmatter(self, content: str) -> Dict[str, Any]:
        """Parse YAML frontmatter from markdown content"""
        if not content.startswith('---'):
            return {}

        try:
            end_marker = content.find('\n---\n', 4)
            if end_marker == -1:
                return {}

            yaml_content = content[4:end_marker]
            return yaml.safe_load(yaml_content) or {}
        except yaml.YAMLError:
            return {}

    def _calculate_checksum(self, filepath: Path) -> str:
        """Calculate SHA256 checksum of a file"""
        sha256_hash = hashlib.sha256()
        with open(filepath, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()[:12]  # First 12 chars for brevity

    def detect_discrepancies(self) -> List[Dict[str, Any]]:
        """Detect discrepancies between documentation and actual configuration"""
        discrepancies = []

        # Check if documented tools match installed tools
        for tool, version in self.context.installed_tools.items():
            if version == 'not installed':
                # Check if documentation claims it should be installed
                setup_doc = self.repo_root / '01-setup' / f'{tool}.md'
                if setup_doc.exists():
                    discrepancies.append({
                        'type': 'missing_tool',
                        'tool': tool,
                        'documented': True,
                        'installed': False,
                        'severity': 'high'
                    })

        # Check chezmoi sync status
        if self.context.chezmoi_state.get('has_changes'):
            discrepancies.append({
                'type': 'chezmoi_changes',
                'changes': self.context.chezmoi_state.get('changes', []),
                'severity': 'medium'
            })

        # Check documentation currency (older than 30 days)
        thirty_days_ago = datetime.datetime.now() - datetime.timedelta(days=30)
        for doc_path, doc_info in self.context.documentation_state['documents'].items():
            if doc_info['status'] == 'active' and doc_info['last_updated'] != 'unknown':
                try:
                    last_updated = datetime.datetime.fromisoformat(doc_info['last_updated'])
                    if last_updated < thirty_days_ago:
                        discrepancies.append({
                            'type': 'stale_documentation',
                            'document': doc_path,
                            'last_updated': doc_info['last_updated'],
                            'severity': 'low'
                        })
                except (ValueError, TypeError):
                    pass

        self.context.discrepancies = discrepancies
        return discrepancies

    def update_documentation(self) -> None:
        """Update documentation to reflect current system state"""
        print("📝 Updating documentation with current state...")

        # Update implementation status
        self._update_implementation_status()

        # Update tool versions in docs
        self._update_tool_versions()

        # Generate new reports
        self._generate_reports()

        # Update metadata
        self._update_metadata()

    def _update_implementation_status(self) -> None:
        """Update the implementation status document"""
        status_file = self.reports_dir / 'implementation-status.md'

        content = f"""# Implementation Status
Generated: {self.context.timestamp}
System: {self.context.os_info.get('os', 'Unknown')} {self.context.os_info.get('version', '')}
Architecture: {self.context.os_info.get('arch', 'Unknown')}

## Phase Completion

"""

        # Define phases and check completion
        phases = {
            '0-prerequisites': self.context.installed_tools.get('homebrew') != 'not installed',
            '1-homebrew': self.context.installed_tools.get('homebrew') != 'not installed',
            '2-chezmoi': self.context.installed_tools.get('chezmoi') != 'not installed',
            '3-fish': self.context.installed_tools.get('fish') != 'not installed',
            '4-mise': self.context.installed_tools.get('mise') != 'not installed',
            '5-security': False,  # TODO: Check security tools
            '6-containers': self.context.installed_tools.get('docker') != 'not installed',
            '7-development': self.context.installed_tools.get('vscode') != 'not installed',
            '8-automation': (self.repo_root / '03-automation' / 'scripts').exists(),
            '9-optimization': self.context.os_info.get('gpu_acceleration') == 'metal'
        }

        for phase, completed in phases.items():
            status = '✅ Complete' if completed else '⏳ Pending'
            content += f"- **Phase {phase}**: {status}\n"

        content += f"""

## Tool Installation Status

| Tool | Version | Status |
|------|---------|--------|
"""

        for tool, version in sorted(self.context.installed_tools.items()):
            status = '✅' if version != 'not installed' else '❌'
            content += f"| {tool.capitalize()} | {version} | {status} |\n"

        content += f"""

## Configuration Files

| Config | Path | Status |
|--------|------|--------|
"""

        for name, info in self.context.active_configs.items():
            status = '✅ Active' if info.get('exists') else '❌ Missing'
            path = info.get('path', 'N/A')
            content += f"| {name} | `{path}` | {status} |\n"

        content += f"""

## Discrepancies Found: {len(self.context.discrepancies)}

"""

        if self.context.discrepancies:
            for disc in self.context.discrepancies:
                content += f"- **{disc['type']}**: {disc.get('severity', 'unknown')} severity\n"
        else:
            content += "No discrepancies detected. System and documentation are in sync.\n"

        status_file.write_text(content)
        print(f"✅ Updated: {status_file}")

    def _update_tool_versions(self) -> None:
        """Update tool version documentation"""
        versions_file = self.reports_dir / 'tool-versions.md'

        content = f"""# Tool Versions
Generated: {self.context.timestamp}

## Development Environment

### Core Tools
"""

        categories = {
            'Package Management': ['homebrew', 'mise'],
            'Version Control': ['git'],
            'Shells': ['fish'],
            'Configuration': ['chezmoi'],
            'Editors': ['vscode'],
            'Containers': ['docker'],
            'Languages': ['node', 'python']
        }

        for category, tools in categories.items():
            content += f"\n#### {category}\n"
            for tool in tools:
                version = self.context.installed_tools.get(tool, 'not installed')
                if version != 'not installed':
                    content += f"- **{tool.capitalize()}**: `{version}`\n"
                else:
                    content += f"- **{tool.capitalize()}**: ❌ Not installed\n"

        versions_file.write_text(content)
        print(f"✅ Updated: {versions_file}")

    def _generate_reports(self) -> None:
        """Generate comprehensive reports"""
        # System context report (JSON)
        context_file = self.reports_dir / 'system-context.json'
        context_file.write_text(json.dumps(asdict(self.context), indent=2, default=str))
        print(f"✅ Generated: {context_file}")

        # Sync summary report (Markdown)
        summary_file = self.reports_dir / 'sync-summary.md'
        summary_content = f"""# System Synchronization Summary
Generated: {self.context.timestamp}

## System Information
- **OS**: {self.context.os_info.get('os')} {self.context.os_info.get('version')}
- **Architecture**: {self.context.os_info.get('arch')}
- **Processor**: {self.context.os_info.get('processor', 'Unknown')}

## Documentation Health
- **Total Documents**: {self.context.documentation_state['statistics']['total']}
- **With Metadata**: {self.context.documentation_state['statistics']['with_metadata']}
- **Active Documents**: {self.context.documentation_state['statistics']['active']}
- **Coverage**: {self.context.documentation_state['statistics']['coverage_percent']:.1f}%

## Configuration Management
- **Chezmoi Managed Files**: {self.context.chezmoi_state.get('file_count', 0)}
- **Pending Changes**: {'Yes' if self.context.chezmoi_state.get('has_changes') else 'No'}

## System Health
- **Discrepancies Found**: {len(self.context.discrepancies)}
- **Critical Issues**: {sum(1 for d in self.context.discrepancies if d.get('severity') == 'high')}

## Next Steps
1. Review discrepancies in [implementation-status.md](implementation-status.md)
2. Update stale documentation
3. Sync chezmoi changes if pending
4. Run validation scripts
"""

        summary_file.write_text(summary_content)
        print(f"✅ Generated: {summary_file}")

    def _update_metadata(self) -> None:
        """Update repository metadata"""
        # Update last sync info
        sync_info = {
            'last_sync': self.context.timestamp,
            'total_documents': self.context.documentation_state['statistics']['total'],
            'discrepancies': len(self.context.discrepancies),
            'system_hash': self._calculate_system_hash()
        }

        sync_file = self.meta_dir / 'sync-info.json'
        sync_file.write_text(json.dumps(sync_info, indent=2))
        print(f"✅ Updated: {sync_file}")

    def _calculate_system_hash(self) -> str:
        """Calculate a hash representing the current system state"""
        state_string = json.dumps({
            'tools': self.context.installed_tools,
            'configs': {k: v.get('checksum') for k, v in self.context.active_configs.items() if v.get('exists')}
        }, sort_keys=True)

        return hashlib.sha256(state_string.encode()).hexdigest()[:16]

    def watch_for_changes(self) -> None:
        """Watch for configuration changes and auto-update documentation"""
        print("👀 Watching for configuration changes...")

        # This would typically use a file watcher like watchdog
        # For now, just check periodically
        import time

        last_hash = self._calculate_system_hash()

        while True:
            time.sleep(60)  # Check every minute

            self.capture_system_context()
            current_hash = self._calculate_system_hash()

            if current_hash != last_hash:
                print(f"🔄 Configuration change detected at {datetime.datetime.now()}")
                self.detect_discrepancies()
                self.update_documentation()
                last_hash = current_hash
            else:
                print(".", end="", flush=True)


def main():
    """Main execution"""
    tracker = ConfigurationTracker()

    # Capture current state
    context = tracker.capture_system_context()

    # Detect discrepancies
    discrepancies = tracker.detect_discrepancies()

    if discrepancies:
        print(f"\n⚠️  Found {len(discrepancies)} discrepancies:")
        for disc in discrepancies:
            print(f"  - {disc['type']}: {disc.get('severity', 'unknown')} severity")
    else:
        print("\n✅ No discrepancies found - documentation and system are in sync!")

    # Update documentation
    tracker.update_documentation()

    print("\n🎉 Documentation synchronization complete!")
    print(f"Reports available in: {tracker.reports_dir}")

    # Optionally start watching for changes
    # tracker.watch_for_changes()


if __name__ == "__main__":
    main()