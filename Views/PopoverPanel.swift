import AppKit
import SwiftUI

// MARK: - PopoverPanel

final class PopoverPanel: NSPanel {
    // MARK: - Initialization

    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 600),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.level = .statusBar
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isMovable = false
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace, .stationary]
        self.titlebarAppearsTransparent = true
        self.isReleasedWhenClosed = false

        // Make sure we can become key window for keyboard events
        self.acceptsMouseMovedEvents = true

        // Set content
        self.contentView = contentView
    }

    // MARK: - Keyboard Events

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        close()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC
            close()
        } else {
            super.keyDown(with: event)
        }
    }
}
