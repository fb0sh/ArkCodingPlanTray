import Foundation

// MARK: - CodingPlanAPI

protocol CodingPlanAPI: Sendable {
    func fetchUsage() async throws -> CodingPlanUsage
    func testConnection() async throws -> Bool
}

// MARK: - CodingPlanClient

final class CodingPlanClient: CodingPlanAPI, @unchecked Sendable {
    private let session: URLSession
    private let secureStore: SecureStore
    private let decoder: JSONDecoder

    /// Cached cookie to avoid repeated Keychain access (which triggers password prompts)
    private var cachedCookie: String?

    init(secureStore: SecureStore) {
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieAcceptPolicy = .never
        config.httpShouldSetCookies = false
        config.waitsForConnectivity = false
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30

        self.session = URLSession(configuration: config)
        self.secureStore = secureStore
        self.decoder = JSONDecoder()

        // Preload cookie from Keychain once on init
        self.cachedCookie = secureStore.loadCookie()
    }

    /// Reload cookie from Keychain (call after saving a new cookie in settings)
    func reloadCookie() {
        cachedCookie = secureStore.loadCookie()
    }

    private var requestBuilder: APIRequestBuilder {
        APIRequestBuilder(
            baseURL: UserDefaultsSettingsStore.baseURL,
            cookie: cachedCookie
        )
    }

    // MARK: - CodingPlanAPI

    func fetchUsage() async throws -> CodingPlanUsage {
        let body = "{}".data(using: .utf8)
        let request = try requestBuilder.buildRequest(path: UserDefaultsSettingsStore.apiPath, method: "POST", body: body)
        let data = try await performRequest(request)
        let response = try decoder.decode(CodingPlanResponse.self, from: data)

        if let error = response.responseMetadata.error {
            throw APIError.decodingFailed(error.message)
        }

        guard let result = response.result else {
            throw APIError.invalidResponse
        }

        return result
    }

    // MARK: - Test Connection

    func testConnection() async throws -> Bool {
        let body = "{}".data(using: .utf8)
        let request = try requestBuilder.buildRequest(path: UserDefaultsSettingsStore.apiPath, method: "POST", body: body)
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Volcengine API returns 200 even on auth errors — check body
        guard let decoded = try? decoder.decode(CodingPlanResponse.self, from: data) else {
            // Response isn't JSON — likely a redirect to login page (bad cookie)
            let bodyPreview = String(data: data.prefix(200), encoding: .utf8) ?? ""
            if bodyPreview.contains("login") || bodyPreview.contains("signin") {
                throw APIError.unauthorized
            }
            throw APIError.invalidResponse
        }

        if let apiError = decoded.responseMetadata.error {
            throw APIError.decodingFailed(apiError.message)
        }

        return decoded.result != nil
    }

    // MARK: - Private

    private func performRequest(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        default:
            throw APIError.invalidResponse
        }
    }
}
