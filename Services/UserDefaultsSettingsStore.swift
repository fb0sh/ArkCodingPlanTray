import Foundation

// MARK: - SettingsStore

protocol SettingsStore: AnyObject, Sendable {
    var refreshInterval: TimeInterval { get set }
    var layoutMode: LayoutMode { get set }
}

enum LayoutMode: String, Codable, Sendable {
    case vertical
    case horizontal
}

// MARK: - UserDefaultsSettingsStore

final class UserDefaultsSettingsStore: SettingsStore, @unchecked Sendable {
    private let defaults: UserDefaults
    private let suiteName = "com.fb0sh.ArkCodingPlanTray"

    private enum Keys {
        static let refreshInterval = "refresh_interval"
        static let layoutMode = "layout_mode"
    }

    static let baseURL = "https://console.volcengine.com"
    static let apiPath = "/api/top/ark/cn-beijing/2024-01-01/GetCodingPlanUsage"
    static let webURL = "https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement"

    init() {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
        registerDefaults()
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Keys.refreshInterval: 60.0,
            Keys.layoutMode: LayoutMode.vertical.rawValue
        ])
    }

    var refreshInterval: TimeInterval {
        get { defaults.double(forKey: Keys.refreshInterval) }
        set { defaults.set(newValue, forKey: Keys.refreshInterval) }
    }

    var layoutMode: LayoutMode {
        get {
            let raw = defaults.string(forKey: Keys.layoutMode) ?? LayoutMode.vertical.rawValue
            return LayoutMode(rawValue: raw) ?? .vertical
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.layoutMode) }
    }
}
