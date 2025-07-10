import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()

    let container: NSPersistentContainer

    var context: NSManagedObjectContext {
        container.viewContext
    }

    private init() {
        container = NSPersistentContainer(name: "Meal_Planner")

        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                fatalError("Unresolved error loading CoreData: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error saving CoreData: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func delete(_ object: NSManagedObject) {
        context.delete(object)
        saveContext()
    }
}
