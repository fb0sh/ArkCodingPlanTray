import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Refresh Interval
            VStack(alignment: .leading, spacing: 8) {
                Text("Auto Refresh")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Text("Every")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    TextField("", value: $viewModel.refreshInterval, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                        .frame(width: 60)

                    Stepper("", value: $viewModel.refreshInterval, in: 1...60, step: 1)
                        .labelsHidden()

                    Text("minutes")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Cookie
            VStack(alignment: .leading, spacing: 8) {
                Text("Cookie")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                Text("从浏览器 DevTools → Network → GetCodingPlanUsage 请求中复制完整的 Cookie 请求头。")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.8))
                    .lineLimit(3, reservesSpace: true)

                CookieTextView(text: $viewModel.cookie)
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    )
            }

            Divider()

            // Action buttons
            HStack(spacing: 12) {
                // Test Connection
                Button {
                    viewModel.testConnection()
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isTesting {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 11))
                        }
                        Text("Test Connection")
                    }
                }
                .disabled(viewModel.isTesting)
                .controlSize(.small)

                // Test result
                if let testResult = viewModel.testResult {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: testResult ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(testResult ? Color(red: 82/255, green: 82/255, blue: 225/255) : .red)

                            Text(testResult ? "Connection Success" : "Connection Failed")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        if let errorMsg = viewModel.testErrorMessage {
                            Text(errorMsg)
                                .font(.system(size: 10))
                                .foregroundColor(.red.opacity(0.8))
                                .lineLimit(2)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }

                Spacer()

                // Save button
                Button {
                    viewModel.save()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 11))
                        Text("Save")
                    }
                }
                .controlSize(.small)
                .keyboardShortcut("s", modifiers: .command)
            }

            // Save hint
            if viewModel.showSaveHint {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 82/255, green: 82/255, blue: 225/255))
                    Text("Settings saved")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 480, height: 380)
        .animation(.easeInOut(duration: 0.2), value: viewModel.testResult)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showSaveHint)
    }
}

// MARK: - SettingsViewModel

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var cookie: String
    @Published var refreshInterval: Int
    @Published var isTesting: Bool = false
    @Published var testResult: Bool?
    @Published var testErrorMessage: String?
    @Published var showSaveHint: Bool = false

    private let settingsStore: SettingsStore
    private let secureStore: SecureStore
    private let apiClient: CodingPlanClient
    private var onSave: () -> Void

    init(
        settingsStore: SettingsStore,
        secureStore: SecureStore,
        apiClient: CodingPlanClient,
        onSave: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.secureStore = secureStore
        self.apiClient = apiClient
        self.onSave = onSave

        self.cookie = secureStore.loadCookie() ?? ""
        self.refreshInterval = Int(settingsStore.refreshInterval / 60)
    }

    func setOnSave(_ callback: @escaping () -> Void) {
        self.onSave = callback
    }

    func save() {
        settingsStore.refreshInterval = TimeInterval(max(refreshInterval, 1) * 60)

        if !cookie.isEmpty {
            try? secureStore.saveCookie(cookie)
        }

        showSaveHint = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.showSaveHint = false
        }

        onSave()
    }

    func testConnection() {
        guard !isTesting else { return }

        // Save current cookie first so the API client uses it
        if !cookie.isEmpty {
            try? secureStore.saveCookie(cookie)
        }

        isTesting = true
        testResult = nil
        testErrorMessage = nil

        Task {
            do {
                let success = try await apiClient.testConnection()
                withAnimation {
                    self.testResult = success
                }
            } catch {
                withAnimation {
                    self.testResult = false
                    self.testErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                }
            }
            self.isTesting = false
        }
    }
}

// MARK: - CookieTextView

struct CookieTextView: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.delegate = context.coordinator
        textView.allowsUndo = true

        // Enable standard edit menu (Cut, Copy, Paste, Select All)
        textView.menu = NSMenu()
        textView.menu?.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "")
        textView.menu?.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "")
        textView.menu?.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "")
        textView.menu?.addItem(NSMenuItem.separator())
        textView.menu?.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "")

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CookieTextView

        init(_ parent: CookieTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
