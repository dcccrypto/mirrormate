import Foundation
import Sentry

final class ApiClient {
    static let shared = ApiClient()
    private init() {}

    private let baseURL = URL(string: SupabaseConfig.url)!

    private let jsonDecoder: JSONDecoder = {
        let d = JSONDecoder()
        // Supabase returns dates in format: "2025-10-18 23:29:56.836233+00"
        // which is not standard ISO8601, so we need a custom decoder
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 first (with 'T' separator)
            let iso8601Formatter = ISO8601DateFormatter()
            iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso8601Formatter.date(from: dateString) {
                return date
            }
            
            // Try Supabase/Postgres format (with space separator and +00 timezone)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSXXXXX"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Fallback: try without fractional seconds
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ssXXXXX"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date from string: \(dateString)")
        }
        return d
    }()

    private let jsonEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    func initSession(maxDurationSec: Int, deviceId: String) async throws -> InitSessionResponse {
        // Get auth token if user is signed in
        let authToken: String
        if let session = try? await SupabaseService.shared.client.auth.session {
            authToken = session.accessToken
            AppLog.info("Initializing session with authenticated user: \(session.user.id)", category: .analysis)
        } else {
            authToken = SupabaseConfig.anonKey
            AppLog.info("Initializing session with device: \(deviceId)", category: .analysis)
        }
        
        let url = baseURL.appendingPathComponent("/functions/v1/init-session")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        
        let payload: [String: Any] = [
            "maxDurationSec": maxDurationSec,
            "deviceId": deviceId
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        AppLog.logRequest(req, category: .network)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        AppLog.logResponse(resp, data: data, error: nil, category: .network)
        try Self.throwIfBad(resp)
        
        do {
            let response = try jsonDecoder.decode(InitSessionResponse.self, from: data)
            AppLog.info("✓ Session created: \(response.sessionId)", category: .analysis)
            return response
        } catch {
            let responseString = String(data: data, encoding: .utf8) ?? "<no data>"
            AppLog.error("Failed to decode InitSessionResponse: \(error)", category: .network)
            AppLog.error("Response body: \(responseString)", category: .network)
            
            // Capture error in Sentry
            SentrySDK.capture(error: error)
            throw error
        }
    }

    func finalize(sessionId: String) async throws -> FinalizeResponse {
        AppLog.info("Finalizing session: \(sessionId)", category: .analysis)
        
        let url = baseURL.appendingPathComponent("/functions/v1/finalize-session")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        
        let payload = ["sessionId": sessionId]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        AppLog.logRequest(req, category: .network)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        AppLog.logResponse(resp, data: data, error: nil, category: .network)
        try Self.throwIfBad(resp)
        
        let response = try jsonDecoder.decode(FinalizeResponse.self, from: data)
        AppLog.info("✓ Session finalized: \(response.status)", category: .analysis)
        return response
    }

    func status(sessionId: String) async throws -> StatusResponse {
        let url = baseURL.appendingPathComponent("/rest/v1/sessions")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "id", value: "eq.\(sessionId)"),
            URLQueryItem(name: "select", value: "status,progress")
        ]
        
        var req = URLRequest(url: components.url!)
        req.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        try Self.throwIfBad(resp)
        
        // Supabase returns array; take first element
        let sessions = try jsonDecoder.decode([StatusResponse].self, from: data)
        guard let session = sessions.first else {
            AppLog.error("No session found for ID: \(sessionId)", category: .analysis)
            let error = URLError(.badServerResponse)
            SentrySDK.capture(error: error)
            throw error
        }
        
        AppLog.debug("Session status: \(session.status) (\(Int(session.progress * 100))%)", category: .analysis)
        return session
    }

    func report(sessionId: String) async throws -> AnalysisReport {
        AppLog.info("Fetching analysis report for session: \(sessionId)", category: .analysis)
        
        let url = baseURL.appendingPathComponent("/rest/v1/analysis_reports")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "session_id", value: "eq.\(sessionId)"),
            URLQueryItem(name: "select", value: "*")
        ]
        
        var req = URLRequest(url: components.url!)
        req.addValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.addValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        
        AppLog.logRequest(req, category: .network)
        
        let (data, resp) = try await URLSession.shared.data(for: req)
        AppLog.logResponse(resp, data: data, error: nil, category: .network)
        try Self.throwIfBad(resp)
        
        // Supabase returns array; take first element and map to AnalysisReport
        let reports = try jsonDecoder.decode([SupabaseAnalysisReport].self, from: data)
        guard let report = reports.first else {
            AppLog.error("No report found for session: \(sessionId)", category: .analysis)
            let error = URLError(.badServerResponse)
            SentrySDK.capture(error: error)
            throw error
        }
        
        AppLog.info("✓ Analysis report received: confidence=\(report.confidence_score)", category: .analysis)
        return report.toAnalysisReport()
    }
    
    private struct SupabaseAnalysisReport: Codable {
        let session_id: String
        let confidence_score: Int
        let impression_tags: [String]
        let filler_words: [String: Int]
        let tone_timeline: [AnalysisReport.TonePoint]
        let emotion_breakdown: [String: Double]
        let gaze_eye_contact_pct: Double
        let feedback: String
        let created_at: Date
        let duration_sec: Int?
        
        // ENHANCED FIELDS
        let vocal_analysis: AnalysisReport.VocalAnalysis?
        let body_language_analysis: AnalysisReport.BodyLanguageAnalysis?
        let strengths: [String]?
        let areas_for_improvement: [String]?
        let practice_exercises: [String]?
        let key_moments: [AnalysisReport.KeyMoment]?
        
        func toAnalysisReport() -> AnalysisReport {
            AnalysisReport(
                sessionId: session_id,
                durationSec: duration_sec ?? 0,
                confidenceScore: confidence_score,
                impressionTags: impression_tags,
                fillerWords: filler_words,
                toneTimeline: tone_timeline,
                emotionBreakdown: emotion_breakdown,
                gaze: AnalysisReport.Gaze(eyeContactPct: gaze_eye_contact_pct),
                feedback: feedback,
                createdAt: created_at,
                vocalAnalysis: vocal_analysis,
                bodyLanguageAnalysis: body_language_analysis,
                strengths: strengths,
                areasForImprovement: areas_for_improvement,
                practiceExercises: practice_exercises,
                keyMoments: key_moments
            )
        }
    }

    static func throwIfBad(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let error = URLError(.badServerResponse)
            SentrySDK.capture(error: error)
            throw error
        }
    }
}


