import XCTest
@testable import HNCore

final class HNCoreTests: XCTestCase {

    /// In-memory fetcher so tests run offline; matches by URL substring.
    struct MockFetcher: Fetcher {
        let responses: [String: Data]
        func data(from url: URL) async throws -> Data {
            for (key, data) in responses where url.absoluteString.contains(key) {
                return data
            }
            throw URLError(.fileDoesNotExist)
        }
    }

    private func itemJSON(_ id: Int, title: String?, type: String = "story") -> Data {
        let titleField = title.map { "\"\($0)\"" } ?? "null"
        return Data("""
        {"id":\(id),"title":\(titleField),"type":"\(type)","by":"tester","score":\(id * 10)}
        """.utf8)
    }

    func testTopStoriesPreserveOrderAndDropInvalid() async throws {
        let responses: [String: Data] = [
            "topstories.json": Data("[1,2,3]".utf8),
            "item/1.json": itemJSON(1, title: "First"),
            "item/2.json": itemJSON(2, title: nil),     // no title -> filtered out
            "item/3.json": itemJSON(3, title: "Third"),
        ]
        let client = HNClient(fetcher: MockFetcher(responses: responses))
        let stories = try await client.topStories(limit: 3)

        XCTAssertEqual(stories.map(\.id), [1, 3])        // ranking preserved, #2 dropped
        XCTAssertEqual(stories.first?.title, "First")
    }

    func testCacheStoresFetchedItem() async throws {
        let responses: [String: Data] = [
            "item/42.json": itemJSON(42, title: "Cached")
        ]
        let cache = ItemCache()
        let client = HNClient(fetcher: MockFetcher(responses: responses), cache: cache)
        _ = try await client.item(42)
        let stored = await cache.get(42)
        XCTAssertEqual(stored?.title, "Cached")
    }

    func testValidation() {
        XCTAssertTrue(Validator.isValidURL("https://example.com"))
        XCTAssertFalse(Validator.isValidURL("not a url"))
        XCTAssertFalse(Validator.isValidURL(nil))
        XCTAssertFalse(Validator.isValidStory(Item(id: 1, title: "  ")))
        XCTAssertTrue(Validator.isValidStory(Item(id: 1, title: "Real", type: "story")))
    }
}
