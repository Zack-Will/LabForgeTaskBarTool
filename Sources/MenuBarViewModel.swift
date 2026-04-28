import Foundation
import ServiceManagement
import SwiftUI

@MainActor
final class MenuBarViewModel: ObservableObject {
    private enum DefaultsKeys {
        static let showLeaderboard = "showLeaderboard"
        static let showMenuBarText = "showMenuBarText"
        static let hiddenModelIDs = "hiddenModelIDs"
    }

    @Published private(set) var modelStatus: ModelStatusPayload?
    @Published private(set) var leaderboard: LeaderboardPayload?
    @Published private(set) var budgetStatus: BudgetStatusPayload?
    @Published private(set) var notices: [String] = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastError: String?
    @Published var launchAtLoginEnabled = false
    @Published var showLeaderboard = false
    @Published var showMenuBarText = true
    @Published var hiddenModelIDs: Set<String> = []

    private let service = LabForgeService()
    private var refreshTask: Task<Void, Never>?

    init() {
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        showLeaderboard = UserDefaults.standard.object(forKey: DefaultsKeys.showLeaderboard) as? Bool ?? false
        showMenuBarText = UserDefaults.standard.object(forKey: DefaultsKeys.showMenuBarText) as? Bool ?? true
        hiddenModelIDs = Set(UserDefaults.standard.stringArray(forKey: DefaultsKeys.hiddenModelIDs) ?? [])

        refreshTask = Task {
            await refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                await refresh()
            }
        }
    }

    deinit {
        refreshTask?.cancel()
    }

    var visibleModels: [MonitoredModelSummary] {
        modelStatus?.orderedModels.filter { !hiddenModelIDs.contains($0.id) } ?? []
    }

    var menuBarTitle: String {
        let models = visibleModels
        guard !models.isEmpty else { return "LabForge --/--" }
        let total = models.count
        let upCount = models.filter(\.isUp).count
        return "LabForge \(upCount)/\(total)"
    }

    var menuBarSymbol: String {
        let models = visibleModels
        guard !models.isEmpty else { return "bolt.horizontal.circle" }
        if models.allSatisfy(\.isUp) {
            return "checkmark.circle.fill"
        }
        if models.contains(where: { $0.status == .error || $0.status == .unknown }) {
            return "exclamationmark.triangle.fill"
        }
        return "dollarsign.circle.fill"
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        async let status = service.fetchModelStatus()
        async let leaderboard = service.fetchLeaderboard()
        async let budget = service.fetchBudgetStatus()
        async let notices = service.fetchNotices()

        var errors: [String] = []

        do {
            self.modelStatus = try await status
        } catch {
            errors.append("Model status: \(error.localizedDescription)")
        }

        do {
            self.leaderboard = try await leaderboard
        } catch {
            errors.append("Leaderboard: \(error.localizedDescription)")
        }

        do {
            self.budgetStatus = try await budget
        } catch {
            errors.append("Budget: \(error.localizedDescription)")
        }

        do {
            self.notices = try await notices.items
        } catch {
            // Notices are secondary; keep the previous ticker text when unavailable.
        }

        self.lastError = errors.isEmpty ? nil : errors.joined(separator: "\n")
    }

    var leaderboardEntries: [LeaderboardEntry] {
        leaderboard?.all ?? []
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }

            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
            lastError = nil
        } catch {
            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
            lastError = "Launch at Login update failed: \(error.localizedDescription)"
        }
    }

    func setShowLeaderboard(_ enabled: Bool) {
        showLeaderboard = enabled
        UserDefaults.standard.set(enabled, forKey: DefaultsKeys.showLeaderboard)
    }

    func setShowMenuBarText(_ enabled: Bool) {
        showMenuBarText = enabled
        UserDefaults.standard.set(enabled, forKey: DefaultsKeys.showMenuBarText)
    }

    func toggleModelVisibility(_ modelID: String) {
        if hiddenModelIDs.contains(modelID) {
            hiddenModelIDs.remove(modelID)
        } else {
            hiddenModelIDs.insert(modelID)
        }
        UserDefaults.standard.set(Array(hiddenModelIDs), forKey: DefaultsKeys.hiddenModelIDs)
    }
}
