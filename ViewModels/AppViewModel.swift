import Foundation
import CoreData
import SwiftUI
import OSLog

@MainActor
class AppViewModel: ObservableObject {
    // MARK: - Logger
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.questmaster.QuestMaster", category: "TaskOperations")

    let persistence: PersistenceController
    var viewContext: NSManagedObjectContext { persistence.container.viewContext }

    @Published var appState: AppStateStore {
        didSet { appState.save() }
    }

    @Published var tasks: [TaskEntity] = []

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        self.appState = AppStateStore.load()
        loadTasks()
        checkDailyReset()
    }

    func loadTasks() {
        let request = TaskEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskEntity.displayOrder, ascending: true),
            NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)
        ]
        do {
            tasks = try viewContext.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            tasks = []
        }
    }

    // MARK: - Daily Reset
    func checkDailyReset() {
        let today = Date().formatted(date: .numeric, time: .omitted)
        if appState.lastActiveDate != today {
            // Reset daily quests
            let request = TaskEntity.fetchRequest()
            request.predicate = NSPredicate(format: "cat == %@", "daily")
            if let dailies = try? viewContext.fetch(request) {
                for task in dailies {
                    task.done = false
                    task.progress = 0
                }
                try? viewContext.save()
            }
            appState.todayCompleted = 0

            // Streak logic
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let yesterdayStr = yesterday.formatted(date: .numeric, time: .omitted)
            if appState.lastActiveDate == yesterdayStr {
                appState.currentStreak += 1
            } else if appState.lastActiveDate != today {
                appState.currentStreak = 1
            }
            if appState.currentStreak > appState.bestStreak {
                appState.bestStreak = appState.currentStreak
            }
            appState.lastActiveDate = today
            appState.save()
            loadTasks()
        }
    }

    // MARK: - Task CRUD
    func addTask(title: String, desc: String = "", cat: TaskCategory, xp: Int, progress: Int = 0) {
        let task = TaskEntity(context: viewContext)
        task.id = UUID().uuidString
        task.title = title
        task.desc = desc
        task.cat = cat.rawValue
        task.xp = Int32(xp)
        task.done = false
        task.progress = Int32(progress)
        task.createdAt = Date()
        task.displayOrder = Int32(tasks.count)
        saveContext()
        loadTasks()
        logger.info("添加任务: id=\(task.wrappedID), title=\(task.wrappedTitle), category=\(cat.rawValue), xp=\(xp)")
    }

    func toggleDone(_ task: TaskEntity) {
        task.done.toggle()
        if task.done {
            task.progress = 100
            let earnedXP = Int(task.xp)
            appState.addXP(earnedXP)

            let entry = HistoryEntry(
                id: UUID().uuidString,
                questID: task.wrappedID,
                title: task.wrappedTitle,
                xp: earnedXP,
                cat: task.wrappedCat.rawValue,
                completedAt: Date()
            )
            appState.history.append(entry)

            // Clear focus / tracking
            if appState.focusQuestID == task.wrappedID {
                appState.focusQuestID = nil
            }
            appState.trackedDailyIDs.removeAll { $0 == task.wrappedID }

            appState.save()
            logger.info("完成任务: id=\(task.wrappedID), title=\(task.wrappedTitle), desc=\(task.wrappedDesc), earnedXP=\(earnedXP)")
        } else {
            task.progress = 0
            logger.info("取消完成: id=\(task.wrappedID), title=\(task.wrappedTitle)")
        }
        saveContext()
        loadTasks()
    }

    func advanceProgress(_ task: TaskEntity, by amount: Int32 = 25) {
        guard !task.done else { return }
        task.progress = min(100, task.progress + amount)
        if task.progress >= 100 {
            toggleDone(task)
        } else {
            saveContext()
            loadTasks()
            logger.info("推进进度: id=\(task.wrappedID), title=\(task.wrappedTitle), desc=\(task.wrappedDesc), progress=\(task.progress)/100")
        }
    }

    func deleteTask(_ task: TaskEntity) {
        let id = task.wrappedID
        let title = task.wrappedTitle
        if appState.focusQuestID == id { appState.focusQuestID = nil }
        appState.trackedDailyIDs.removeAll { $0 == id }
        viewContext.delete(task)
        saveContext()
        loadTasks()
        logger.info("删除任务: id=\(id), title=\(title)")
    }

    func moveTask(_ task: TaskEntity, to newCat: TaskCategory) {
        let oldCat = task.wrappedCat
        task.cat = newCat.rawValue
        if appState.focusQuestID == task.wrappedID && newCat == .daily {
            appState.focusQuestID = nil
            if !appState.trackedDailyIDs.contains(task.wrappedID) {
                appState.trackedDailyIDs.insert(task.wrappedID, at: 0)
                if appState.trackedDailyIDs.count > 3 {
                    appState.trackedDailyIDs = Array(appState.trackedDailyIDs.prefix(3))
                }
            }
        }
        if oldCat == .daily && newCat != .daily {
            appState.trackedDailyIDs.removeAll { $0 == task.wrappedID }
            appState.focusQuestID = task.wrappedID
        }
        saveContext()
        loadTasks()
        logger.info("移动任务: id=\(task.wrappedID), title=\(task.wrappedTitle), from=\(oldCat.rawValue), to=\(newCat.rawValue)")
    }

    func toggleTracking(_ task: TaskEntity) {
        let id = task.wrappedID
        if task.wrappedCat == .daily {
            if appState.trackedDailyIDs.contains(id) {
                appState.trackedDailyIDs.removeAll { $0 == id }
                logger.info("取消跟踪日常: id=\(id), title=\(task.wrappedTitle)")
            } else {
                appState.trackedDailyIDs.insert(id, at: 0)
                if appState.trackedDailyIDs.count > 3 {
                    appState.trackedDailyIDs = Array(appState.trackedDailyIDs.prefix(3))
                }
                logger.info("跟踪日常: id=\(id), title=\(task.wrappedTitle)")
            }
        } else {
            if appState.focusQuestID == id {
                appState.focusQuestID = nil
                logger.info("取消聚焦任务: id=\(id), title=\(task.wrappedTitle)")
            } else {
                appState.focusQuestID = id
                logger.info("聚焦任务: id=\(id), title=\(task.wrappedTitle)")
            }
        }
        appState.save()
    }

    func toggleCollapsed(_ cat: String) {
        if appState.collapsedCategories.contains(cat) {
            appState.collapsedCategories.removeAll { $0 == cat }
        } else {
            appState.collapsedCategories.append(cat)
        }
        appState.save()
    }

    // MARK: - Computed
    func tasks(for cat: TaskCategory, includeDone: Bool = true) -> [TaskEntity] {
        if includeDone {
            return tasks.filter { $0.wrappedCat == cat }
        }
        return tasks.filter { $0.wrappedCat == cat && !$0.done }
    }

    var dailyTasks: [TaskEntity] { tasks(for: .daily) }
    var mainTasks: [TaskEntity] { tasks(for: .main) }
    var sideTasks: [TaskEntity] { tasks(for: .side) }
    var adventureTasks: [TaskEntity] { tasks(for: .adventure) }

    var activeTasks: [TaskEntity] { tasks.filter { !$0.done } }

    /// 专注任务：优先返回手动聚焦的任务（若有），否则返回第一个活跃的主线任务或第一个活跃的非日常任务。
    var focusTask: TaskEntity? {
        if let id = appState.focusQuestID,
           let task = tasks.first(where: { $0.wrappedID == id && !$0.done }) {
            return task
        }
        // Fallback: first active main task, or any active non-daily task
        return tasks.first(where: { !$0.done && $0.wrappedCat == .main })
            ?? tasks.first(where: { !$0.done && $0.wrappedCat != .daily })
    }

    var trackedDailies: [TaskEntity] {
        let tracked = appState.trackedDailyIDs
            .compactMap { id in tasks.first(where: { $0.wrappedID == id && $0.wrappedCat == .daily }) }
        let others = tasks.filter { $0.wrappedCat == .daily && !$0.done && !appState.trackedDailyIDs.contains($0.wrappedID) }
            .sorted { ($0.createdAt ?? Date()) < ($1.createdAt ?? Date()) }
        return Array((tracked + others).prefix(3))
    }

    var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        switch h {
        case 0..<6: return "夜深了 🌙"
        case 6..<9: return "早上好 🌤️"
        case 9..<12: return "上午好 ☀️"
        case 12..<14: return "中午好 🌞"
        case 14..<18: return "下午好 ⛅"
        case 18..<21: return "傍晚好 🌆"
        default: return "晚上好 🌙"
        }
    }

    var activeCount: Int { activeTasks.count }

    var levelInfo: (level: Int, title: String, subtitle: String) {
        let info = levelTitles.first { $0.level == appState.level } ?? levelTitles.last!
        return (appState.level, info.title, info.subtitle)
    }

    var totalEarnedXP: Int {
        appState.history.reduce(0) { $0 + $1.xp }
    }

    /// 判断某个任务是否正在被追踪（日常任务看 trackedDailyIDs，非日常任务看 focusQuestID）
    func isTracking(_ task: TaskEntity) -> Bool {
        if task.wrappedCat == .daily {
            return appState.trackedDailyIDs.contains(task.wrappedID)
        } else {
            return appState.focusQuestID == task.wrappedID
        }
    }

    // MARK: - Private
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Save error: \(error)")
        }
    }
}
