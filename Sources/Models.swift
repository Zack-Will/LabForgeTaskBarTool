import Foundation

struct ModelStatusPayload: Decodable {
    let models: [String: MonitoredModel]
    let updatedAt: String
    let pingMS: Int

    enum CodingKeys: String, CodingKey {
        case models
        case updatedAt = "updated_at"
        case pingMS = "ping_ms"
    }

    var orderedModels: [MonitoredModelSummary] {
        let order = [
            "claude-opus-4-6",
            "claude-sonnet-4-6",
            "claude-haiku-4-5",
            "gpt-5.3-codex",
            "gpt-5.4"
        ]

        return order.compactMap { id in
            guard let model = models[id] else { return nil }
            return MonitoredModelSummary(id: id, model: model)
        }
    }
}

struct MonitoredModel: Decodable {
    let name: String
    let provider: String
    let api: String
    let history: [ModelProbe]
}

struct ModelProbe: Decodable {
    let timestamp: String
    let ok: Bool
    let ms: Int

    enum CodingKeys: String, CodingKey {
        case timestamp = "t"
        case ok
        case ms
    }
}

struct MonitoredModelSummary: Identifiable {
    let id: String
    let name: String
    let provider: String
    let latencyMS: Int
    let successRate: Double
    let isUp: Bool
    let recentProbes: [ModelProbe]
    let latestTimestamp: String

    init(id: String, model: MonitoredModel) {
        self.id = id
        self.name = model.name
        self.provider = model.provider
        self.latencyMS = model.history.last?.ms ?? 0
        self.isUp = model.history.last?.ok ?? false
        self.recentProbes = Array(model.history.suffix(60))
        self.latestTimestamp = model.history.last?.timestamp ?? "--"

        let total = Double(model.history.count)
        let success = Double(model.history.filter(\.ok).count)
        self.successRate = total > 0 ? success / total : 0
    }
}

struct LeaderboardPayload: Decodable {
    let all: [LeaderboardEntry]
    let month: [LeaderboardEntry]
    let week: [LeaderboardEntry]
    let day: [LeaderboardEntry]
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case all
        case month
        case week
        case day
        case updatedAt = "updated_at"
    }
}

struct LeaderboardEntry: Decodable, Identifiable {
    let alias: String
    let tokens: Int
    let claudeTokens: Int?
    let gptTokens: Int?

    enum CodingKeys: String, CodingKey {
        case alias
        case tokens
        case claudeTokens = "claude_tokens"
        case gptTokens = "gpt_tokens"
    }

    var id: String { alias }
}

struct BudgetStatusPayload: Decodable {
    let gpt: BudgetChannel
    let claude: BudgetChannel
    let windowStart: String?
    let windowEnd: String?
    let resetHour: Int?
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case gpt
        case claude
        case windowStart = "window_start"
        case windowEnd = "window_end"
        case resetHour = "reset_hour"
        case updatedAt = "updated_at"
    }
}

struct BudgetChannel: Decodable, Identifiable {
    let spent: Double
    let budget: Double
    let title: String
    let description: String?
    let channel: String?

    enum CodingKeys: String, CodingKey {
        case spent
        case budget
        case title
        case label
        case description
        case channel
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        spent = try container.decode(Double.self, forKey: .spent)
        budget = try container.decode(Double.self, forKey: .budget)
        title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decode(String.self, forKey: .label)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        channel = try container.decodeIfPresent(String.self, forKey: .channel)
    }

    var id: String { title }

    var remaining: Double {
        max(0, budget - spent)
    }

    var usageRatio: Double {
        guard budget > 0 else { return 0 }
        return min(max(spent / budget, 0), 1)
    }
}

struct NoticePayload {
    let items: [String]
}
