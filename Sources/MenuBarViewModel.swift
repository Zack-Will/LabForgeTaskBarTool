import Foundation
import ServiceManagement
import SwiftUI

@MainActor
final class MenuBarViewModel: ObservableObject {
    private enum DefaultsKeys {
        static let showLeaderboard = "showLeaderboard"
        static let showMenuBarText = "showMenuBarText"
    }

    @Published private(set) var modelStatus: ModelStatusPayload?
    @Published private(set) var leaderboard: LeaderboardPayload?
    @Published private(set) var budgetStatus: BudgetStatusPayload?
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastError: String?
    @Published var launchAtLoginEnabled = false
    @Published var showLeaderboard = false
    @Published var showMenuBarText = true

    private let service = LabForgeService()
    private var refreshTask: Task<Void, Never>?

    init() {
        launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        showLeaderboard = UserDefaults.standard.object(forKey: DefaultsKeys.showLeaderboard) as? Bool ?? false
        showMenuBarText = UserDefaults.standard.object(forKey: DefaultsKeys.showMenuBarText) as? Bool ?? true

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

    var menuBarTitle: String {
        guard let status = modelStatus else { return "LabForge --/--" }
        let total = status.orderedModels.count
        let upCount = status.orderedModels.filter(\.isUp).count
        return "LabForge \(upCount)/\(total)"
    }

    var menuBarSymbol: String {
        guard let status = modelStatus else { return "bolt.horizontal.circle" }
        return status.orderedModels.allSatisfy(\.isUp) ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            async let status = service.fetchModelStatus()
            async let leaderboard = service.fetchLeaderboard()
            async let budget = service.fetchBudgetStatus()
            self.modelStatus = try await status
            self.leaderboard = try await leaderboard
            self.budgetStatus = try await budget
            self.lastError = nil
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    var topThreeEntries: [LeaderboardEntry] {
        Array((leaderboard?.all ?? []).prefix(3))
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
}
