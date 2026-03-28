import SwiftUI
import AppKit

struct MenuBarContentView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                budgetSection
                recentStatusSection
                if viewModel.showLeaderboard {
                    leaderboardSection
                }
                footer
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: 780)
        .task {
            await viewModel.refresh()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("LabForge Monitor")
                    .font(.headline)
                if let payload = viewModel.modelStatus {
                    Text("Ping \(payload.pingMS) ms")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Loading status...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                Task { await viewModel.refresh() }
            } label: {
                if viewModel.isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .buttonStyle(.borderless)
            .help("Refresh now")
        }
    }

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top 3 Leaderboard")
                .font(.subheadline.weight(.semibold))

            if viewModel.topThreeEntries.isEmpty {
                ProgressView()
                    .controlSize(.small)
            } else {
                ForEach(Array(viewModel.topThreeEntries.enumerated()), id: \.element.id) { index, entry in
                    HStack(spacing: 10) {
                        Text("#\(index + 1)")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 24, alignment: .leading)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.alias)
                                .font(.system(size: 13, weight: .medium))
                            Text("\(entry.tokens.formatted()) tokens")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        let claude = entry.claudeTokens ?? 0
                        let gpt = entry.gptTokens ?? 0
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("C \(claude.formatted())")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.orange)
                            Text("G \(gpt.formatted())")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Model Remaining")
                .font(.subheadline.weight(.semibold))

            if let budget = viewModel.budgetStatus {
                HStack(spacing: 10) {
                    budgetCard(
                        title: budget.gpt.label,
                        tint: Color.green,
                        channel: budget.gpt
                    )
                    budgetCard(
                        title: budget.claude.label,
                        tint: Color.orange,
                        channel: budget.claude
                    )
                }

                Text("Budget updated: \(budget.updatedAt)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var recentStatusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Status")
                .font(.subheadline.weight(.semibold))

            if let payload = viewModel.modelStatus {
                ForEach(Array(payload.orderedModels.enumerated()), id: \.element.id) { _, model in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.name)
                                    .font(.system(size: 12, weight: .medium))
                                Text(model.provider)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(model.latencyMS) ms")
                                    .font(.system(.caption, design: .monospaced))
                                Text(model.successRate, format: .percent.precision(.fractionLength(0)))
                                    .font(.caption2)
                                    .foregroundStyle(model.isUp ? Color.secondary : Color.red)
                            }
                            Text(model.isUp ? "OK" : "FAIL")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(model.isUp ? Color.green.opacity(0.14) : Color.red.opacity(0.14))
                                .foregroundStyle(model.isUp ? Color.green : Color.red)
                                .clipShape(Capsule())
                        }

                        HStack(spacing: 2) {
                            ForEach(Array(model.recentProbes.enumerated()), id: \.offset) { _, probe in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(probe.ok ? Color.green : Color.red)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 18)
                                    .help("\(probe.ok ? "OK" : "FAIL") • \(probe.ms) ms • \(probe.timestamp)")
                            }
                        }

                        HStack {
                            Text("PAST")
                            Spacer()
                            Text("NOW")
                        }
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary.opacity(0.75))
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.08))
                    )
                }
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private func shortTimestamp(_ raw: String) -> String {
        guard raw.count >= 16 else { return raw }
        let start = raw.index(raw.startIndex, offsetBy: 11)
        let end = raw.index(raw.startIndex, offsetBy: 16)
        return String(raw[start..<end])
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            if let updatedAt = viewModel.modelStatus?.updatedAt {
                Text("Status updated: \(updatedAt)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let updatedAt = viewModel.leaderboard?.updatedAt {
                Text("Leaderboard updated: \(updatedAt)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let error = viewModel.lastError {
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }

            Toggle("Launch at Login", isOn: Binding(
                get: { viewModel.launchAtLoginEnabled },
                set: { viewModel.setLaunchAtLogin($0) }
            ))
            .toggleStyle(.switch)

            HStack {
                Button("Open LabForge") {
                    if let url = URL(string: "https://www.labforge.top/#model-status") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
    }

    private func budgetCard(title: String, tint: Color, channel: BudgetChannel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))

            Text("\(channel.remaining, specifier: "%.1f") / \(channel.budget, specifier: "%.0f")")
                .font(.system(size: 16, weight: .bold, design: .rounded))

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.12))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(tint)
                        .frame(width: max(10, proxy.size.width * CGFloat(channel.usageRatio)))
                }
            }
            .frame(height: 8)

            Text("Used \(channel.spent, specifier: "%.1f") (\(channel.usageRatio * 100, specifier: "%.0f")%)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}
