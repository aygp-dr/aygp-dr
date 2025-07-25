# Post-Compact Resurrection Notes

## Conventional Commit Rules

Based on the project's commit history and CLAUDE.md guidelines:

### Format
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types Used
- **feat**: New features or functionality
- **fix**: Bug fixes
- **docs**: Documentation changes
- **refactor**: Code restructuring without functional changes
- **test**: Adding or modifying tests
- **ci**: CI/CD configuration changes
- **build**: Build system changes

### Rules
1. **No "generated with" messages** in commit body or message
2. **Use --trailer for co-author attribution** (e.g., `Co-authored-by: Name <email>`)
3. **Skip CI notation**: Use `[skip ci]` in commit message when appropriate
4. **Concise descriptions**: Keep subject line under 50 characters
5. **Present tense**: Use imperative mood ("add" not "added")

### Examples from Project
- `feat: complete experiment 01-ollama-structured-output`
- `fix: resolve GitHub Actions permissions issue`
- `docs: update README with latest topics [skip ci]`
- `ci: update cron schedule to run hourly for testing`
- `refactor: simplify to only use authenticated GitHub user`

## Context Summary

### Grammar and Spelling Corrections
- Fixed "fepose" → "repos" in user messages
- Corrected "cnovert" → "convert"
- Fixed "ooperation" → "operation"
- Corrected "geernate_repoose_top20.sh" → "generate_repos_top20.sh"

### Issues Addressed
1. **Token Scoping**: Fixed limitation where only profile repo topics were shown
2. **GitHub Actions**: Resolved `gmake` vs `make` compatibility on Ubuntu runners
3. **Ollama Connectivity**: Multiple SSH tunnel disconnections requiring restarts
4. **Guile JSON Module**: Removed dependency on missing (json) module

### Deviations from Plan
- Experiments 02-13 remain incomplete due to Ollama connectivity issues
- Focus shifted to infrastructure setup and connectivity troubleshooting
- Some experiments were created as stubs without full implementation

### Testing Completed
1. **Ollama Structured Output (01)**: Successfully tested JSON schema compliance
2. **GitHub API Integration**: Verified `gh` CLI commands work correctly
3. **Makefile Automation**: Confirmed `gmake` invocation for experiments
4. **CI/CD**: Validated hourly cron job execution

### Future Experiments
1. **02-ollama-structured-scheme**: Guile Scheme implementation (partially complete)
2. **03-bidirectional-conversion**: Spec ↔ JSON Schema conversion
3. **04-github-api-integration**: Rate limiting and pagination
4. **05-spec-validation-framework**: JSON Schema validation
5. **06-api-composition**: Multi-API composition patterns
6. **07-error-handling**: Robust error patterns
7. **08-caching-layer**: Request/response caching
8. **09-config-management**: Environment-based configuration
9. **10-integration-tests**: End-to-end testing
10. **11-monitoring-observability**: API usage monitoring
11. **12-schema-evolution**: Version migration strategies
12. **13-documentation-generation**: Auto-generated docs from specs

### Technical Achievements
- Converted shell script to use GitHub API directly via `gh` CLI
- Created comprehensive API specifications (api-specs.json)
- Implemented Guile Scheme version of metadata checker
- Built experiment framework with Makefile automation
- Successfully tested Ollama structured JSON output

### Pending Work
- Complete remaining experiments (02-13)
- Resolve Ollama connectivity stability
- Implement full Scheme JSON parsing
- Add comprehensive error handling
- Create integration test suite

## Important Commands

### Running Experiments
**ALWAYS use gmake with -C flag to avoid pwd issues:**
```bash
gmake -C experiments/01-ollama-structured-output run
gmake -C experiments/02-ollama-structured-scheme run
gmake -C experiments/03-spec-json-conversion run
# etc...
```

**NEVER use:**
```bash
cd experiments/03-spec-json-conversion && gmake run  # WRONG - causes pwd issues
```