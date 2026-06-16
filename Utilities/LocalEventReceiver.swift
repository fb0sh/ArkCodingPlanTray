import Foundation

// MARK: - LocalEventReceiver

/// Protocol for receiving local events from future browser extensions.
/// Currently reserved — no concrete implementation.
///
/// Future extensions may communicate via:
/// - XPC
/// - URL Scheme
/// - Local HTTP Server
/// - WebSocket
protocol LocalEventReceiver: AnyObject, Sendable {
    /// Handle an event received from an external source
    func handleEvent(_ event: LocalEvent)
}

// MARK: - LocalEvent

/// Events that can be received from browser extensions or other sources.
enum LocalEvent: Sendable {
    /// User opened a task in the browser
    case taskOpened(taskID: String)
    /// Task status changed externally
    case taskStatusChanged(taskID: String, newStatus: String)
    /// User wants to refresh the task list
    case refreshRequested
    /// Application should show the popover
    case showPopover
}
