import CoreData
import Foundation

final class CoreDataStack {
    static let shared = CoreDataStack()
    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "MirrorMate")
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved Core Data error: \(error)")
            }
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
    }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do { try context.save() } catch { print("Core Data save error: \(error)") }
        }
    }
}


