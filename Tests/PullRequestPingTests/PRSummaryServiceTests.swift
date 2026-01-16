import Foundation
import Testing

@testable import PullRequestPing

@Suite("PR Summary Service")
struct PRSummaryServiceTests {

  @Test("Summary of PR with multiple comments produces non-empty output")
  func testSummaryWithComments() async throws {
    let pr = PullRequest(
      body: "This PR adds authentication feature",
      comments: [
        Comment(
          id: "1",
          author: Author(login: "reviewer1"),
          authorAssociation: "MEMBER",
          body: "Please add error handling for the login failure case",
          createdAt: "2025-12-18T10:00:00Z",
          url: "https://github.com/test/pr/1#comment-1"
        ),
        Comment(
          id: "2",
          author: Author(login: "reviewer2"),
          authorAssociation: "COLLABORATOR",
          body: "Consider using async/await instead of callbacks",
          createdAt: "2025-12-18T11:00:00Z",
          url: "https://github.com/test/pr/1#comment-2"
        ),
      ],
      reviews: [
        Review(
          id: "r1",
          author: Author(login: "lead"),
          authorAssociation: "OWNER",
          body: "Good progress, but needs more tests",
          submittedAt: "2025-12-18T12:00:00Z",
          state: "CHANGES_REQUESTED",
          comments: [
            ReviewComment(
              id: "rc1",
              path: "Sources/Auth/Login.swift",
              line: 42,
              body: "Add unit tests for this function",
              createdAt: "2025-12-18T12:00:00Z",
              isResolved: false
            )
          ]
        )
      ]
    )

    let service = PRSummaryService()
    let summary = try await service.summarize(pr)

    #expect(!summary.isEmpty)
    #expect(summary != "No comments to summarize.")
    // Summary should be concise (roughly 1-2 sentences)
    #expect(summary.count < 500)
  }

  @Test("Summary of PR with no comments returns fallback message")
  func testSummaryWithNoComments() async throws {
    let pr = PullRequest(
      body: "Empty PR",
      comments: [],
      reviews: []
    )

    let service = PRSummaryService()
    let summary = try await service.summarize(pr)

    #expect(summary == "No comments to summarize.")
  }

  @Test("Unresolved summary counts threads correctly")
  func testUnresolvedSummary() async throws {
    let pr = PullRequest(
      body: "",
      comments: [],
      reviews: [
        Review(
          id: "1",
          author: Author(login: "reviewer"),
          authorAssociation: "MEMBER",
          body: nil,
          submittedAt: "2025-12-18T10:00:00Z",
          state: "CHANGES_REQUESTED",
          comments: [
            ReviewComment(
              id: "1",
              path: "auth.swift",
              line: 10,
              body: "Missing error handling",
              createdAt: "2025-12-18T10:00:00Z",
              isResolved: false
            ),
            ReviewComment(
              id: "2",
              path: "models.swift",
              line: 20,
              body: "Type safety concern",
              createdAt: "2025-12-18T10:00:00Z",
              isResolved: false
            ),
            ReviewComment(
              id: "3",
              path: "resolved.swift",
              line: 30,
              body: "Already fixed",
              createdAt: "2025-12-18T10:00:00Z",
              isResolved: true
            ),
          ]
        )
      ]
    )

    let service = PRSummaryService()
    let summary = try await service.summarizeUnresolved(pr)

    // Should mention the count of unresolved threads
    #expect(summary.contains("2 unresolved thread"))
    #expect(!summary.isEmpty)
  }

  @Test("Unresolved summary with no unresolved threads returns appropriate message")
  func testUnresolvedSummaryAllResolved() async throws {
    let pr = PullRequest(
      body: "",
      comments: [],
      reviews: [
        Review(
          id: "1",
          author: Author(login: "reviewer"),
          authorAssociation: "MEMBER",
          body: nil,
          submittedAt: "2025-12-18T10:00:00Z",
          state: "APPROVED",
          comments: [
            ReviewComment(
              id: "1",
              path: "fixed.swift",
              line: 10,
              body: "Fixed",
              createdAt: "2025-12-18T10:00:00Z",
              isResolved: true
            )
          ]
        )
      ]
    )

    let service = PRSummaryService()
    let summary = try await service.summarizeUnresolved(pr)

    #expect(summary == "No unresolved threads.")
  }

  @Test("Summary includes review state information")
  func testSummaryIncludesReviewState() async throws {
    let pr = PullRequest(
      body: "",
      comments: [],
      reviews: [
        Review(
          id: "1",
          author: Author(login: "approver"),
          authorAssociation: "MEMBER",
          body: "LGTM, ship it!",
          submittedAt: "2025-12-18T10:00:00Z",
          state: "APPROVED"
        ),
        Review(
          id: "2",
          author: Author(login: "critic"),
          authorAssociation: "MEMBER",
          body: "Needs more work on error handling",
          submittedAt: "2025-12-18T11:00:00Z",
          state: "CHANGES_REQUESTED"
        ),
      ]
    )

    let service = PRSummaryService()
    let summary = try await service.summarize(pr)

    #expect(!summary.isEmpty)
    // The summary should be generated (not the fallback message)
    #expect(summary != "No comments to summarize.")
  }

  @Test("Single unresolved thread uses singular form")
  func testSingleUnresolvedThread() async throws {
    let pr = PullRequest(
      body: "",
      comments: [],
      reviews: [
        Review(
          id: "1",
          author: Author(login: "reviewer"),
          authorAssociation: "MEMBER",
          body: nil,
          submittedAt: "2025-12-18T10:00:00Z",
          state: "CHANGES_REQUESTED",
          comments: [
            ReviewComment(
              id: "1",
              path: "file.swift",
              line: 10,
              body: "Fix this",
              createdAt: "2025-12-18T10:00:00Z",
              isResolved: false
            )
          ]
        )
      ]
    )

    let service = PRSummaryService()
    let summary = try await service.summarizeUnresolved(pr)

    // Should use singular "thread" not "threads"
    #expect(summary.contains("1 unresolved thread:"))
    #expect(!summary.contains("threads"))
  }
}
