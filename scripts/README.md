# Scripts Directory

This directory contains various scripts for managing and auditing GitHub repositories.

## Repository Metadata Checking

### check_repo_metadata.sh (original)
- Checks repositories by scanning local filesystem
- Requires repositories to be cloned locally
- Uses `gh` CLI for API calls

### check_repo_metadata_api.sh
- Uses GitHub API directly without filesystem access
- Lists all public repositories for authenticated user
- Provides suggestions for missing descriptions and topics

### check-repo-metadata.scm
- Guile Scheme implementation of the metadata checker
- Uses GitHub REST API via `gh` CLI
- Provides colored output and actionable suggestions
- Pattern-based topic suggestions

## Usage

```bash
# Bash version (API-based)
./scripts/check_repo_metadata_api.sh

# Guile Scheme version
./scripts/check-repo-metadata.scm
# or
guile scripts/check-repo-metadata.scm
```

## Requirements

- `gh` CLI tool (GitHub CLI)
- Guile (for Scheme version)
- GitHub authentication via `gh auth login`

## GitHub API Endpoints Used

- `GET /user` - Get authenticated user
- `GET /users/{user}/repos` - List user repositories  
- `PATCH /repos/{owner}/{repo}` - Edit repository metadata

## Topic Generation

- `generate_repos-top20.sh` - Generates top 20 repository topics across all repos