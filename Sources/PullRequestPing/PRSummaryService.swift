import EdgePromptCore
import Foundation

/// Service for summarizing PR comments using local LLM
public actor PRSummaryService {
  private let engine: LLMEngine

  public init() {
    self.engine = LLMEngine()
  }

  /// Summarizes PR comments into 1-2 sentences
  /// - Parameter pr: The pull request to summarize
  /// - Returns: A concise summary of the PR comments
  public func summarize(_ pr: PullRequest) async throws -> String {
    let text = formatCommentsForSummarization(pr)
    guard !text.isEmpty else { return "No comments to summarize." }

    let options = SummarizeOptions(text: text, maxLength: 50)  // ~2 sentences worth of words
    let result = try await engine.summarize(options)
    return result.summary
  }

  /// Summarizes only unresolved comments from a PR
  /// - Parameter pr: The pull request to summarize (should be pre-filtered for unresolved)
  /// - Returns: A concise summary focused on unresolved threads
  public func summarizeUnresolved(_ pr: PullRequest) async throws -> String {
    // Count unresolved threads
    var unresolvedCount = 0
    var unresolvedDetails: [String] = []

    for review in pr.reviews {
      if let comments = review.comments {
        for comment in comments where comment.isResolved == false {
          unresolvedCount += 1
          if let path = comment.path {
            unresolvedDetails.append("\(path): \(comment.body.prefix(100))")
          } else {
            unresolvedDetails.append(comment.body.prefix(100).description)
          }
        }
      }
    }

    guard unresolvedCount > 0 else {
      return "No unresolved threads."
    }

    let text = unresolvedDetails.joined(separator: "\n---\n")
    let options = SummarizeOptions(text: text, maxLength: 50)
    let result = try await engine.summarize(options)

    return "\(unresolvedCount) unresolved thread\(unresolvedCount == 1 ? "" : "s"): \(result.summary)"
  }

  // MARK: - Private Helpers

  private func formatCommentsForSummarization(_ pr: PullRequest) -> String {
    var parts: [String] = []

    // Include review comments (most important for action items)
    for review in pr.reviews {
      if let body = review.body, !body.isEmpty {
        parts.append("[\(review.state)] \(review.author.login): \(body)")
      }
      if let comments = review.comments {
        for comment in comments {
          let status = comment.isResolved == true ? "resolved" : "unresolved"
          let path = comment.path ?? "general"
          parts.append("[\(status)] \(path): \(comment.body)")
        }
      }
    }

    // Include top-level comments
    for comment in pr.comments {
      parts.append("\(comment.author.login): \(comment.body)")
    }

    return parts.joined(separator: "\n---\n")
  }
}
