import Foundation
import Combine
import SwiftUI

// MARK: - AppViewModel

@MainActor
final class AppViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var usage: CodingPlanUsage?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastRefreshedAt: Date?
    @Published var isPopoverShown: Bool = false
    @Published var layoutMode: LayoutMode = .vertical

    // MARK: - Dependencies

    private let apiClient: CodingPlanClient
    private let settingsStore: SettingsStore

    // MARK: - Private

    private var refreshTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        apiClient: CodingPlanClient,
        settingsStore: SettingsStore
    ) {
        self.apiClient = apiClient
        self.settingsStore = settingsStore
        self.layoutMode = settingsStore.layoutMode
    }

    // MARK: - Data Loading

    func loadData() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let fetchedUsage = try await apiClient.fetchUsage()
            self.usage = fetchedUsage
            self.lastRefreshedAt = Date()
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            await loadData()
        }
    }

    // MARK: - Auto Refresh

    func startAutoRefresh() {
        stopAutoRefresh()
        scheduleNextRefresh()
    }

    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func scheduleNextRefresh() {
        let interval = max(settingsStore.refreshInterval, 15)

        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.loadData()
            self?.scheduleNextRefresh()
        }
    }

    // MARK: - Layout

    func toggleLayout() {
        layoutMode = layoutMode == .vertical ? .horizontal : .vertical
        settingsStore.layoutMode = layoutMode
    }

    // MARK: - Open in Browser

    func openArkCodingPlanTray() {
        guard let url = URL(string: UserDefaultsSettingsStore.webURL) else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Deinit

    deinit {
        refreshTask?.cancel()
    }
}
