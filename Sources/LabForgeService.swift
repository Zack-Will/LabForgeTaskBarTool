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
        let url = URL(string: "https://www.labforge.top/model-status.json")!
        let (data, response) = try await session.data(from: url)
        try validate(response: response)
        let decoder = JSONDecoder()
        return try decoder.decode(ModelStatusPayload.self, from: data)
    }

    func fetchLeaderboard() async throws -> LeaderboardPayload {
        let url = URL(string: "https://www.labforge.top/leaderboard-data.js")!
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
        let url = URL(string: "https://www.labforge.top/budget-status.json")!
        let (data, response) = try await session.data(from: url)
        try validate(response: response)
        let decoder = JSONDecoder()
        return try decoder.decode(BudgetStatusPayload.self, from: data)
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
}

enum LabForgeServiceError: LocalizedError {
    case badServerResponse
    case invalidLeaderboardPayload

    var errorDescription: String? {
        switch self {
        case .badServerResponse:
            return "LabForge server returned an unexpected response."
        case .invalidLeaderboardPayload:
            return "Could not parse leaderboard data."
        }
    }
}
