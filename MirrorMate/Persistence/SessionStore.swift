import CoreData
import Foundation

@MainActor
final class SessionStore: ObservableObject {
    static let shared = SessionStore()
    private let context: NSManagedObjectContext

    @Published var sessions: [SessionRecord] = []

    init(context: NSManagedObjectContext = CoreDataStack.shared.container.viewContext) {
        self.context = context
        Task { await reload() }
    }

    func reload() async {
        let fetch = NSFetchRequest<SessionEntity>(entityName: "SessionEntity")
        fetch.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        do {
            let items = try context.fetch(fetch)
            self.sessions = items.map { SessionRecord(entity: $0) }
        } catch {
            print("Fetch error: \(error)")
        }
    }

    func saveReport(_ report: AnalysisReport) {
        AppLog.info("💾 Saving report to CoreData for session: \(report.sessionId)", category: .storage)
        
        // Check if report already exists
        let fetchRequest: NSFetchRequest<SessionEntity> = NSFetchRequest(entityName: "SessionEntity")
        fetchRequest.predicate = NSPredicate(format: "sessionId == %@", report.sessionId)
        
        do {
            let existingEntities = try context.fetch(fetchRequest)
            let entity: SessionEntity
            
            if let existing = existingEntities.first {
                AppLog.info("Updating existing report", category: .storage)
                entity = existing
            } else {
                AppLog.info("Creating new report", category: .storage)
                entity = SessionEntity(context: context)
            }
            
            entity.sessionId = report.sessionId
            entity.createdAt = report.createdAt
            entity.confidenceScore = Int16(report.confidenceScore)
            
            // Encode tags
            if let tagsData = try? JSONSerialization.data(withJSONObject: report.impressionTags, options: []) {
                entity.tags = tagsData
            } else {
                AppLog.warning("Failed to encode tags", category: .storage)
            }
            
            // Encode full report with proper date encoder
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let metricsData = try? encoder.encode(report) {
                entity.metrics = metricsData
                AppLog.info("Report metrics encoded: \(metricsData.count) bytes", category: .storage)
            } else {
                AppLog.error("Failed to encode metrics", category: .storage)
            }
            
            CoreDataStack.shared.saveContext()
            AppLog.info("✅ Report saved successfully to CoreData", category: .storage)
            
            Task { await reload() }
        } catch {
            AppLog.error("Failed to save report: \(error.localizedDescription)", category: .storage)
        }
    }
}

struct SessionRecord: Identifiable {
    var id: String { sessionId }
    let sessionId: String
    let createdAt: Date
    let confidenceScore: Int
    let impressionTags: [String]
    let rawReport: AnalysisReport?

    init(entity: SessionEntity) {
        self.sessionId = entity.sessionId ?? UUID().uuidString
        self.createdAt = entity.createdAt ?? Date()
        self.confidenceScore = Int(entity.confidenceScore)
        if let data = entity.tags, let array = try? JSONSerialization.jsonObject(with: data) as? [String] {
            self.impressionTags = array
        } else { self.impressionTags = [] }
        
        // Decode with proper date strategy
        if let metrics = entity.metrics {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let decoded = try? decoder.decode(AnalysisReport.self, from: metrics) {
                self.rawReport = decoded
            } else {
                AppLog.warning("Failed to decode report metrics for session: \(self.sessionId)", category: .storage)
                self.rawReport = nil
            }
        } else {
            self.rawReport = nil
        }
    }
}


