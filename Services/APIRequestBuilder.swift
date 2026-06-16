import Foundation

// MARK: - APIRequestBuilder

struct APIRequestBuilder: Sendable {
    private let baseURL: String
    private let cookie: String?

    init(baseURL: String, cookie: String?) {
        self.baseURL = baseURL
        self.cookie = cookie
    }

    func buildRequest(path: String, method: String = "POST", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(UserDefaultsSettingsStore.webURL, forHTTPHeaderField: "Referer")
        request.setValue("ArkCodingPlanTray/1.0 (macOS)", forHTTPHeaderField: "User-Agent")
        request.setValue("zh", forHTTPHeaderField: "accept-language")
        request.timeoutInterval = 15

        // Cookie
        if let cookie = cookie, !cookie.isEmpty {
            request.setValue(cookie, forHTTPHeaderField: "Cookie")
        }

        // Auto-extract csrfToken from cookie and set as x-csrf-token header
        if let csrfToken = extractCsrfToken(from: cookie) {
            request.setValue(csrfToken, forHTTPHeaderField: "x-csrf-token")
        }

        if let body = body {
            request.httpBody = body
        }

        return request
    }

    /// Extract csrfToken value from the Cookie string
    private func extractCsrfToken(from cookie: String?) -> String? {
        guard let cookie = cookie else { return nil }
        // Pattern: csrfToken=xxxxx; or csrfToken=xxxxx at end
        let pattern = #"csrfToken=([^;\s]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: cookie, range: NSRange(cookie.startIndex..., in: cookie)) else {
            return nil
        }
        let range = Range(match.range(at: 1), in: cookie)
        return range.map { String(cookie[$0]) }
    }
}
