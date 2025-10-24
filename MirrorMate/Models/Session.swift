import Foundation

struct InitSessionResponse: Codable {
    let sessionId: String
    let uploadUrl: String
    let uploadPath: String?
    let uploadToken: String?
    let expiresAt: String
    
    var uploadUrlAsURL: URL? {
        URL(string: uploadUrl)
    }
    
    var expiresAtDate: Date? {
        ISO8601DateFormatter().date(from: expiresAt)
    }
}

struct FinalizeResponse: Codable {
    let status: String
}

struct StatusResponse: Codable {
    enum State: String, Codable { case queued, processing, complete, error }
    let status: String
    let progress: Double

    var state: State {
        State(rawValue: status) ?? .queued
    }
}


