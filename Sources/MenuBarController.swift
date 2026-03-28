import AppKit
import Combine
import SwiftUI

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let viewModel: MenuBarViewModel
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let contextMenu = NSMenu()
    private var cancellables = Set<AnyCancellable>()
    private let popoverSize = NSSize(width: 520, height: 820)

    init(viewModel: MenuBarViewModel) {
        self.viewModel = viewModel
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureStatusItem()
        configurePopover()
        configureMenu()
        bindViewModel()
        refreshStatusButton()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageLeading
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = popoverSize
        popover.contentViewController = NSHostingController(
            rootView: MenuBarContentView(viewModel: viewModel)
                .frame(width: popoverSize.width)
        )
    }

    private func configureMenu() {
        contextMenu.delegate = self

        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(refreshNow), keyEquivalent: "r")
        refreshItem.target = self

        let openItem = NSMenuItem(title: "Open LabForge", action: #selector(openLabForge), keyEquivalent: "o")
        openItem.target = self

        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "l")
        launchAtLoginItem.target = self
        launchAtLoginItem.state = viewModel.launchAtLoginEnabled ? .on : .off

        let leaderboardItem = NSMenuItem(title: "Show Leaderboard", action: #selector(toggleLeaderboard), keyEquivalent: "")
        leaderboardItem.target = self
        leaderboardItem.state = viewModel.showLeaderboard ? .on : .off

        let menuBarTextItem = NSMenuItem(title: "Show Menu Bar Text", action: #selector(toggleMenuBarText), keyEquivalent: "")
        menuBarTextItem.target = self
        menuBarTextItem.state = viewModel.showMenuBarText ? .on : .off

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self

        contextMenu.items = [
            refreshItem,
            openItem,
            .separator(),
            menuBarTextItem,
            leaderboardItem,
            launchAtLoginItem,
            .separator(),
            quitItem
        ]
    }

    private func bindViewModel() {
        viewModel.$modelStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshStatusButton()
            }
            .store(in: &cancellables)

        viewModel.$leaderboard
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshMenuState()
            }
            .store(in: &cancellables)

        viewModel.$budgetStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshPopoverContent()
            }
            .store(in: &cancellables)

        viewModel.$launchAtLoginEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshMenuState()
            }
            .store(in: &cancellables)

        viewModel.$showLeaderboard
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshMenuState()
                self?.refreshPopoverContent()
            }
            .store(in: &cancellables)

        viewModel.$showMenuBarText
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshStatusButton()
                self?.refreshMenuState()
            }
            .store(in: &cancellables)
    }

    private func refreshStatusButton() {
        guard let button = statusItem.button else { return }
        button.title = viewModel.showMenuBarText ? viewModel.menuBarTitle : ""
        button.image = NSImage(systemSymbolName: viewModel.menuBarSymbol, accessibilityDescription: "LabForge status")
        button.image?.size = NSSize(width: 14, height: 14)
    }

    private func refreshMenuState() {
        if let item = contextMenu.items.first(where: { $0.title == "Launch at Login" }) {
            item.state = viewModel.launchAtLoginEnabled ? .on : .off
        }
        if let item = contextMenu.items.first(where: { $0.title == "Show Leaderboard" }) {
            item.state = viewModel.showLeaderboard ? .on : .off
        }
        if let item = contextMenu.items.first(where: { $0.title == "Show Menu Bar Text" }) {
            item.state = viewModel.showMenuBarText ? .on : .off
        }
    }

    private func refreshPopoverContent() {
        popover.contentSize = popoverSize
        popover.contentViewController = NSHostingController(
            rootView: MenuBarContentView(viewModel: viewModel)
                .frame(width: popoverSize.width)
        )
    }

    @objc
    private func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            togglePopover(sender)
            return
        }

        switch event.type {
        case .rightMouseUp:
            showContextMenu(sender)
        default:
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func showContextMenu(_ sender: NSStatusBarButton) {
        refreshMenuState()
        statusItem.menu = contextMenu
        sender.performClick(nil)
        statusItem.menu = nil
    }

    @objc
    private func refreshNow() {
        Task { await viewModel.refresh() }
    }

    @objc
    private func openLabForge() {
        if let url = URL(string: "https://www.labforge.top/#model-status") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc
    private func toggleLaunchAtLogin() {
        viewModel.setLaunchAtLogin(!viewModel.launchAtLoginEnabled)
    }

    @objc
    private func toggleLeaderboard() {
        viewModel.setShowLeaderboard(!viewModel.showLeaderboard)
    }

    @objc
    private func toggleMenuBarText() {
        viewModel.setShowMenuBarText(!viewModel.showMenuBarText)
    }

    @objc
    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
