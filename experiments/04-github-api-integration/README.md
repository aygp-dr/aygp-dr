# 04 - GitHub API Integration

This experiment demonstrates integrating with GitHub's REST API using Guile Scheme, including authentication, rate limiting, and pagination.

## Overview

Building a robust GitHub API client in Scheme that:
- Handles authentication via personal access tokens
- Respects rate limits
- Manages pagination for large result sets
- Validates responses against specs

## Components

### github-client.scm
Basic REST client with:
- HTTP request wrapper
- Authentication header injection
- JSON response parsing
- Error handling

### rate-limit-test.scm
Tests for:
- Reading rate limit headers
- Implementing backoff strategies
- Graceful degradation when limits approached

### pagination-test.scm
Demonstrates:
- Following `Link` headers
- Iterating through paged results
- Collecting complete datasets

### specs/
Response specifications for:
- Repository data structure
- User information
- Search results

## Usage

```bash
# Test basic client
guile github-client.scm

# Test rate limiting
guile rate-limit-test.scm

# Test pagination
guile pagination-test.scm
```

## Configuration

Set environment variables:
```bash
export GITHUB_TOKEN=your_token_here
export GITHUB_API_URL=https://api.github.com
```

## Key Concepts

1. **Authentication**: Use Bearer token in Authorization header
2. **Rate Limiting**: Check X-RateLimit-* headers
3. **Pagination**: Parse Link header for next/last pages
4. **Validation**: Match responses against Scheme specs