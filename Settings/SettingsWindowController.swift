import AppKit
import SwiftUI

// MARK: - SettingsWindowController

final class SettingsWindowController: NSWindowController {
    private let viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel

        let hostingView = NSHostingView(rootView: SettingsView(viewModel: viewModel))

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "ArkCodingPlanTray Settings"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("SettingsWindow")

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        // If window was closed, re-show it
        if window?.isVisible == false {
            window?.orderFront(nil)
        }
        window?.makeKeyAndOrderFront(nil)
        window?.level = .normal
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Singleton Holder

extension SettingsWindowController {
    private static var sharedInstance: SettingsWindowController?

    static func shared(settingsStore: SettingsStore? = nil,
                       secureStore: SecureStore? = nil,
                       apiClient: CodingPlanClient? = nil,
                       onSave: (() -> Void)? = nil) -> SettingsWindowController {
        if let existing = sharedInstance {
            if let onSave = onSave {
                existing.viewModel.setOnSave(onSave)
            }
            return existing
        }

        let store = settingsStore ?? UserDefaultsSettingsStore()
        let secure = secureStore ?? KeychainStore()
        let client = apiClient ?? CodingPlanClient(secureStore: secure)

        let viewModel = SettingsViewModel(
            settingsStore: store,
            secureStore: secure,
            apiClient: client,
            onSave: onSave ?? {}
        )

        let controller = SettingsWindowController(viewModel: viewModel)
        sharedInstance = controller
        return controller
    }

    static func resetShared() {
        sharedInstance = nil
    }
}
