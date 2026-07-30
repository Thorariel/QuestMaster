import Foundation
import CoreData

extension TaskEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TaskEntity> {
        return NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var desc: String?
    @NSManaged public var cat: String?
    @NSManaged public var xp: Int32
    @NSManaged public var done: Bool
    @NSManaged public var progress: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var displayOrder: Int32

    var wrappedID: String { id ?? UUID().uuidString }
    var wrappedTitle: String { title ?? "" }
    var wrappedDesc: String { desc ?? "" }
    var wrappedCat: TaskCategory { TaskCategory(rawValue: cat ?? "side") ?? .side }
    var wrappedCreatedAt: Date { createdAt ?? Date() }
}

extension TaskEntity: Identifiable {

}
