import XCTest
@testable import uictl

/// Exercises FeedbackStore against a throwaway UICTL_HOME, never ~/.uictl.
final class FeedbackStoreTests: XCTestCase {
    private var tempDir: String!

    override func setUpWithError() throws {
        tempDir = NSTemporaryDirectory() + "uictl-test-\(UUID().uuidString)"
        setenv("UICTL_HOME", tempDir, 1)
    }

    override func tearDownWithError() throws {
        unsetenv("UICTL_HOME")
        try? FileManager.default.removeItem(atPath: tempDir)
    }

    func testPathsHonorOverride() {
        XCTAssertEqual(UICtlPaths.homeDir, tempDir)
        XCTAssertEqual(UICtlPaths.feedbackFilePath, tempDir + "/feedback.json")
    }

    func testEmptyStoreListsNothing() throws {
        XCTAssertTrue(try FeedbackStore.list().isEmpty)
    }

    func testCreateAssignsIncrementingIdsAsDrafts() throws {
        let a = try FeedbackStore.create(category: .issue, title: "a", body: "x")
        let b = try FeedbackStore.create(category: .error, title: "b", body: "y")
        XCTAssertEqual([a.id, b.id], [1, 2])
        XCTAssertEqual(a.status, .draft)
        XCTAssertEqual(try FeedbackStore.list().count, 2)
    }

    func testIdsAreNotReusedAfterDelete() throws {
        _ = try FeedbackStore.create(category: .issue, title: "a", body: "x")
        try FeedbackStore.delete(id: 1)
        let next = try FeedbackStore.create(category: .issue, title: "b", body: "y")
        XCTAssertEqual(next.id, 2)
    }

    func testUpdateChangesOnlyProvidedFields() throws {
        let e = try FeedbackStore.create(category: .issue, title: "t", body: "b")
        let u = try FeedbackStore.update(id: e.id, category: nil, title: "new", body: nil)
        XCTAssertEqual(u.title, "new")
        XCTAssertEqual(u.body, "b")
        XCTAssertEqual(u.category, .issue)
        XCTAssertGreaterThanOrEqual(u.updatedAt, e.updatedAt)
    }

    func testMarkSubmittedRecordsUrl() throws {
        let e = try FeedbackStore.create(category: .recommendation, title: "t", body: "b")
        let s = try FeedbackStore.markSubmitted(id: e.id, url: "https://example.com/1")
        XCTAssertEqual(s.status, .submitted)
        XCTAssertEqual(s.submittedUrl, "https://example.com/1")
        XCTAssertNotNil(s.submittedAt)
        XCTAssertEqual(try FeedbackStore.get(id: e.id).status, .submitted)
    }

    func testMissingIdThrows() {
        XCTAssertThrowsError(try FeedbackStore.get(id: 99))
        XCTAssertThrowsError(try FeedbackStore.delete(id: 99))
        XCTAssertThrowsError(try FeedbackStore.update(id: 99, category: nil, title: "x", body: nil))
    }

    func testSubmissionURLEncodesTitleAndFoldsCategoryIntoBody() throws {
        let e = try FeedbackStore.create(category: .error, title: "a & b", body: "details")
        let url = try FeedbackStore.submissionURL(for: e, repo: "owner/repo")
        let comps = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(comps.host, "github.com")
        XCTAssertEqual(comps.path, "/owner/repo/issues/new")
        let items = Dictionary(uniqueKeysWithValues: (comps.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        XCTAssertEqual(items["title"], "a & b")
        XCTAssertEqual(items["body"], "**Category:** error\n\ndetails")
    }

    func testJSONDictUsesNullForUnsetSubmission() throws {
        let e = try FeedbackStore.create(category: .issue, title: "t", body: "b")
        XCTAssertTrue(e.jsonDict["submittedAt"] is NSNull)
        XCTAssertTrue(e.jsonDict["submittedUrl"] is NSNull)
        XCTAssertEqual(e.jsonDict["status"] as? String, "draft")
    }
}
