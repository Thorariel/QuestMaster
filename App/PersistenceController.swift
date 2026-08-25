import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        for i in 0..<6 {
            let task = TaskEntity(context: viewContext)
            task.id = "preview_\(i)"
            task.title = sampleTitles[i]
            task.desc = "示例任务描述"
            task.cat = sampleCats[i]
            task.xp = Int32(sampleXPs[i])
            task.done = false
            task.progress = Int32(i * 20)
            task.createdAt = Date()
            task.displayOrder = Int32(i)

            task.isTriggered = true
            task.triggerType = nil
            task.triggerLocation = nil
            task.triggerDate = nil
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Preview error: \(nsError)")
        }

        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "QuestMaster")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Core Data load warning: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

private let sampleTitles = [
    "打通经脉 - 基础修炼",
    "收集草药 - 回春丹材料",
    "夜探藏经阁",
    "日常打坐修炼",
    "拜访各大门派",
    "绘制完整地图",
]

private let sampleCats = ["main", "side", "adventure", "daily", "side", "main"]
private let sampleXPs = [50, 10, 10, 5, 15, 100]
