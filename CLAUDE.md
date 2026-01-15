# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build
swift build                                           # Debug build
swift build -c release                                # Release build

# Test (uses Swift Testing framework, NOT XCTest)
swift test                                            # Run all tests
swift test --filter PullRequestPingTests              # Run specific suite
swift test --filter "testFilterUnresolvedComments"    # Run single test

# Lint & Format
swift format lint -s -p -r Sources Tests Package.swift
swift format format -p -r -i Sources Tests Package.swift

# Install CLI tool
swift package experimental-install --product pull-request-ping
```

## Architecture

**Strategy + Factory pattern** for multi-provider PR comment fetching:

```
CLI (PullRequestPingCommand)
         │
         ▼
   ProviderFactory ──auto-detects from git remote──▶ ProviderType enum
         │
         ▼
   PRProvider protocol
         │
    ┌────┴────┬────────────┐
    ▼         ▼            ▼
 GitHub    GitLab       Azure
Provider   Provider    Provider
```

### Key Abstractions

| Type | Purpose |
|------|---------|
| `PRProvider` | Protocol defining `fetchPR()`, `replyToComment()`, `resolveThread()` |
| `ProviderFactory` | Auto-detects provider from git remote URL patterns |
| `PullRequest` | Contains `comments` (top-level) and `reviews` (with inline `ReviewComment`) |
| `TranslationService` | Actor wrapping Apple's Translation.framework for markdown-preserving translation |

### Provider Detection

The factory parses git remote URLs to detect:
- `github.com` → GitHub (`gh` CLI)
- `gitlab.com` or `gitlab.*` → GitLab (`glab` CLI)
- `dev.azure.com` or `visualstudio.com` → Azure DevOps (`az` CLI)

### Translation System

Uses **Apple's Translation.framework** (NOT FoundationModels):
- `MarkdownPreserver` extracts translatable text while preserving markdown structure
- `TranslationService` actor handles batch translation
- Graceful fallback: shows original text if translation unavailable

### Thread Resolution

- **GitHub**: Uses GraphQL API (`gh api graphql`) with `PRRT_` thread IDs
- **GitLab/Azure**: Native thread resolution via their respective CLIs

## CLI Usage

```bash
# View PR comments (auto-detects provider)
pull-request-ping 123                    # By PR number
pull-request-ping --current              # Current branch's PR
pull-request-ping 123 --unresolved       # Only unresolved threads
pull-request-ping 123 --format json      # JSON output for scripting

# Reply to comments
pull-request-ping reply 123 --message "Done"
pull-request-ping reply-to 123 THREAD_ID --message "Fixed"

# Resolve thread (GitHub only)
pull-request-ping resolve 123 THREAD_ID
```

## Testing Conventions

- Uses **Swift Testing** framework (`@Test`, `#expect`, `@Suite`)
- Test files in `Tests/PullRequestPingTests/`
- Tests cover: model parsing, formatting, resolution filtering, provider-specific behavior
