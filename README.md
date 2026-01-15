# pull-request-ping

A Swift CLI tool for viewing and interacting with PR comments across **GitHub**, **GitLab**, and **Azure DevOps**.

## Features

- **Multi-platform support**: GitHub, GitLab, and Azure DevOps
- **Translation**: Built-in translation using Apple's Translation.framework (macOS 14.4+)
- **Thread management**: View, reply to, and resolve review threads
- **Filtering**: Show only unresolved or resolved threads
- **Multiple output formats**: Plain text, Markdown, or JSON

## Installation

### Via Swift Package Manager

```bash
swift package experimental-install --product pull-request-ping
```

### From Source

```bash
git clone https://github.com/promptping-ai/pull-request-ping.git
cd pull-request-ping
swift build -c release
```

## Usage

### View PR Comments

```bash
# View comments for PR #29
pull-request-ping 29

# View current branch's PR
pull-request-ping --current

# Include PR description
pull-request-ping 29 --with-body

# Show only unresolved threads
pull-request-ping 29 --unresolved

# Use specific provider
pull-request-ping 29 --provider azure

# Translate comments to English
pull-request-ping 29 --language en

# Output as JSON (for scripting)
pull-request-ping 29 --format json
```

### Reply to PR

```bash
# Reply to a PR
pull-request-ping reply 29 --message "Done!"

# Reply with translation
pull-request-ping reply 29 -m "Terminé!" --translate-to en
```

### Reply to Specific Thread

```bash
# Reply to a specific comment/thread
pull-request-ping reply-to 29 THREAD_ID --message "Fixed"
```

### Resolve Thread

```bash
# Resolve a discussion thread (GitHub only via GraphQL)
pull-request-ping resolve 29 THREAD_ID
```

## Prerequisites

The tool uses platform-specific CLIs under the hood:

| Platform | Required CLI |
|----------|--------------|
| GitHub | [gh](https://cli.github.com/) |
| GitLab | [glab](https://gitlab.com/gitlab-org/cli) |
| Azure DevOps | [az](https://docs.microsoft.com/en-us/cli/azure/) |

## Translation Support

Translation requires macOS 14.4+ and uses Apple's Translation.framework. Supported languages:

- English, French, Dutch, German, Spanish, Italian
- Japanese, Korean, Chinese, Arabic, Hindi
- Portuguese, Russian, Polish, Turkish, Ukrainian
- Indonesian, Thai, Vietnamese

First use may prompt you to download language models via System Settings → General → Language & Region → Translation Languages.

## Library Usage

You can also use `PullRequestPing` as a Swift library:

```swift
import PullRequestPing

// Create provider (auto-detects from git remote)
let factory = ProviderFactory()
let provider = try await factory.createProvider()

// Fetch PR data
let pr = try await provider.fetchPR(identifier: "29", repo: nil)

// Format output
let formatter = PRCommentsFormatter()
print(formatter.format(pr, includeBody: true))
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.
