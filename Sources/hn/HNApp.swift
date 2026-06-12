import Foundation
import HNCore

@main
struct HNApp {
    static func main() async {
        var count = 10
        var summarize = false
        let args = Array(CommandLine.arguments.dropFirst())
        var i = 0
        while i < args.count {
            if (args[i] == "--count" || args[i] == "-n"), i + 1 < args.count, let n = Int(args[i + 1]) {
                count = max(1, min(n, 50))
                i += 1
            } else if args[i] == "--summarize" || args[i] == "-s" {
                summarize = true
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

            if summarize {
                // Read from environment variable, or try to read from .env file if it exists
                var apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
                if apiKey == nil {
                    // Try to load from .env file in the current directory
                    let fileManager = FileManager.default
                    let envPath = fileManager.currentDirectoryPath + "/.env"
                    if let envString = try? String(contentsOfFile: envPath, encoding: .utf8) {
                        let lines = envString.components(separatedBy: .newlines)
                        for line in lines {
                            if line.starts(with: "GEMINI_API_KEY=") {
                                apiKey = String(line.dropFirst("GEMINI_API_KEY=".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                                break
                            }
                        }
                    }
                }

                guard let finalApiKey = apiKey, !finalApiKey.isEmpty, finalApiKey != "your_api_key_here" else {
                    print("\n[!] To use the summarization feature, please set the GEMINI_API_KEY environment variable or put it in the .env file.")
                    return
                }
                print("\n🤖 Generating summary with AI...")
                let llm = LLMClient(apiKey: finalApiKey)
                let summary = try await llm.summarize(stories: stories)
                print("\n--- Trending on Hacker News ---")
                print(summary)
            }
        } catch {
            print("error: \(error)")
        }
    }
}
