import AppKit
import Combine
import SwiftUI

// MARK: - AppDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties

    private var statusItem: NSStatusItem!
    private var statusBarRenderer: StatusBarRenderer!
    private var popoverPanel: PopoverPanel?
    private var viewModel: AppViewModel!
    private var settingsStore: SettingsStore!
    private var secureStore: SecureStore!
    private var apiClient: CodingPlanClient!

    private var monitor: Any?
    private var isPopoverShown: Bool = false
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent app from showing in Dock
        NSApp.setActivationPolicy(.accessory)

        // Initialize services
        settingsStore = UserDefaultsSettingsStore()
        secureStore = KeychainStore()
        apiClient = CodingPlanClient(secureStore: secureStore)
        viewModel = AppViewModel(
            apiClient: apiClient,
            settingsStore: settingsStore
        )

        // Setup status item
        setupStatusItem()

        // Add Edit menu so keyboard shortcuts (Cmd+C/V/A) work in text fields
        setupEditMenu()

        // Register keyboard shortcut
        registerKeyboardShortcuts()

        // Listen for notifications from SwiftUI views
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(closePopover),
            name: NSNotification.Name("ClosePopover"),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettings),
            name: NSNotification.Name("OpenSettings"),
            object: nil
        )

        // Preload data so popover isn't empty on first open
        Task {
            await viewModel.loadData()
        }

        // Observe view model changes to update status bar
        observeViewModel()
    }

    func applicationWillTerminate(_ notification: Notification) {
        removeGlobalMonitor()
    }

    // MARK: - Status Item Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )

        guard let button = statusItem.button else { return }

        // Use renderer to generate the initial image
        statusBarRenderer = StatusBarRenderer()
        button.image = statusBarRenderer.renderFallbackImage()

        button.action = #selector(handleStatusItemClick)
        button.target = self
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func handleStatusItemClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit ArkCodingPlanTray", action: #selector(terminateApp), keyEquivalent: "q"))
            NSMenu.popUpContextMenu(menu, with: event, for: statusItem.button!)
        } else {
            togglePopover()
        }
    }

    @objc private func terminateApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Popover Management

    @objc private func togglePopover() {
        if isPopoverShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }

        // Create popover if needed
        if popoverPanel == nil {
            let hostingView = NSHostingView(
                rootView: PopoverContentView(viewModel: viewModel)
            )
            hostingView.frame = NSRect(x: 0, y: 0, width: 420, height: 600)
            hostingView.autoresizingMask = [.width, .height]

            popoverPanel = PopoverPanel(contentView: hostingView)
        }

        guard let panel = popoverPanel else { return }

        // Calculate position
        let position = calculatePopoverPosition(for: button)
        panel.setFrameOrigin(position)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        isPopoverShown = true

        // Load data if needed
        if viewModel.usage == nil {
            viewModel.refresh()
        }

        // Start auto-refresh
        viewModel.startAutoRefresh()

        // Add global monitor for click outside
        addGlobalMonitor()
    }

    @objc private func closePopover() {
        popoverPanel?.close()
        isPopoverShown = false
        removeGlobalMonitor()
        viewModel.stopAutoRefresh()
    }

    @objc func openSettings() {
        // Close popover first so settings window isn't blocked
        closePopover()
        // Open settings with a callback that refreshes data
        SettingsWindowController.shared(
            settingsStore: settingsStore,
            secureStore: secureStore,
            apiClient: apiClient,
            onSave: { [weak self] in
                self?.viewModel.refresh()
            }
        ).show()
    }

    // MARK: - Popover Positioning

    private func calculatePopoverPosition(for button: NSStatusBarButton) -> NSPoint {
        guard let screen = button.window?.screen ?? NSScreen.main else {
            return .zero
        }

        // Get the button's frame in screen coordinates
        let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero

        let panelWidth: CGFloat = 420
        let screenFrame = screen.visibleFrame

        // Calculate horizontal position - center below the status item
        var x = buttonFrame.midX - panelWidth / 2

        // Ensure the panel doesn't go off-screen
        let minX = screenFrame.minX + 8
        let maxX = screenFrame.maxX - panelWidth - 8
        x = max(minX, min(x, maxX))

        // Calculate vertical position - directly below the menu bar
        // buttonFrame.origin.y is the bottom of the status item (near screen top)
        // We want the popover's top edge just below the menu bar
        let panelHeight = popoverPanel?.frame.height ?? 600
        let y = buttonFrame.origin.y - panelHeight - 8 // 8px gap below menu bar

        return NSPoint(x: x, y: y)
    }

    // MARK: - Global Monitor

    private func addGlobalMonitor() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [
            .leftMouseDown,
            .rightMouseDown,
            .otherMouseDown
        ]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func removeGlobalMonitor() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    // MARK: - View Model Observation

    private func setupEditMenu() {
        // LSUIElement = true removes the menu bar, which breaks Cmd+C/V/A/X/Z
        // in NSTextView. We intercept these key equivalents and forward them
        // to the first responder.
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let cmd = event.modifierFlags.contains(.command)
            guard cmd else { return event }

            switch event.charactersIgnoringModifiers ?? "" {
            case "c":
                NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self)
                return nil
            case "v":
                NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self)
                return nil
            case "x":
                NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self)
                return nil
            case "a":
                NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: self)
                return nil
            case "z":
                if event.modifierFlags.contains(.shift) {
                    NSApp.sendAction(#selector(UndoManager.redo), to: nil, from: self)
                } else {
                    NSApp.sendAction(#selector(UndoManager.undo), to: nil, from: self)
                }
                return nil
            default:
                return event
            }
        }
    }

    private func observeViewModel() {
        viewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusBar()
            }
            .store(in: &cancellables)
    }

    private func updateStatusBar() {
        guard let button = statusItem?.button else { return }

        guard let usage = viewModel.usage else {
            button.image = statusBarRenderer?.renderFallbackImage()
            return
        }

        // Find the most relevant quota (session, or the one with highest percent)
        let sessionQuota = usage.quotaUsage.first { $0.level == "session" }
        let primaryQuota = sessionQuota ?? usage.quotaUsage.max(by: { $0.percent < $1.percent })

        if let quota = primaryQuota {
            button.image = statusBarRenderer?.renderImage(percent: quota.percent)
        } else {
            button.image = statusBarRenderer?.renderFallbackImage()
        }
    }

    // MARK: - Keyboard Shortcuts

    private func registerKeyboardShortcuts() {
        // Cmd+R for refresh
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            // Cmd+R
            if event.modifierFlags.contains(.command) && event.keyCode == 15 {
                if self.isPopoverShown {
                    self.viewModel.refresh()
                    return nil
                }
            }

            // ESC
            if event.keyCode == 53 {
                if self.isPopoverShown {
                    self.closePopover()
                    return nil
                }
            }

            return event
        }
    }
}
