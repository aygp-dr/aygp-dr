#!/usr/bin/env python3
"""
Contract-based validation for topics display format.
Uses formal specifications to ensure display consistency.
"""

import re
import sys
import json
from pathlib import Path
from typing import List, Tuple, Optional

class TopicsFormatValidator:
    """Validates topics format against formal specifications."""
    
    # Regular expressions derived from EBNF grammar
    TOPIC_NAME_PATTERN = r'[a-z][a-z0-9-]*'
    COUNT_PATTERN = r'[0-9]+'
    
    # Org-mode patterns
    ORG_HEADER_PATTERN = r'^\#\+TITLE: Repository Topics\n\#\+OPTIONS: \^\:\{\} toc:nil$'
    ORG_TOPIC_PATTERN = rf'({TOPIC_NAME_PATTERN})\^\{{({COUNT_PATTERN})\}}'
    
    # HTML/Markdown patterns
    HTML_TOPIC_PATTERN = rf'({TOPIC_NAME_PATTERN})<sup>({COUNT_PATTERN})</sup>'
    
    def __init__(self):
        self.errors: List[str] = []
        self.warnings: List[str] = []
    
    def validate_org_file(self, filepath: Path) -> bool:
        """Validate org-mode topics file format."""
        try:
            content = filepath.read_text()
            lines = content.strip().split('\n')
            
            # Validate header
            if len(lines) < 4:
                self.errors.append(f"Org file too short: expected at least 4 lines, got {len(lines)}")
                return False
            
            header = '\n'.join(lines[:2])
            if not re.match(self.ORG_HEADER_PATTERN, header):
                self.errors.append(f"Invalid org header format")
                return False
            
            # Validate empty line
            if lines[2] != '':
                self.errors.append("Missing empty line after header")
                return False
            
            # Validate topics line
            topics_line = lines[3]
            return self._validate_topics_line(topics_line, 'org')
            
        except Exception as e:
            self.errors.append(f"Error reading org file: {e}")
            return False
    
    def validate_markdown_file(self, filepath: Path) -> bool:
        """Validate markdown/HTML topics file format."""
        try:
            content = filepath.read_text()
            lines = content.strip().split('\n')
            
            if not lines:
                self.errors.append("Markdown file is empty")
                return False
            
            # First line should be topics
            return self._validate_topics_line(lines[0], 'html')
            
        except Exception as e:
            self.errors.append(f"Error reading markdown file: {e}")
            return False
    
    def _validate_topics_line(self, line: str, format_type: str) -> bool:
        """Validate a single line of topics."""
        if format_type == 'org':
            pattern = self.ORG_TOPIC_PATTERN
        else:
            pattern = self.HTML_TOPIC_PATTERN
        
        # Split by separator
        topics = line.split(' · ')
        if not topics:
            self.errors.append("No topics found")
            return False
        
        parsed_topics = []
        for i, topic in enumerate(topics):
            match = re.match(f'^{pattern}$', topic)
            if not match:
                self.errors.append(f"Invalid topic format at position {i+1}: '{topic}'")
                return False
            
            name, count = match.groups()
            parsed_topics.append((name, int(count)))
        
        # Additional validations
        if len(parsed_topics) > 20:
            self.warnings.append(f"Too many topics: {len(parsed_topics)} (expected max 20)")
        
        # Check if counts are decreasing
        counts = [count for _, count in parsed_topics]
        if counts != sorted(counts, reverse=True):
            self.warnings.append("Topic counts are not in descending order")
        
        # Check for duplicates
        names = [name for name, _ in parsed_topics]
        if len(names) != len(set(names)):
            self.errors.append("Duplicate topic names found")
            return False
        
        return len(self.errors) == 0
    
    def validate_consistency(self, org_file: Path, md_file: Path) -> bool:
        """Validate that org and markdown files have consistent content."""
        try:
            # Extract topics from org file
            org_content = org_file.read_text()
            org_topics_match = re.search(rf'^(.+{self.ORG_TOPIC_PATTERN}.+)$', org_content, re.MULTILINE)
            if not org_topics_match:
                self.errors.append("Could not find topics line in org file")
                return False
            
            org_topics = re.findall(self.ORG_TOPIC_PATTERN, org_topics_match.group(1))
            
            # Extract topics from markdown file
            md_content = md_file.read_text()
            md_topics = re.findall(self.HTML_TOPIC_PATTERN, md_content.split('\n')[0])
            
            # Compare
            if len(org_topics) != len(md_topics):
                self.errors.append(f"Topic count mismatch: org has {len(org_topics)}, markdown has {len(md_topics)}")
                return False
            
            for i, ((org_name, org_count), (md_name, md_count)) in enumerate(zip(org_topics, md_topics)):
                if org_name != md_name:
                    self.errors.append(f"Topic name mismatch at position {i+1}: '{org_name}' vs '{md_name}'")
                if org_count != md_count:
                    self.errors.append(f"Topic count mismatch for '{org_name}': {org_count} vs {md_count}")
            
            return len(self.errors) == 0
            
        except Exception as e:
            self.errors.append(f"Error comparing files: {e}")
            return False
    
    def generate_report(self) -> str:
        """Generate validation report."""
        report = []
        if self.errors:
            report.append("ERRORS:")
            for error in self.errors:
                report.append(f"  ✗ {error}")
        else:
            report.append("✓ All validations passed")
        
        if self.warnings:
            report.append("\nWARNINGS:")
            for warning in self.warnings:
                report.append(f"  ⚠ {warning}")
        
        return '\n'.join(report)


def main():
    """Main validation entry point."""
    validator = TopicsFormatValidator()
    
    # Validate individual files
    org_file = Path('topics.org')
    md_file = Path('README.md')
    
    success = True
    
    if org_file.exists():
        if validator.validate_org_file(org_file):
            print("✓ topics.org format is valid")
        else:
            print("✗ topics.org format is invalid")
            success = False
    else:
        print("⚠ topics.org not found")
    
    if md_file.exists():
        if validator.validate_markdown_file(md_file):
            print("✓ README.md format is valid")
        else:
            print("✗ README.md format is invalid")
            success = False
    else:
        print("⚠ README.md not found")
    
    # Validate consistency
    if org_file.exists() and md_file.exists():
        if validator.validate_consistency(org_file, md_file):
            print("✓ Files are consistent")
        else:
            print("✗ Files are inconsistent")
            success = False
    
    # Print detailed report
    print("\n" + validator.generate_report())
    
    return 0 if success else 1


if __name__ == '__main__':
    sys.exit(main())