import Foundation

struct LabForgeService {
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 20
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()

    func fetchModelStatus() async throws -> ModelStatusPayload {
        let url = URL(string: "https://zju.labforge.top/model-status.json")!
        let (data, response) = try await session.data(from: url)
        try validate(response: response)
        let decoder = JSONDecoder()
        return try decoder.decode(ModelStatusPayload.self, from: data)
    }

    func fetchLeaderboard() async throws -> LeaderboardPayload {
        let url = URL(string: "https://zju.labforge.top/leaderboard-data.js")!
        let (data, response) = try await session.data(from: url)
        try validate(response: response)

        guard
            let body = String(data: data, encoding: .utf8),
            let payload = extractLeaderboardJSON(from: body)?.data(using: .utf8)
        else {
            throw LabForgeServiceError.invalidLeaderboardPayload
        }

        let decoder = JSONDecoder()
        return try decoder.decode(LeaderboardPayload.self, from: payload)
    }

    func fetchBudgetStatus() async throws -> BudgetStatusPayload {
        let url = URL(string: "https://zju.labforge.top/budget-status.json")!
        let (data, response) = try await session.data(from: url)
        try validate(response: response)
        let decoder = JSONDecoder()
        return try decoder.decode(BudgetStatusPayload.self, from: data)
    }

    func fetchNotices() async throws -> NoticePayload {
        do {
            return try await fetchNoticesJSON()
        } catch {
            return try await fetchHomepageNotices()
        }
    }

    private func fetchNoticesJSON() async throws -> NoticePayload {
        let url = URL(string: "https://zju.labforge.top/notices.json")!
        let (data, response) = try await session.data(from: url)
        try validate(response: response)
        return try decodeNotices(from: data)
    }

    private func fetchHomepageNotices() async throws -> NoticePayload {
        let url = URL(string: "https://zju.labforge.top/")!
        let (data, response) = try await session.data(from: url)
        try validate(response: response)

        guard let html = String(data: data, encoding: .utf8) else {
            throw LabForgeServiceError.invalidNoticePayload
        }

        let rawItems = try extractNoticeArray(from: html)
        let itemPattern = #""((?:\\"|[^"])*)""#
        let itemRegex = try NSRegularExpression(pattern: itemPattern)
        let itemRange = NSRange(rawItems.startIndex..<rawItems.endIndex, in: rawItems)
        let notices = itemRegex.matches(in: rawItems, options: [], range: itemRange).compactMap { match -> String? in
            guard let captured = Range(match.range(at: 1), in: rawItems) else { return nil }
            return String(rawItems[captured]).replacingOccurrences(of: #"\""#, with: #"""#)
        }

        let payload = NoticePayload(items: notices)
        guard !payload.items.isEmpty else {
            throw LabForgeServiceError.invalidNoticePayload
        }

        return payload
    }

    private func validate(response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw LabForgeServiceError.badServerResponse
        }
    }

    private func extractLeaderboardJSON(from script: String) -> String? {
        let prefix = "window.__LEADERBOARD__ ="
        guard let start = script.range(of: prefix) else { return nil }
        let tail = script[start.upperBound...]
        guard let end = tail.firstIndex(of: ";") else { return nil }
        return tail[..<end].trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func decodeNotices(from data: Data) throws -> NoticePayload {
        let payload = try JSONDecoder().decode(NoticePayload.self, from: data)
        guard !payload.items.isEmpty else {
            throw LabForgeServiceError.invalidNoticePayload
        }
        return payload
    }

    private func extractNoticeArray(from html: String) throws -> String {
        let patterns = [
            #"const\s+DEFAULT_NOTICE_ITEMS\s*=\s*\[(.*?)\];"#,
            #"const\s+NOTICE_ITEMS\s*=\s*\[(.*?)\];"#
        ]
        let range = NSRange(html.startIndex..<html.endIndex, in: html)

        for pattern in patterns {
            let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
            guard
                let match = regex.firstMatch(in: html, options: [], range: range),
                let itemsRange = Range(match.range(at: 1), in: html)
            else {
                continue
            }
            return String(html[itemsRange])
        }

        throw LabForgeServiceError.invalidNoticePayload
    }
}

enum LabForgeServiceError: LocalizedError {
    case badServerResponse
    case invalidLeaderboardPayload
    case invalidNoticePayload

    var errorDescription: String? {
        switch self {
        case .badServerResponse:
            return "LabForge server returned an unexpected response."
        case .invalidLeaderboardPayload:
            return "Could not parse leaderboard data."
        case .invalidNoticePayload:
            return "Could not parse notice data."
        }
    }
}
