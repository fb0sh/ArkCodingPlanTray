import Foundation

// MARK: - CodingPlanUsage

struct CodingPlanUsage: Codable, Sendable {
    let status: String
    let updateTimestamp: TimeInterval
    let quotaUsage: [QuotaUsage]

    enum CodingKeys: String, CodingKey {
        case status = "Status"
        case updateTimestamp = "UpdateTimestamp"
        case quotaUsage = "QuotaUsage"
    }
}

// MARK: - QuotaUsage

struct QuotaUsage: Codable, Identifiable, Sendable {
    let level: String
    let percent: Double
    let resetTimestamp: TimeInterval

    enum CodingKeys: String, CodingKey {
        case level = "Level"
        case percent = "Percent"
        case resetTimestamp = "ResetTimestamp"
    }

    var id: String { level }

    var displayName: String {
        switch level {
        case "session": return "Session"
        case "weekly": return "Weekly"
        case "monthly": return "Monthly"
        default: return level.capitalized
        }
    }

    var resetDate: Date {
        Date(timeIntervalSince1970: resetTimestamp)
    }
}

// MARK: - CodingPlanResponse

struct CodingPlanResponse: Codable, Sendable {
    let responseMetadata: ResponseMetadata
    let result: CodingPlanUsage?

    enum CodingKeys: String, CodingKey {
        case responseMetadata = "ResponseMetadata"
        case result = "Result"
    }
}

// MARK: - ResponseMetadata

struct ResponseMetadata: Codable, Sendable {
    let requestId: String
    let action: String
    let version: String
    let service: String
    let region: String
    let error: ResponseError?

    enum CodingKeys: String, CodingKey {
        case requestId = "RequestId"
        case action = "Action"
        case version = "Version"
        case service = "Service"
        case region = "Region"
        case error = "Error"
    }
}

// MARK: - ResponseError

struct ResponseError: Codable, Sendable {
    let codeN: Int
    let code: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case codeN = "CodeN"
        case code = "Code"
        case message = "Message"
    }
}
