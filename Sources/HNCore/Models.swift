import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Model

/// A Hacker News item (story / job / etc.). Most fields are optional because
/// the API omits them depending on the item type.
public struct Item: Codable, Sendable, Identifiable {
    public let id: Int
    public let title: String?
    public let by: String?
    public let score: Int?
    public let url: String?
    public let time: Int?
    public let type: String?
    public let descendants: Int?

    public init(id: Int, title: String? = nil, by: String? = nil, score: Int? = nil,
                url: String? = nil, time: Int? = nil, type: String? = nil, descendants: Int? = nil) {
        self.id = id
        self.title = title
        self.by = by
        self.score = score
        self.url = url
        self.time = time
        self.type = type
        self.descendants = descendants
    }
}

// MARK: - Validation

public enum Validator {
    /// A story we're willing to show: a story-type item with a non-empty title.
    public static func isValidStory(_ item: Item) -> Bool {
        if let type = item.type, type != "story" { return false }
        guard let title = item.title,
              !title.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return true
    }

    public static func isValidURL(_ string: String?) -> Bool {
        guard let string, let url = URL(string: string) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
}

// MARK: - Networking (injectable for testing)

/// Tiny abstraction over the network so the client can be tested offline with
/// a mock. The default implementation uses URLSession's async API.
public protocol Fetcher: Sendable {
    func data(from url: URL) async throws -> Data
}

public struct URLSessionFetcher: Fetcher {
    public init() {}
    public func data(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
