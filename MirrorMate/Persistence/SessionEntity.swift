import CoreData
import Foundation

@objc(SessionEntity)
public class SessionEntity: NSManagedObject {
    @NSManaged public var sessionId: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var confidenceScore: Int16
    @NSManaged public var tags: Data?
    @NSManaged public var metrics: Data?
}


