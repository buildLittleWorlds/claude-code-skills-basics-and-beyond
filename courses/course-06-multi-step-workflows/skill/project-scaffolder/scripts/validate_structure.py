#!/usr/bin/env python3
"""Validate a scaffolded project structure against a template.

Checks that all expected files and directories exist, files are non-empty
where expected, and reports specific issues for each discrepancy.

Usage:
    python validate_structure.py <project-directory> <template-name>
    python validate_structure.py --help

Exit codes:
    0 - Validation passed (all checks OK)
    1 - Validation failed (errors found)
    2 - Usage error (bad arguments, unknown template)
"""

import json
import os
import sys
from pathlib import Path

# Template definitions: each maps a template name to its expected structure.
# Each entry is a dict with:
#   "path": relative file path
#   "type": "file" or "dir"
#   "required_content": list of strings that must appear in the file (optional)
TEMPLATES = {
    "python-api": [
        {
            "path": "pyproject.toml",
            "type": "file",
            "required_content": ["[project]", "[build-system]"],
        },
        {
            "path": "README.md",
            "type": "file",
            "required_content": ["#"],
        },
        {
            "path": "src",
            "type": "dir",
        },
        {
            "path": "src/__init__.py",
            "type": "file",
            "required_content": [],
        },
        {
            "path": "tests",
            "type": "dir",
        },
        {
            "path": "tests/test_placeholder.py",
            "type": "file",
            "required_content": ["import pytest", "def test_"],
        },
    ],
    "node-api": [
        {
            "path": "package.json",
            "type": "file",
            "required_content": ['"name"', '"scripts"'],
        },
        {
            "path": "README.md",
            "type": "file",
            "required_content": ["#"],
        },
        {
            "path": "src",
            "type": "dir",
        },
        {
            "path": "src/index.ts",
            "type": "file",
            "required_content": [],
        },
        {
            "path": "tests",
            "type": "dir",
        },
        {
            "path": "tests/index.test.ts",
            "type": "file",
            "required_content": ["describe", "it("],
        },
    ],
}


def print_usage():
    """Print usage information."""
    print("Usage: python validate_structure.py <project-directory> <template-name>")
    print()
    print("Arguments:")
    print("  project-directory  Path to the scaffolded project to validate")
    print("  template-name      Template to validate against: python-api, node-api")
    print()
    print("Output: JSON object with validation results")
    print()
    print("Examples:")
    print("  python validate_structure.py ./my-service python-api")
    print("  python validate_structure.py /tmp/my-app node-api")


def validate_project(project_dir: Path, template_name: str) -> dict:
    """Validate a project directory against a template definition.

    Args:
        project_dir: Path to the project directory to validate.
        template_name: Name of the template to validate against.

    Returns:
        dict with keys: valid, project_dir, template, errors, warnings, summary
    """
    errors = []
    warnings = []

    if not project_dir.exists():
        errors.append(f"MISSING: Project directory '{project_dir}' does not exist")
        return {
            "valid": False,
            "project_dir": str(project_dir.resolve()),
            "template": template_name,
            "errors": errors,
            "warnings": warnings,
            "summary": f"{len(errors)} error(s), {len(warnings)} warning(s)",
        }

    if not project_dir.is_dir():
        errors.append(f"NOT_A_DIRECTORY: '{project_dir}' exists but is not a directory")
        return {
            "valid": False,
            "project_dir": str(project_dir.resolve()),
            "template": template_name,
            "errors": errors,
            "warnings": warnings,
            "summary": f"{len(errors)} error(s), {len(warnings)} warning(s)",
        }

    template_spec = TEMPLATES[template_name]

    # Check each expected item
    for item in template_spec:
        item_path = project_dir / item["path"]

        if item["type"] == "dir":
            if not item_path.exists():
                errors.append(f"MISSING: {item['path']}/ directory does not exist")
            elif not item_path.is_dir():
                errors.append(
                    f"NOT_A_DIRECTORY: {item['path']} exists but is not a directory"
                )
        elif item["type"] == "file":
            if not item_path.exists():
                errors.append(f"MISSING: {item['path']}")
            elif not item_path.is_file():
                errors.append(f"NOT_A_FILE: {item['path']} exists but is not a file")
            else:
                # Check file is not empty (if content is expected)
                try:
                    content = item_path.read_text(encoding="utf-8")
                except (OSError, UnicodeDecodeError) as e:
                    errors.append(f"UNREADABLE: {item['path']} -- {e}")
                    continue

                if not content.strip():
                    # Empty files are only an error if required_content is specified
                    if item.get("required_content"):
                        errors.append(
                            f"EMPTY: {item['path']} (expected content but file is empty)"
                        )

                # Check for required content strings
                for required in item.get("required_content", []):
                    if required not in content:
                        errors.append(
                            f"CONTENT: {item['path']} missing expected content: {required}"
                        )

    # Check for extra files (informational only)
    expected_paths = {item["path"] for item in template_spec}
    if project_dir.exists() and project_dir.is_dir():
        for root, dirs, files in os.walk(project_dir):
            # Skip hidden directories
            dirs[:] = [d for d in dirs if not d.startswith(".")]
            rel_root = Path(root).relative_to(project_dir)
            for f in files:
                if f.startswith("."):
                    continue
                rel_path = str(rel_root / f) if str(rel_root) != "." else f
                if rel_path not in expected_paths:
                    warnings.append(f"EXTRA: {rel_path} (not in template, keeping)")

    is_valid = len(errors) == 0
    return {
        "valid": is_valid,
        "project_dir": str(project_dir.resolve()),
        "template": template_name,
        "errors": errors,
        "warnings": warnings,
        "summary": f"{len(errors)} error(s), {len(warnings)} warning(s)",
    }


def main():
    if len(sys.argv) == 2 and sys.argv[1] in ("--help", "-h"):
        print_usage()
        sys.exit(0)

    if len(sys.argv) != 3:
        print("Error: Expected 2 arguments: <project-directory> <template-name>", file=sys.stderr)
        print(file=sys.stderr)
        print_usage()
        sys.exit(2)

    project_dir = Path(sys.argv[1])
    template_name = sys.argv[2]

    if template_name not in TEMPLATES:
        available = ", ".join(sorted(TEMPLATES.keys()))
        print(
            f"Error: Unknown template '{template_name}'. Available: {available}",
            file=sys.stderr,
        )
        sys.exit(2)

    result = validate_project(project_dir, template_name)
    print(json.dumps(result, indent=2))
    sys.exit(0 if result["valid"] else 1)


if __name__ == "__main__":
    main()
