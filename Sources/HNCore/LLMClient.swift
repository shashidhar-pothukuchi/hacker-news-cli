import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A simple client to interact with the Gemini API
public struct LLMClient: Sendable {
    private let apiKey: String
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func summarize(stories: [Item]) async throws -> String {
        let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)")!
        
        let storyDescriptions = stories.enumerated().map { (index, story) in
            "\(index + 1). \(story.title ?? "Untitled") (Score: \(story.score ?? 0))"
        }.joined(separator: "\n")
        
        let prompt = """
        You are an insightful tech analyst. Review the following top stories currently trending on Hacker News.
        Provide a concise, engaging summary (about 3-5 sentences) of the overarching themes, major news, or most interesting tech trends represented in these stories.
        
        Stories:
        \(storyDescriptions)
        """
        
        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(parts: [GeminiPart(text: prompt)])
            ]
        )
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("API Error Response: \(errorString)")
            }
            throw URLError(.badServerResponse)
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = geminiResponse.candidates?.first?.content?.parts?.first?.text else {
            throw URLError(.cannotParseResponse)
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Gemini API Models

private struct GeminiRequest: Codable {
    let contents: [GeminiContent]
}

private struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

private struct GeminiPart: Codable {
    let text: String
}

private struct GeminiResponse: Codable {
    struct Candidate: Codable {
        struct Content: Codable {
            struct Part: Codable {
                let text: String?
            }
            let parts: [Part]?
        }
        let content: Content?
    }
    let candidates: [Candidate]?
}
