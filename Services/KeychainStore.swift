import Foundation
import Security

// MARK: - SecureStore

protocol SecureStore: Sendable {
    func save(key: String, value: String) throws
    func load(key: String) -> String?
    func delete(key: String)

    func saveCookie(_ cookie: String) throws
    func loadCookie() -> String?
    func deleteCookie()
}

// MARK: - KeychainStore

final class KeychainStore: SecureStore, @unchecked Sendable {
    private let service = "com.fb0sh.ArkCodingPlanTray"

    func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        // Delete existing item first
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Convenience

    func saveCookie(_ cookie: String) throws {
        try save(key: "cookie", value: cookie)
    }

    func loadCookie() -> String? {
        load(key: "cookie")
    }

    func deleteCookie() {
        delete(key: "cookie")
    }
}

// MARK: - KeychainError

enum KeychainError: Error, LocalizedError {
    case encodingFailed
    case saveFailed(OSStatus)
    case readFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data"
        case .saveFailed(let status):
            return "Failed to save to Keychain (OSStatus: \(status))"
        case .readFailed(let status):
            return "Failed to read from Keychain (OSStatus: \(status))"
        }
    }
}
