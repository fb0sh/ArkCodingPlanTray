import Foundation

// MARK: - APIError

enum APIError: Error, LocalizedError, Sendable {
    case unauthorized
    case forbidden
    case invalidResponse
    case decodingFailed(String)
    case network(Error)
    case invalidURL
    case unknown

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized — please check your credentials"
        case .forbidden:
            return "Forbidden — you don't have access"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingFailed(let detail):
            return "Failed to decode response: \(detail)"
        case .network(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidURL:
            return "Invalid URL — please check your Base URL setting"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
