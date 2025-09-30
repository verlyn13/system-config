#!/usr/bin/env python3

"""
Comprehensive System Validation Suite
Validates that the system configuration matches documentation and policies
Version: 2.0.0
"""

import os
import sys
import json
import yaml
import subprocess
import re
from pathlib import Path
from typing import List, Dict, Any, Tuple
from dataclasses import dataclass
from enum import Enum
import hashlib

# Terminal colors
class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    RESET = '\033[0m'
    BOLD = '\033[1m'


class ValidationLevel(Enum):
    CRITICAL = "critical"
    ERROR = "error"
    WARNING = "warning"
    INFO = "info"
    SUCCESS = "success"


@dataclass
class ValidationResult:
    """Result of a single validation check"""
    category: str
    check: str
    level: ValidationLevel
    message: str
    details: Dict[str, Any] = None


class SystemValidator:
    """Comprehensive system validation"""

    def __init__(self):
        self.repo_root = Path(__file__).parent.parent.parent
        self.results: List[ValidationResult] = []
        self.policy_file = self.repo_root / "04-policies" / "policy-as-code.yaml"

    def run_all_validations(self) -> Tuple[bool, List[ValidationResult]]:
        """Run all validation checks"""
        print(f"{Colors.BOLD}{Colors.BLUE}🔍 Running Comprehensive System Validation{Colors.RESET}")
        print("=" * 60)

        # Run validation categories
        self.validate_prerequisites()
        self.validate_homebrew()
        self.validate_chezmoi()
        self.validate_shell()
        self.validate_tools()
        self.validate_configuration_files()
        self.validate_documentation()
        self.validate_security()
        self.validate_performance()
        self.validate_policies()
        self.validate_repo_env()
        self.validate_multirepo_env()

        # Analyze results
        return self.analyze_results()

    def validate_prerequisites(self) -> None:
        """Validate system prerequisites"""
        print(f"\n{Colors.CYAN}📋 Validating Prerequisites...{Colors.RESET}")

        # Check macOS version
        try:
            version = subprocess.check_output(['sw_vers', '-productVersion'], text=True).strip()
            major_version = int(version.split('.')[0])

            if major_version >= 14:
                self.add_result("Prerequisites", "macOS Version", ValidationLevel.SUCCESS,
                               f"macOS {version} meets requirements")
            else:
                self.add_result("Prerequisites", "macOS Version", ValidationLevel.ERROR,
                               f"macOS {version} is below required version 14+")
        except Exception as e:
            self.add_result("Prerequisites", "macOS Version", ValidationLevel.ERROR,
                           f"Could not determine macOS version: {e}")

        # Check architecture
        try:
            arch = subprocess.check_output(['uname', '-m'], text=True).strip()
            if arch in ['arm64', 'x86_64']:
                self.add_result("Prerequisites", "Architecture", ValidationLevel.SUCCESS,
                               f"Architecture {arch} is supported")
            else:
                self.add_result("Prerequisites", "Architecture", ValidationLevel.WARNING,
                               f"Unexpected architecture: {arch}")
        except Exception as e:
            self.add_result("Prerequisites", "Architecture", ValidationLevel.ERROR,
                           f"Could not determine architecture: {e}")

        # Check Xcode Command Line Tools
        try:
            subprocess.run(['xcode-select', '-p'], check=True, capture_output=True)
            self.add_result("Prerequisites", "Xcode CLT", ValidationLevel.SUCCESS,
                           "Xcode Command Line Tools installed")
        except subprocess.CalledProcessError:
            self.add_result("Prerequisites", "Xcode CLT", ValidationLevel.CRITICAL,
                           "Xcode Command Line Tools not installed")

    def validate_homebrew(self) -> None:
        """Validate Homebrew installation and packages"""
        print(f"\n{Colors.CYAN}🍺 Validating Homebrew...{Colors.RESET}")

        # Check Homebrew installation
        try:
            brew_version = subprocess.check_output(['brew', '--version'], text=True).strip().split('\n')[0]
            self.add_result("Homebrew", "Installation", ValidationLevel.SUCCESS,
                           brew_version)

            # Check for outdated packages
            outdated = subprocess.check_output(['brew', 'outdated'], text=True).strip()
            if outdated:
                packages = len(outdated.split('\n'))
                self.add_result("Homebrew", "Outdated Packages", ValidationLevel.WARNING,
                               f"{packages} packages need updating",
                               {"packages": outdated.split('\n')})
            else:
                self.add_result("Homebrew", "Packages", ValidationLevel.SUCCESS,
                               "All packages are up to date")

            # Check Homebrew health
            subprocess.run(['brew', 'doctor'], check=True, capture_output=True)
            self.add_result("Homebrew", "Health Check", ValidationLevel.SUCCESS,
                           "Homebrew is healthy")

        except subprocess.CalledProcessError as e:
            if 'brew doctor' in str(e.cmd):
                self.add_result("Homebrew", "Health Check", ValidationLevel.WARNING,
                               "Homebrew has minor issues (run 'brew doctor')")
            else:
                self.add_result("Homebrew", "Installation", ValidationLevel.CRITICAL,
                               "Homebrew not installed or not in PATH")
        except FileNotFoundError:
            self.add_result("Homebrew", "Installation", ValidationLevel.CRITICAL,
                           "Homebrew not installed")

    def validate_chezmoi(self) -> None:
        """Validate Chezmoi configuration"""
        print(f"\n{Colors.CYAN}🏠 Validating Chezmoi...{Colors.RESET}")

        try:
            # Check installation
            version = subprocess.check_output(['chezmoi', '--version'], text=True).strip()
            self.add_result("Chezmoi", "Installation", ValidationLevel.SUCCESS, version)

            # Check for uncommitted changes
            status = subprocess.check_output(['chezmoi', 'status'], text=True).strip()
            if status:
                changes = len(status.split('\n'))
                self.add_result("Chezmoi", "Uncommitted Changes", ValidationLevel.WARNING,
                               f"{changes} files have uncommitted changes",
                               {"files": status.split('\n')})
            else:
                self.add_result("Chezmoi", "Status", ValidationLevel.SUCCESS,
                               "All files are in sync")

            # Check managed files count
            managed = subprocess.check_output(['chezmoi', 'managed'], text=True).strip().split('\n')
            self.add_result("Chezmoi", "Managed Files", ValidationLevel.INFO,
                           f"Managing {len(managed)} files")

        except (subprocess.CalledProcessError, FileNotFoundError):
            self.add_result("Chezmoi", "Installation", ValidationLevel.ERROR,
                           "Chezmoi not installed or not configured")

    def validate_shell(self) -> None:
        """Validate shell configuration"""
        print(f"\n{Colors.CYAN}🐚 Validating Shell...{Colors.RESET}")

        # Check current shell
        current_shell = os.environ.get('SHELL', '')

        if 'fish' in current_shell:
            self.add_result("Shell", "Current Shell", ValidationLevel.SUCCESS,
                           "Fish shell is active")

            # Validate Fish configuration
            fish_config = Path.home() / '.config' / 'fish' / 'config.fish'
            if fish_config.exists():
                self.add_result("Shell", "Fish Config", ValidationLevel.SUCCESS,
                               "Fish configuration exists")
            else:
                self.add_result("Shell", "Fish Config", ValidationLevel.WARNING,
                               "Fish configuration not found")

            # Check Fish plugins/functions
            try:
                functions = subprocess.check_output(['fish', '-c', 'functions'], text=True)
                if 'mise' in functions:
                    self.add_result("Shell", "Mise Integration", ValidationLevel.SUCCESS,
                                   "Mise is integrated with Fish")
                if 'direnv' in functions:
                    self.add_result("Shell", "Direnv Integration", ValidationLevel.SUCCESS,
                                   "Direnv is integrated with Fish")
            except subprocess.CalledProcessError:
                pass

        elif 'zsh' in current_shell:
            self.add_result("Shell", "Current Shell", ValidationLevel.INFO,
                           "Using Zsh (Fish recommended)")
        else:
            self.add_result("Shell", "Current Shell", ValidationLevel.WARNING,
                           f"Unexpected shell: {current_shell}")

    def validate_tools(self) -> None:
        """Validate development tools"""
        print(f"\n{Colors.CYAN}🔧 Validating Development Tools...{Colors.RESET}")

        required_tools = {
            'git': {'min_version': '2.0', 'critical': True},
            'mise': {'min_version': None, 'critical': False},
            'node': {'min_version': '18.0', 'critical': False},
            'python3': {'min_version': '3.9', 'critical': False},
            'code': {'min_version': None, 'critical': False},
            'docker': {'min_version': None, 'critical': False},
        }

        for tool, requirements in required_tools.items():
            try:
                # Get version
                if tool == 'python3':
                    version_cmd = ['python3', '--version']
                else:
                    version_cmd = [tool, '--version']

                version_output = subprocess.check_output(version_cmd, text=True, stderr=subprocess.STDOUT).strip()

                # Extract version number
                version_match = re.search(r'(\d+\.\d+(?:\.\d+)?)', version_output)
                if version_match:
                    version = version_match.group(1)

                    if requirements['min_version'] and self.compare_versions(version, requirements['min_version']) < 0:
                        level = ValidationLevel.ERROR if requirements['critical'] else ValidationLevel.WARNING
                        self.add_result("Tools", tool.capitalize(), level,
                                       f"Version {version} is below minimum {requirements['min_version']}")
                    else:
                        self.add_result("Tools", tool.capitalize(), ValidationLevel.SUCCESS,
                                       f"Version {version}")
                else:
                    self.add_result("Tools", tool.capitalize(), ValidationLevel.INFO,
                                   "Installed (version unknown)")

            except (subprocess.CalledProcessError, FileNotFoundError):
                level = ValidationLevel.ERROR if requirements['critical'] else ValidationLevel.WARNING
                self.add_result("Tools", tool.capitalize(), level, "Not installed")

    def validate_configuration_files(self) -> None:
        """Validate configuration files"""
        print(f"\n{Colors.CYAN}📄 Validating Configuration Files...{Colors.RESET}")

        config_files = {
            '~/.gitconfig': 'Git configuration',
            '~/.ssh/config': 'SSH configuration',
            '~/.config/fish/config.fish': 'Fish configuration',
            '~/.config/iterm2/com.googlecode.iterm2.plist': 'iTerm2 preferences',
            '~/.config/mise/config.toml': 'Mise configuration',
        }

        for path, description in config_files.items():
            file_path = Path(path).expanduser()
            if file_path.exists():
                # Check file permissions for sensitive files
                if 'ssh' in path:
                    stat_info = file_path.stat()
                    mode = oct(stat_info.st_mode)[-3:]
                    if mode == '600' or mode == '644':
                        self.add_result("Config Files", description, ValidationLevel.SUCCESS,
                                       f"Exists with correct permissions ({mode})")
                    else:
                        self.add_result("Config Files", description, ValidationLevel.WARNING,
                                       f"Exists but has loose permissions ({mode})")
                else:
                    self.add_result("Config Files", description, ValidationLevel.SUCCESS, "Exists")
            else:
                level = ValidationLevel.WARNING if 'mise' in path else ValidationLevel.INFO
                self.add_result("Config Files", description, level, "Not found")

    def validate_documentation(self) -> None:
        """Validate documentation completeness"""
        print(f"\n{Colors.CYAN}📚 Validating Documentation...{Colors.RESET}")

        # Count documentation files
        md_files = list(self.repo_root.rglob('*.md'))
        with_metadata = 0
        active_docs = 0
        stale_docs = 0

        for md_file in md_files:
            content = md_file.read_text()
            if content.startswith('---'):
                with_metadata += 1
                # Parse frontmatter
                if 'status: active' in content:
                    active_docs += 1
                if 'last_updated: ' in content:
                    # Check for stale docs (simplified check)
                    pass

        coverage = (with_metadata / len(md_files) * 100) if md_files else 0

        self.add_result("Documentation", "Coverage", ValidationLevel.SUCCESS if coverage == 100 else ValidationLevel.INFO,
                       f"{coverage:.1f}% of documents have metadata ({with_metadata}/{len(md_files)})")

        self.add_result("Documentation", "Active Docs", ValidationLevel.INFO,
                       f"{active_docs} documents are marked as active")

    def validate_security(self) -> None:
        """Validate security settings"""
        print(f"\n{Colors.CYAN}🔐 Validating Security...{Colors.RESET}")

        # Check SSH key permissions
        ssh_dir = Path.home() / '.ssh'
        if ssh_dir.exists():
            for key_file in ssh_dir.glob('id_*'):
                if not key_file.name.endswith('.pub'):
                    mode = oct(key_file.stat().st_mode)[-3:]
                    if mode == '600':
                        self.add_result("Security", f"SSH Key {key_file.name}", ValidationLevel.SUCCESS,
                                       "Correct permissions (600)")
                    else:
                        self.add_result("Security", f"SSH Key {key_file.name}", ValidationLevel.CRITICAL,
                                       f"Insecure permissions ({mode})")

        # Check for .env files in Development directories
        dev_dir = Path.home() / 'Development'
        if dev_dir.exists():
            env_files = list(dev_dir.rglob('.env'))
            if env_files:
                self.add_result("Security", ".env Files", ValidationLevel.WARNING,
                               f"Found {len(env_files)} .env files in Development")

        # Check Git credential helper
        try:
            credential_helper = subprocess.check_output(
                ['git', 'config', '--global', 'credential.helper'], text=True
            ).strip()
            if credential_helper:
                self.add_result("Security", "Git Credentials", ValidationLevel.SUCCESS,
                               f"Using credential helper: {credential_helper}")
            else:
                self.add_result("Security", "Git Credentials", ValidationLevel.WARNING,
                               "No credential helper configured")
        except subprocess.CalledProcessError:
            pass

    def validate_performance(self) -> None:
        """Validate performance optimizations"""
        print(f"\n{Colors.CYAN}⚡ Validating Performance...{Colors.RESET}")

        # Check if development directories are excluded from Spotlight
        try:
            mdutil_output = subprocess.check_output(
                ['mdutil', '-s', str(Path.home() / 'Development')],
                text=True, stderr=subprocess.DEVNULL
            )
            if 'disabled' in mdutil_output.lower():
                self.add_result("Performance", "Spotlight Exclusion", ValidationLevel.SUCCESS,
                               "Development directory excluded from Spotlight")
            else:
                self.add_result("Performance", "Spotlight Exclusion", ValidationLevel.INFO,
                               "Development directory not excluded from Spotlight")
        except subprocess.CalledProcessError:
            pass

        # Check shell startup time (for Fish)
        if 'fish' in os.environ.get('SHELL', ''):
            try:
                import time
                start = time.time()
                subprocess.run(['fish', '-c', 'exit'], check=True)
                startup_time = (time.time() - start) * 1000

                if startup_time < 150:
                    self.add_result("Performance", "Shell Startup", ValidationLevel.SUCCESS,
                                   f"Fish startup time: {startup_time:.0f}ms")
                else:
                    self.add_result("Performance", "Shell Startup", ValidationLevel.WARNING,
                                   f"Slow Fish startup: {startup_time:.0f}ms (target < 150ms)")
            except subprocess.CalledProcessError:
                pass

    def validate_policies(self) -> None:
        """Validate against defined policies"""
        print(f"\n{Colors.CYAN}📋 Validating Policies...{Colors.RESET}")

        if not self.policy_file.exists():
            self.add_result("Policies", "Policy File", ValidationLevel.WARNING,
                           "policy-as-code.yaml not found")
            return

        try:
            with open(self.policy_file) as f:
                policies = yaml.safe_load(f)

            # Validate each policy category
            for category, rules in policies.items():
                if isinstance(rules, dict):
                    for rule_name, rule_config in rules.items():
                        # This is a simplified policy check
                        # In reality, you'd implement specific checks for each policy
                        pass

            self.add_result("Policies", "Compliance", ValidationLevel.INFO,
                           "Policy validation framework is active")

        except Exception as e:
            self.add_result("Policies", "Policy File", ValidationLevel.ERROR,
                           f"Could not parse policy file: {e}")

    def validate_repo_env(self) -> None:
        """Validate repo-local env (.envrc) and mise trust status"""
        print(f"\n{Colors.CYAN}🧪 Validating Repo Env (.envrc/mise trust)...{Colors.RESET}")
        repo_envrc = self.repo_root / '.envrc'
        if not repo_envrc.exists():
            self.add_result("Repo Env", ".envrc", ValidationLevel.ERROR, ".envrc not found in repo root")
        else:
            try:
                content = repo_envrc.read_text()
                has_use_mise_fn = 'use_mise()' in content and 'direnv_load mise direnv exec' in content
                uses_use_mise = 'use mise' in content
                eval_mise = '$(mise direnv)' in content
                if has_use_mise_fn and uses_use_mise and not eval_mise:
                    self.add_result("Repo Env", ".envrc Structure", ValidationLevel.SUCCESS,
                                    "uses embedded use_mise() and avoids external eval")
                else:
                    msg = []
                    if not has_use_mise_fn: msg.append('missing use_mise()')
                    if not uses_use_mise: msg.append('missing "use mise"')
                    if eval_mise: msg.append('contains eval "$(mise direnv)"')
                    self.add_result("Repo Env", ".envrc Structure", ValidationLevel.WARNING,
                                    ", ".join(msg) or "non-standard structure")
            except Exception as e:
                self.add_result("Repo Env", ".envrc Read", ValidationLevel.ERROR, f"failed to read: {e}")

        # Check mise trust status for this repo
        try:
            out = subprocess.check_output(['bash', '-lc', 'mise trust --show'], text=True, cwd=self.repo_root)
            trusted = any('.mise.toml' in line and ('trusted' in line or 'mise trusted' in line) for line in out.splitlines())
            if trusted:
                self.add_result("Repo Env", "mise trust", ValidationLevel.SUCCESS, ".mise.toml trusted")
            else:
                self.add_result("Repo Env", "mise trust", ValidationLevel.WARNING, ".mise.toml not trusted")
        except Exception as e:
            self.add_result("Repo Env", "mise trust", ValidationLevel.INFO, f"unable to check trust: {e}")

    def validate_multirepo_env(self) -> None:
        """Validate .envrc structure and mise trust across discovered repositories"""
        print(f"\n{Colors.CYAN}🧪 Validating Multi‑Repo Env (.envrc/mise trust)...{Colors.RESET}")
        # Load registry written by observers/bridge if present
        registry = Path.home() / '.local' / 'share' / 'devops-mcp' / 'project-registry.json'
        if not registry.exists():
            self.add_result("Multi-Repo Env", "Registry", ValidationLevel.INFO, "Registry not found; skipping multi-repo checks")
            return
        try:
            data = json.loads(registry.read_text())
            projects = data.get('projects', [])
        except Exception as e:
            self.add_result("Multi-Repo Env", "Registry Parse", ValidationLevel.ERROR, f"Failed to parse registry: {e}")
            return

        checked = 0
        ok_envrc = 0
        ok_trust = 0
        for p in projects:
            repo_path = Path(p.get('path', ''))
            if not repo_path or not repo_path.exists():
                continue
            checked += 1
            # .envrc check
            try:
                envrc = repo_path / '.envrc'
                if envrc.exists():
                    content = envrc.read_text(errors='ignore')
                    if ('use_mise()' in content and 'direnv_load mise direnv exec' in content and 'use mise' in content and '$(mise direnv)' not in content):
                        ok_envrc += 1
                # mise trust check (only if .mise.toml exists)
                if (repo_path / '.mise.toml').exists():
                    out = subprocess.check_output(['bash', '-lc', 'mise trust --show'], text=True, cwd=str(repo_path))
                    if '.mise.toml' in out and 'trusted' in out:
                        ok_trust += 1
            except Exception:
                pass

        self.add_result(
            "Multi-Repo Env",
            ".envrc Compliance",
            ValidationLevel.SUCCESS if ok_envrc == checked or checked == 0 else ValidationLevel.WARNING,
            f"{ok_envrc}/{checked} repos have robust .envrc"
        )
        self.add_result(
            "Multi-Repo Env",
            "mise trust",
            ValidationLevel.SUCCESS if ok_trust > 0 else ValidationLevel.INFO,
            f"{ok_trust}/{checked} repos with .mise.toml are trusted"
        )

    def add_result(self, category: str, check: str, level: ValidationLevel,
                   message: str, details: Dict[str, Any] = None) -> None:
        """Add a validation result"""
        result = ValidationResult(category, check, level, message, details)
        self.results.append(result)

        # Print result immediately
        icon = self.get_icon(level)
        color = self.get_color(level)
        print(f"  {color}{icon} {check}: {message}{Colors.RESET}")

    def get_icon(self, level: ValidationLevel) -> str:
        """Get icon for validation level"""
        icons = {
            ValidationLevel.CRITICAL: "❌",
            ValidationLevel.ERROR: "❌",
            ValidationLevel.WARNING: "⚠️ ",
            ValidationLevel.INFO: "ℹ️ ",
            ValidationLevel.SUCCESS: "✅"
        }
        return icons.get(level, "•")

    def get_color(self, level: ValidationLevel) -> str:
        """Get color for validation level"""
        colors = {
            ValidationLevel.CRITICAL: Colors.RED + Colors.BOLD,
            ValidationLevel.ERROR: Colors.RED,
            ValidationLevel.WARNING: Colors.YELLOW,
            ValidationLevel.INFO: Colors.BLUE,
            ValidationLevel.SUCCESS: Colors.GREEN
        }
        return colors.get(level, Colors.WHITE)

    def compare_versions(self, version1: str, version2: str) -> int:
        """Compare two version strings"""
        v1_parts = [int(x) for x in version1.split('.')]
        v2_parts = [int(x) for x in version2.split('.')]

        # Pad with zeros if needed
        while len(v1_parts) < len(v2_parts):
            v1_parts.append(0)
        while len(v2_parts) < len(v1_parts):
            v2_parts.append(0)

        for i in range(len(v1_parts)):
            if v1_parts[i] > v2_parts[i]:
                return 1
            elif v1_parts[i] < v2_parts[i]:
                return -1
        return 0

    def analyze_results(self) -> Tuple[bool, List[ValidationResult]]:
        """Analyze validation results and determine overall status"""
        print(f"\n{Colors.BOLD}{Colors.BLUE}📊 Validation Summary{Colors.RESET}")
        print("=" * 60)

        # Count by level
        counts = {level: 0 for level in ValidationLevel}
        for result in self.results:
            counts[result.level] += 1

        # Print summary
        print(f"{Colors.GREEN}✅ Success: {counts[ValidationLevel.SUCCESS]}{Colors.RESET}")
        print(f"{Colors.BLUE}ℹ️  Info: {counts[ValidationLevel.INFO]}{Colors.RESET}")
        print(f"{Colors.YELLOW}⚠️  Warnings: {counts[ValidationLevel.WARNING]}{Colors.RESET}")
        print(f"{Colors.RED}❌ Errors: {counts[ValidationLevel.ERROR]}{Colors.RESET}")
        print(f"{Colors.RED}{Colors.BOLD}❌ Critical: {counts[ValidationLevel.CRITICAL]}{Colors.RESET}")

        # Determine overall status
        if counts[ValidationLevel.CRITICAL] > 0:
            print(f"\n{Colors.RED}{Colors.BOLD}❌ VALIDATION FAILED: Critical issues found{Colors.RESET}")
            success = False
        elif counts[ValidationLevel.ERROR] > 0:
            print(f"\n{Colors.RED}❌ VALIDATION FAILED: Errors found{Colors.RESET}")
            success = False
        elif counts[ValidationLevel.WARNING] > 0:
            print(f"\n{Colors.YELLOW}⚠️  VALIDATION PASSED WITH WARNINGS{Colors.RESET}")
            success = True
        else:
            print(f"\n{Colors.GREEN}{Colors.BOLD}✅ VALIDATION PASSED{Colors.RESET}")
            success = True

        # Save results to file
        self.save_results()

        return success, self.results

    def save_results(self) -> None:
        """Save validation results to a file"""
        results_file = self.repo_root / '07-reports' / 'status' / 'validation-results.json'

        results_data = {
            'timestamp': str(Path.cwd()),
            'results': [
                {
                    'category': r.category,
                    'check': r.check,
                    'level': r.level.value,
                    'message': r.message,
                    'details': r.details
                }
                for r in self.results
            ]
        }

        results_file.parent.mkdir(parents=True, exist_ok=True)
        results_file.write_text(json.dumps(results_data, indent=2))
        print(f"\n💾 Results saved to: {results_file.relative_to(self.repo_root)}")


def main():
    """Main execution"""
    validator = SystemValidator()
    success, results = validator.run_all_validations()

    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
