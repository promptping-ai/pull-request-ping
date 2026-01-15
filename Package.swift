// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "pull-request-ping",
  platforms: [.macOS(.v14)],
  products: [
    .library(
      name: "PullRequestPing",
      targets: ["PullRequestPing"]
    ),
    .executable(
      name: "pull-request-ping",
      targets: ["pull-request-ping"]
    ),
  ],
  dependencies: [
    // Modern async subprocess execution
    .package(
      url: "https://github.com/swiftlang/swift-subprocess.git",
      from: "0.1.0"
    ),
    // Markdown parsing for translation preservation
    .package(
      url: "https://github.com/swiftlang/swift-markdown.git",
      from: "0.5.0"
    ),
    // CLI argument parsing
    .package(
      url: "https://github.com/apple/swift-argument-parser.git",
      from: "1.3.0"
    ),
  ],
  targets: [
    // PR comments library (parses and formats PR comments from GitHub/GitLab/Azure)
    .target(
      name: "PullRequestPing",
      dependencies: [
        .product(name: "Subprocess", package: "swift-subprocess"),
        .product(name: "Markdown", package: "swift-markdown"),
      ],
      linkerSettings: [
        // Translation.framework for neural machine translation (macOS 14.4+)
        .linkedFramework("Translation", .when(platforms: [.macOS, .iOS]))
      ]
    ),

    // CLI tool (installable via swift package experimental-install)
    .executableTarget(
      name: "pull-request-ping",
      dependencies: [
        "PullRequestPing",
        .product(name: "Subprocess", package: "swift-subprocess"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),

    // Tests
    .testTarget(
      name: "PullRequestPingTests",
      dependencies: ["PullRequestPing"]
    ),
  ]
)
