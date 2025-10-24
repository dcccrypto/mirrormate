import Foundation

struct AnalysisReport: Codable, Identifiable {
    var id: String { sessionId }
    let sessionId: String
    let durationSec: Int
    let confidenceScore: Int
    let impressionTags: [String]
    let fillerWords: [String: Int]
    let toneTimeline: [TonePoint]
    let emotionBreakdown: [String: Double]
    let gaze: Gaze
    let feedback: String
    let createdAt: Date
    
    // ENHANCED FIELDS
    let vocalAnalysis: VocalAnalysis?
    let bodyLanguageAnalysis: BodyLanguageAnalysis?
    let strengths: [String]?
    let areasForImprovement: [String]?
    let practiceExercises: [String]?
    let keyMoments: [KeyMoment]?

    struct TonePoint: Codable, Identifiable {
        var id: String { "\(t)" }
        let t: Double
        let energy: Double
        let confidence: Double? // NEW: confidence timeline
    }

    struct Gaze: Codable {
        let eyeContactPct: Double
    }
    
    // NEW: Vocal Analysis
    struct VocalAnalysis: Codable {
        let paceWordsPerMin: Int
        let volumeConsistency: Double
        let tonalVariety: Double
        let clarity: Double
        let pauseEffectiveness: Double
    }
    
    // NEW: Body Language Analysis
    struct BodyLanguageAnalysis: Codable {
        let postureScore: Double
        let gestureNaturalness: Double
        let facialExpressiveness: Double
        let eyeContactPct: Double
        let movementPurpose: Double
    }
    
    // NEW: Key Moments
    struct KeyMoment: Codable, Identifiable {
        var id: String { "\(timestamp)-\(type)" }
        let timestamp: Int
        let type: String // "strength" or "improvement"
        let description: String
    }
    
    // Custom CodingKeys to map from API response
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case durationSec = "duration_sec"
        case confidenceScore = "confidence_score"
        case impressionTags = "impression_tags"
        case fillerWords = "filler_words"
        case toneTimeline = "tone_timeline"
        case emotionBreakdown = "emotion_breakdown"
        case gaze
        case feedback
        case createdAt = "created_at"
        case vocalAnalysis = "vocal_analysis"
        case bodyLanguageAnalysis = "body_language_analysis"
        case strengths
        case areasForImprovement = "areas_for_improvement"
        case practiceExercises = "practice_exercises"
        case keyMoments = "key_moments"
    }
    
    // Regular initializer for creating from code
    init(sessionId: String, durationSec: Int, confidenceScore: Int, impressionTags: [String], fillerWords: [String: Int], toneTimeline: [TonePoint], emotionBreakdown: [String: Double], gaze: Gaze, feedback: String, createdAt: Date, vocalAnalysis: VocalAnalysis? = nil, bodyLanguageAnalysis: BodyLanguageAnalysis? = nil, strengths: [String]? = nil, areasForImprovement: [String]? = nil, practiceExercises: [String]? = nil, keyMoments: [KeyMoment]? = nil) {
        self.sessionId = sessionId
        self.durationSec = durationSec
        self.confidenceScore = confidenceScore
        self.impressionTags = impressionTags
        self.fillerWords = fillerWords
        self.toneTimeline = toneTimeline
        self.emotionBreakdown = emotionBreakdown
        self.gaze = gaze
        self.feedback = feedback
        self.createdAt = createdAt
        self.vocalAnalysis = vocalAnalysis
        self.bodyLanguageAnalysis = bodyLanguageAnalysis
        self.strengths = strengths
        self.areasForImprovement = areasForImprovement
        self.practiceExercises = practiceExercises
        self.keyMoments = keyMoments
    }
    
    // Custom decoding for flexible API responses
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        
        // Handle durationSec as either Int or Double
        if let intValue = try? container.decode(Int.self, forKey: .durationSec) {
            durationSec = intValue
        } else if let doubleValue = try? container.decode(Double.self, forKey: .durationSec) {
            durationSec = Int(doubleValue)
        } else {
            durationSec = 0
        }
        
        confidenceScore = try container.decode(Int.self, forKey: .confidenceScore)
        impressionTags = try container.decode([String].self, forKey: .impressionTags)
        fillerWords = try container.decode([String: Int].self, forKey: .fillerWords)
        toneTimeline = try container.decode([TonePoint].self, forKey: .toneTimeline)
        emotionBreakdown = try container.decode([String: Double].self, forKey: .emotionBreakdown)
        
        // Handle gaze as either nested object or flat percentage
        if let gazeObj = try? container.decode(Gaze.self, forKey: .gaze) {
            gaze = gazeObj
        } else {
            let eyeContactPct = (try? container.decode(Double.self, forKey: .gaze)) ?? 0.0
            gaze = Gaze(eyeContactPct: eyeContactPct)
        }
        
        feedback = try container.decode(String.self, forKey: .feedback)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        // NEW: Decode enhanced fields (optional for backwards compatibility)
        vocalAnalysis = try? container.decode(VocalAnalysis.self, forKey: .vocalAnalysis)
        bodyLanguageAnalysis = try? container.decode(BodyLanguageAnalysis.self, forKey: .bodyLanguageAnalysis)
        strengths = try? container.decode([String].self, forKey: .strengths)
        areasForImprovement = try? container.decode([String].self, forKey: .areasForImprovement)
        practiceExercises = try? container.decode([String].self, forKey: .practiceExercises)
        keyMoments = try? container.decode([KeyMoment].self, forKey: .keyMoments)
    }
    
    // Custom encoding to match the decoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(durationSec, forKey: .durationSec)
        try container.encode(confidenceScore, forKey: .confidenceScore)
        try container.encode(impressionTags, forKey: .impressionTags)
        try container.encode(fillerWords, forKey: .fillerWords)
        try container.encode(toneTimeline, forKey: .toneTimeline)
        try container.encode(emotionBreakdown, forKey: .emotionBreakdown)
        try container.encode(gaze, forKey: .gaze)
        try container.encode(feedback, forKey: .feedback)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(vocalAnalysis, forKey: .vocalAnalysis)
        try container.encodeIfPresent(bodyLanguageAnalysis, forKey: .bodyLanguageAnalysis)
        try container.encodeIfPresent(strengths, forKey: .strengths)
        try container.encodeIfPresent(areasForImprovement, forKey: .areasForImprovement)
        try container.encodeIfPresent(practiceExercises, forKey: .practiceExercises)
        try container.encodeIfPresent(keyMoments, forKey: .keyMoments)
    }
}
