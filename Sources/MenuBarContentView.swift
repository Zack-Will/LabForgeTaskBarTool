import SwiftUI
import AppKit

struct MenuBarContentView: View {
    @ObservedObject var viewModel: MenuBarViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                noticeSection
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
            HStack {
                Text("Leaderboard")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if !viewModel.leaderboardEntries.isEmpty {
                    Text("\(viewModel.leaderboardEntries.count) entries")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.leaderboardEntries.isEmpty {
                ProgressView()
                    .controlSize(.small)
            } else {
                let entries = viewModel.leaderboardEntries
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                            leaderboardRow(index: index, entry: entry)
                            if index < entries.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                }
                .frame(height: min(CGFloat(entries.count) * 44, 260))
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.08))
                )
            }
        }
    }

    private func leaderboardRow(index: Int, entry: LeaderboardEntry) -> some View {
        HStack(spacing: 10) {
            Text("#\(index + 1)")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.alias)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
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
        .padding(.vertical, 6)
    }

    private var noticeSection: some View {
        Group {
            if !viewModel.notices.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Announcements")
                        .font(.subheadline.weight(.semibold))

                    HStack(spacing: 10) {
                        Text("公告")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.12))
                            .foregroundStyle(Color.blue)
                            .clipShape(Capsule())

                        NoticeTickerView(items: viewModel.notices)
                            .frame(height: 20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .clipped()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.08))
                    )
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
                        title: budget.gpt.title,
                        tint: Color.green,
                        channel: budget.gpt
                    )
                    budgetCard(
                        title: budget.claude.title,
                        tint: Color.blue,
                        channel: budget.claude
                    )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Budget updated: \(budget.updatedAt)")
                    if let windowStart = budget.windowStart, let windowEnd = budget.windowEnd {
                        Text("Window: \(windowStart) -> \(windowEnd)")
                    } else if let resetHour = budget.resetHour {
                        Text("Reset hour: \(resetHour):00")
                    }
                }
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

            if viewModel.modelStatus != nil {
                ForEach(Array(viewModel.visibleModels.enumerated()), id: \.element.id) { _, model in
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
                                    .foregroundStyle(model.status == .ok ? Color.secondary : color(for: model.status))
                            }

                            let statusColor = color(for: model.status)
                            Text(model.status.label)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(statusColor.opacity(0.14))
                                .foregroundStyle(statusColor)
                                .clipShape(Capsule())
                        }

                        HStack(spacing: 2) {
                            ForEach(Array(model.recentProbes.enumerated()), id: \.offset) { _, probe in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(color(for: probe.status))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 18)
                                    .help("\(probe.status.label) • \(probe.ms) ms • \(probe.timestamp)")
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

    private func color(for status: ModelProbeStatus) -> Color {
        switch status {
        case .ok:
            return .green
        case .budget:
            return .gray
        case .error, .unknown:
            return .red
        }
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
                    if let url = URL(string: "https://zju.labforge.top/#model-status") {
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
            if let description = channel.description {
                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("$\(channel.spent, specifier: "%.2f") / $\(channel.budget, specifier: "%.0f")")
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

            Text("Remaining $\(channel.remaining, specifier: "%.2f") • \(channel.usageRatio * 100, specifier: "%.0f")% used")
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

struct NoticeTickerView: View {
    let items: [String]

    @State private var offset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0

    private var tickerText: String {
        items.joined(separator: "   •   ")
    }

    var body: some View {
        GeometryReader { geometry in
            let repeatedText = tickerText + "   •   " + tickerText

            ZStack(alignment: .leading) {
                Text(repeatedText)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .offset(x: offset)
                    .background(
                        GeometryReader { textProxy in
                            Color.clear
                                .onAppear {
                                    let measured = measureTextWidth(tickerText + "   •   ")
                                    contentWidth = measured
                                    startAnimation(containerWidth: geometry.size.width)
                                }
                                .onChange(of: geometry.size.width) { _, newWidth in
                                    startAnimation(containerWidth: newWidth)
                                }
                        }
                    )
            }
            .frame(width: geometry.size.width, alignment: .leading)
            .clipped()
        }
    }

    private func startAnimation(containerWidth: CGFloat) {
        guard contentWidth > 0, containerWidth > 0 else { return }
        offset = containerWidth
        let travel = containerWidth + contentWidth
        let duration = max(12, Double(travel / 28))
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            offset = -contentWidth
        }
    }

    private func measureTextWidth(_ text: String) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium)
        ]
        return ceil((text as NSString).size(withAttributes: attributes).width)
    }
}
