import Foundation
import HNCore

@main
struct HNApp {
    static func main() async {
        var count = 10
        let args = Array(CommandLine.arguments.dropFirst())
        var i = 0
        while i < args.count {
            if (args[i] == "--count" || args[i] == "-n"), i + 1 < args.count, let n = Int(args[i + 1]) {
                count = max(1, min(n, 50))
                i += 1
            }
            i += 1
        }

        let client = HNClient()
        do {
            let stories = try await client.topStories(limit: count)
            guard !stories.isEmpty else {
                print("No stories returned.")
                return
            }
            for (rank, story) in stories.enumerated() {
                let score = story.score.map { "\($0) pts" } ?? "—"
                let host = story.url.flatMap { URL(string: $0)?.host } ?? "news.ycombinator.com"
                print(String(format: "%2d. %@", rank + 1, story.title ?? "(untitled)"))
                print("    \(score) · by \(story.by ?? "unknown") · \(host)")
            }
        } catch {
            print("error: \(error)")
        }
    }
}
