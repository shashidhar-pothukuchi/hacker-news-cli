import Foundation

/// Thread-safe in-memory cache. Being an `actor` keeps concurrent reads/writes
/// from the parallel fetches data-race free.
public actor ItemCache {
    private var store: [Int: Item] = [:]
    public init() {}
    public func get(_ id: Int) -> Item? { store[id] }
    public func set(_ item: Item) { store[item.id] = item }
}

public struct HNClient: Sendable {
    private let fetcher: Fetcher
    private let cache: ItemCache
    private let base = URL(string: "https://hacker-news.firebaseio.com/v0/")!

    public init(fetcher: Fetcher = URLSessionFetcher(), cache: ItemCache = ItemCache()) {
        self.fetcher = fetcher
        self.cache = cache
    }

    public func topStoryIDs(limit: Int) async throws -> [Int] {
        let url = base.appendingPathComponent("topstories.json")
        let data = try await fetcher.data(from: url)
        let ids = try JSONDecoder().decode([Int].self, from: data)
        return Array(ids.prefix(limit))
    }

    public func item(_ id: Int) async throws -> Item {
        if let cached = await cache.get(id) { return cached }
        let url = base.appendingPathComponent("item/\(id).json")
        let data = try await fetcher.data(from: url)
        let item = try JSONDecoder().decode(Item.self, from: data)
        await cache.set(item)
        return item
    }

    /// Fetch the top `limit` stories. The item fetches run concurrently via a
    /// task group, but results are written back by index so the final list
    /// keeps Hacker News' ranking. Invalid items are dropped.
    public func topStories(limit: Int) async throws -> [Item] {
        let ids = try await topStoryIDs(limit: limit)

        let ordered = try await withThrowingTaskGroup(of: (Int, Item?).self) { group -> [Item?] in
            for (index, id) in ids.enumerated() {
                group.addTask {
                    (index, try? await self.item(id))
                }
            }
            var buffer = [Item?](repeating: nil, count: ids.count)
            for try await (index, item) in group {
                buffer[index] = item
            }
            return buffer
        }

        return ordered.compactMap { $0 }.filter(Validator.isValidStory)
    }
}
