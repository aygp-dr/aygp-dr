#!/usr/bin/env python3
"""
Validate API responses against the JSON schema specifications
"""

import json
import sys
from typing import Dict, Any, List


def validate_type(value: Any, schema: Dict[str, Any]) -> tuple[bool, str]:
    """Validate a value against a type schema"""
    if "type" not in schema:
        return True, ""
    
    expected_type = schema["type"]
    
    # Handle nullable types
    if schema.get("nullable", False) and value is None:
        return True, ""
    
    # Type mapping from JSON schema to Python
    type_map = {
        "string": str,
        "integer": int,
        "number": (int, float),
        "boolean": bool,
        "array": list,
        "object": dict
    }
    
    if expected_type not in type_map:
        return False, f"Unknown type: {expected_type}"
    
    expected_python_type = type_map[expected_type]
    
    if not isinstance(value, expected_python_type):
        return False, f"Expected {expected_type}, got {type(value).__name__}"
    
    # Additional validations
    if expected_type == "array" and "items" in schema:
        for i, item in enumerate(value):
            valid, msg = validate_type(item, schema["items"])
            if not valid:
                return False, f"Array item {i}: {msg}"
    
    elif expected_type == "object" and "properties" in schema:
        for prop, prop_schema in schema["properties"].items():
            if prop in value:
                valid, msg = validate_type(value[prop], prop_schema)
                if not valid:
                    return False, f"Property '{prop}': {msg}"
            elif prop_schema.get("required", False):
                return False, f"Missing required property: {prop}"
    
    # Enum validation
    if "enum" in schema and value not in schema["enum"]:
        return False, f"Value must be one of: {schema['enum']}"
    
    return True, ""


def validate_github_response(response: Dict[str, Any], endpoint: str) -> List[str]:
    """Validate a GitHub API response"""
    errors = []
    
    with open("api-specs.json", "r") as f:
        specs = json.load(f)
    
    # Find the endpoint schema
    schema = None
    for api_type in ["rest", "graphql"]:
        if api_type in specs["github"]:
            for ep_name, ep_spec in specs["github"][api_type].items():
                if endpoint in [ep_spec.get("endpoint"), ep_name]:
                    schema = ep_spec.get("response", {}).get("schema")
                    break
    
    if not schema:
        errors.append(f"No schema found for endpoint: {endpoint}")
        return errors
    
    valid, msg = validate_type(response, schema)
    if not valid:
        errors.append(msg)
    
    return errors


def validate_gh_cli_output(output: Any, command: str) -> List[str]:
    """Validate gh CLI command output"""
    errors = []
    
    with open("api-specs.json", "r") as f:
        specs = json.load(f)
    
    # Find the command schema
    schema = None
    for cmd_name, cmd_spec in specs.get("gh_cli", {}).get("commands", {}).items():
        if command == cmd_name or command in cmd_spec.get("command", ""):
            schema = cmd_spec.get("output")
            break
    
    if not schema:
        errors.append(f"No schema found for command: {command}")
        return errors
    
    valid, msg = validate_type(output, schema)
    if not valid:
        errors.append(msg)
    
    return errors


def main():
    """Example usage"""
    # Example: Validate a gh repo list response
    sample_response = [
        {
            "name": "test-repo",
            "description": "A test repository",
            "repositoryTopics": [
                {"name": "python"},
                {"name": "testing"}
            ]
        }
    ]
    
    errors = validate_gh_cli_output(sample_response, "repo_list")
    if errors:
        print("Validation errors:")
        for error in errors:
            print(f"  - {error}")
    else:
        print("✓ Valid response")
    
    # Example: Validate GitHub REST API response
    github_response = {
        "login": "aygp-dr",
        "id": 12345,
        "public_repos": 73
    }
    
    errors = validate_github_response(github_response, "/user")
    if errors:
        print("\nGitHub API validation errors:")
        for error in errors:
            print(f"  - {error}")
    else:
        print("\n✓ Valid GitHub API response")


if __name__ == "__main__":
    main()