#!/usr/bin/env python3
"""
Policy as Code Validator for macOS Development Environment
Validates system compliance against policy-as-code.yaml
"""

import os
import sys
import yaml
import subprocess
import json
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Tuple, Any

# Color codes for terminal output
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    PURPLE = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    RESET = '\033[0m'

def load_policy(policy_file: str = "policy-as-code.yaml") -> Dict:
    """Load policy configuration from YAML file"""
    policy_path = Path(__file__).parent / policy_file
    with open(policy_path, 'r') as f:
        return yaml.safe_load(f)

def run_command(cmd: str) -> Tuple[bool, str]:
    """Execute shell command and return success status and output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=5)
        return result.returncode == 0, result.stdout.strip()
    except subprocess.TimeoutExpired:
        return False, "Command timed out"
    except Exception as e:
        return False, str(e)

def expand_path(path: str) -> Path:
    """Expand ~ and environment variables in path"""
    return Path(os.path.expandvars(os.path.expanduser(path)))

def check_version(actual: str, required: str) -> bool:
    """Compare version strings"""
    try:
        actual_parts = [int(x) for x in actual.split('.')[:3]]
        required_parts = [int(x) for x in required.split('.')[:3]]
        return actual_parts >= required_parts
    except:
        return False

class PolicyValidator:
    def __init__(self, policy: Dict):
        self.policy = policy
        self.results = {
            'passed': [],
            'failed': [],
            'warnings': [],
            'score': 0
        }

    def validate_system(self) -> Dict:
        """Run all validation checks"""
        print(f"{Colors.BLUE}╔══════════════════════════════════════════════════════════╗{Colors.RESET}")
        print(f"{Colors.BLUE}║        Policy as Code Validation - System Check          ║{Colors.RESET}")
        print(f"{Colors.BLUE}╚══════════════════════════════════════════════════════════╝{Colors.RESET}\n")

        # Run validation categories
        self.validate_directories()
        self.validate_tools()
        self.validate_languages()
        self.validate_path()
        self.validate_security()
        self.validate_configuration()

        # Calculate compliance score
        total_checks = len(self.results['passed']) + len(self.results['failed'])
        if total_checks > 0:
            self.results['score'] = (len(self.results['passed']) / total_checks) * 100

        return self.results

    def validate_directories(self):
        """Validate required directory structure"""
        print(f"{Colors.CYAN}[Checking Directory Structure]{Colors.RESET}")

        for dir_config in self.policy['directories']['required']:
            path = expand_path(dir_config['path'])
            if path.exists() and path.is_dir():
                self.log_success(f"Directory exists: {dir_config['path']}")
                self.results['passed'].append(f"dir_{path.name}")
            else:
                self.log_failure(f"Directory missing: {dir_config['path']}")
                self.results['failed'].append(f"dir_{path.name}")

    def validate_tools(self):
        """Validate required tools and versions"""
        print(f"\n{Colors.CYAN}[Checking Required Tools]{Colors.RESET}")

        for tool_name, tool_config in self.policy['tools']['required'].items():
            success, output = run_command(tool_config['validation'])

            if success:
                # Extract version from output
                version = self.extract_version(output)
                if version and check_version(version, tool_config['min_version']):
                    self.log_success(f"{tool_name}: {version} (>= {tool_config['min_version']})")
                    self.results['passed'].append(f"tool_{tool_name}")
                else:
                    self.log_warning(f"{tool_name}: Version check failed")
                    self.results['warnings'].append(f"tool_{tool_name}_version")
            else:
                self.log_failure(f"{tool_name}: Not installed")
                self.results['failed'].append(f"tool_{tool_name}")

    def validate_languages(self):
        """Validate programming language installations"""
        print(f"\n{Colors.CYAN}[Checking Language Runtimes]{Colors.RESET}")

        for lang_name, lang_config in self.policy['tools']['languages'].items():
            success, output = run_command(lang_config['validation'])

            if success:
                version = self.extract_version(output)
                if version and 'min_version' in lang_config:
                    if check_version(version, lang_config['min_version']):
                        self.log_success(f"{lang_name}: {version}")
                        self.results['passed'].append(f"lang_{lang_name}")
                    else:
                        self.log_warning(f"{lang_name}: {version} (below required {lang_config['min_version']})")
                        self.results['warnings'].append(f"lang_{lang_name}_version")
                else:
                    self.log_success(f"{lang_name}: Installed")
                    self.results['passed'].append(f"lang_{lang_name}")
            else:
                self.log_failure(f"{lang_name}: Not installed")
                self.results['failed'].append(f"lang_{lang_name}")

    def validate_path(self):
        """Validate PATH entries"""
        print(f"\n{Colors.CYAN}[Checking PATH Configuration]{Colors.RESET}")

        success, path_output = run_command("echo $PATH")
        if success:
            path_entries = path_output.split(':')

            for required_path in self.policy['path']['required_entries']:
                expanded = str(expand_path(required_path))
                if any(expanded in p for p in path_entries):
                    self.log_success(f"PATH contains: {required_path}")
                    self.results['passed'].append(f"path_{required_path.split('/')[-1]}")
                else:
                    self.log_failure(f"PATH missing: {required_path}")
                    self.results['failed'].append(f"path_{required_path.split('/')[-1]}")

    def validate_security(self):
        """Validate security configuration"""
        print(f"\n{Colors.CYAN}[Checking Security Configuration]{Colors.RESET}")

        # Check age key
        age_key_path = expand_path(self.policy['security']['encryption']['key_location'])
        if age_key_path.exists():
            self.log_success("Age key exists")
            self.results['passed'].append("security_age_key")
        else:
            self.log_failure("Age key not found")
            self.results['failed'].append("security_age_key")

        # Check gopass
        success, _ = run_command("gopass version")
        if success:
            self.log_success("gopass installed")
            self.results['passed'].append("security_gopass")
        else:
            self.log_warning("gopass not configured")
            self.results['warnings'].append("security_gopass")

        # Check SSH directory
        ssh_path = expand_path("~/.ssh")
        if ssh_path.exists() and any(ssh_path.glob("id_*")):
            self.log_success("SSH keys present")
            self.results['passed'].append("security_ssh")
        else:
            self.log_warning("SSH keys not found")
            self.results['warnings'].append("security_ssh")

    def validate_configuration(self):
        """Validate configuration files"""
        print(f"\n{Colors.CYAN}[Checking Configuration Files]{Colors.RESET}")

        # Check chezmoi config
        chezmoi_config = expand_path("~/.config/chezmoi/chezmoi.toml")
        if chezmoi_config.exists():
            with open(chezmoi_config, 'r') as f:
                content = f.read()

            for key in self.policy['configuration']['chezmoi']['required_keys']:
                if key in content:
                    self.log_success(f"chezmoi config has key: {key}")
                    self.results['passed'].append(f"config_chezmoi_{key}")
                else:
                    self.log_failure(f"chezmoi config missing key: {key}")
                    self.results['failed'].append(f"config_chezmoi_{key}")

    def extract_version(self, output: str) -> str:
        """Extract version number from command output"""
        import re
        # Common version patterns
        patterns = [
            r'(\d+\.\d+\.\d+)',
            r'version (\d+\.\d+\.\d+)',
            r'v(\d+\.\d+\.\d+)',
        ]

        for pattern in patterns:
            match = re.search(pattern, output)
            if match:
                return match.group(1)
        return ""

    def log_success(self, message: str):
        """Log success message"""
        print(f"{Colors.GREEN}✓{Colors.RESET} {message}")

    def log_failure(self, message: str):
        """Log failure message"""
        print(f"{Colors.RED}✗{Colors.RESET} {message}")

    def log_warning(self, message: str):
        """Log warning message"""
        print(f"{Colors.YELLOW}⚠{Colors.RESET} {message}")

def generate_report(results: Dict):
    """Generate compliance report with docs frontmatter"""
    # Build body
    report = f"""# Policy as Code Compliance Report
## Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

### Overall Compliance Score: {results['score']:.1f}%

### Summary
- **Passed Checks**: {len(results['passed'])}
- **Failed Checks**: {len(results['failed'])}
- **Warnings**: {len(results['warnings'])}

### Grade: {"A" if results['score'] >= 90 else "B" if results['score'] >= 80 else "C" if results['score'] >= 70 else "D" if results['score'] >= 60 else "F"}

### Failed Checks
"""

    for check in results['failed']:
        report += f"- ❌ {check.replace('_', ' ').title()}\n"

    report += "\n### Warnings\n"
    for warning in results['warnings']:
        report += f"- ⚠️ {warning.replace('_', ' ').title()}\n"

    report += "\n### Passed Checks\n"
    for check in results['passed'][:10]:  # Show first 10
        report += f"- ✅ {check.replace('_', ' ').title()}\n"

    if len(results['passed']) > 10:
        report += f"- ... and {len(results['passed']) - 10} more\n"

    # Prepare frontmatter and path within repo
    repo_root = Path(__file__).resolve().parents[2]
    report_path = repo_root / "docs" / "reports" / "compliance-report.md"
    report_path.parent.mkdir(parents=True, exist_ok=True)

    frontmatter = (
        "---\n"
        "title: Policy as Code Compliance Report\n"
        "category: report\n"
        "component: compliance\n"
        "status: active\n"
        "version: 1.0.0\n"
        f"last_updated: {datetime.now().strftime('%Y-%m-%d')}\n"
        "tags: [report, compliance]\n"
        "priority: medium\n"
        "---\n\n"
    )

    with open(report_path, 'w') as f:
        f.write(frontmatter + report)

    print(f"\n{Colors.BLUE}Report saved to: {report_path}{Colors.RESET}")

def main():
    """Main validation entry point"""
    try:
        # Load policy
        policy = load_policy()

        # Create validator
        validator = PolicyValidator(policy)

        # Run validation
        results = validator.validate_system()

        # Print summary
        print(f"\n{Colors.BLUE}╔══════════════════════════════════════════════════════════╗{Colors.RESET}")
        print(f"{Colors.BLUE}║                    Validation Summary                    ║{Colors.RESET}")
        print(f"{Colors.BLUE}╚══════════════════════════════════════════════════════════╝{Colors.RESET}")
        print(f"\nCompliance Score: {Colors.GREEN if results['score'] >= 80 else Colors.YELLOW if results['score'] >= 60 else Colors.RED}{results['score']:.1f}%{Colors.RESET}")
        print(f"Passed: {Colors.GREEN}{len(results['passed'])}{Colors.RESET}")
        print(f"Failed: {Colors.RED}{len(results['failed'])}{Colors.RESET}")
        print(f"Warnings: {Colors.YELLOW}{len(results['warnings'])}{Colors.RESET}")

        # Generate report
        generate_report(results)

        # Exit with appropriate code
        sys.exit(0 if results['score'] >= 80 else 1)

    except Exception as e:
        print(f"{Colors.RED}Error: {e}{Colors.RESET}")
        sys.exit(2)

if __name__ == "__main__":
    main()
