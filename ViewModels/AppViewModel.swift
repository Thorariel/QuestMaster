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
        checkDailyBackup()
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
        syncAutoTracking()
    }

    // MARK: - 自动追踪同步
    /// 把首页自动展示的专注任务/日常任务写入追踪状态，
    /// 确保与任务详情页的追踪状态始终一致。
    private func syncAutoTracking() {
        var changed = false

        // 1. 若没有聚焦任务，自动聚焦第一个活跃主线任务或活跃非日常任务
        if appState.focusQuestID == nil,
           let autoFocus = tasks.first(where: { !$0.done && $0.wrappedCat == .main })
               ?? tasks.first(where: { !$0.done && $0.wrappedCat != .daily }) {
            appState.focusQuestID = autoFocus.wrappedID
            changed = true
        }

        // 2. 若追踪的日常不足 3 个，自动补充活跃的日常任务
        if appState.trackedDailyIDs.count < 3 {
            let trackedIDs = Set(appState.trackedDailyIDs)
            let candidates = tasks
                .filter { $0.wrappedCat == .daily && !$0.done && !trackedIDs.contains($0.wrappedID) }
                .sorted { ($0.createdAt ?? Date()) < ($1.createdAt ?? Date()) }
            let needed = 3 - appState.trackedDailyIDs.count
            for task in candidates.prefix(needed) {
                appState.trackedDailyIDs.append(task.wrappedID)
                changed = true
            }
        }

        if changed {
            appState.save()
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

    // MARK: - Daily Backup
    func checkDailyBackup() {
        let today = Date().formatted(date: .numeric, time: .omitted)
        guard BackupManager.lastBackupDate() != today else { return }
        do {
            let backup = try BackupManager.makeBackup(context: viewContext, appState: appState)
            try BackupManager.write(backup)
            BackupManager.markBackedUpToday()
            BackupManager.pruneOldBackups()
            logger.info("每日备份完成，共 \(backup.tasks.count) 个任务")
        } catch {
            logger.error("每日备份失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 导入备份

    /// 导入备份：恢复玩家状态（覆盖当前存档），合并任务（按 id 跳过已存在的）
    func importBackup(_ backup: BackupFile) throws -> BackupImportSummary {
        appState = backup.appState

        let request = TaskEntity.fetchRequest()
        let existingTasks = try viewContext.fetch(request)
        let existingIDs = Set(existingTasks.compactMap { $0.id })

        var imported = 0
        for item in backup.tasks {
            guard !existingIDs.contains(item.id) else { continue }
            let task = TaskEntity(context: viewContext)
            task.id = item.id
            task.title = item.title
            task.desc = item.desc
            task.cat = item.cat
            task.xp = item.xp
            task.done = item.done
            task.progress = item.progress
            task.createdAt = item.createdAt
            task.displayOrder = item.displayOrder
            imported += 1
        }

        saveContext()
        loadTasks()
        logger.info("导入备份: 新增 \(imported) 个任务, 跳过 \(backup.tasks.count - imported) 个重复任务")

        return BackupImportSummary(importedTasks: imported, skippedTasks: backup.tasks.count - imported)
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

    func updateTask(_ task: TaskEntity, title: String, desc: String, cat: TaskCategory, xp: Int) {
        let oldCat = task.wrappedCat
        task.title = title
        task.desc = desc
        task.cat = cat.rawValue
        task.xp = Int32(xp)

        // 类别变化时同步追踪状态，避免首页与详情页不一致
        if oldCat != cat {
            if cat == .daily {
                // 进入日常：清除聚焦，并加入日常追踪
                if appState.focusQuestID == task.wrappedID {
                    appState.focusQuestID = nil
                }
                if !appState.trackedDailyIDs.contains(task.wrappedID) {
                    appState.trackedDailyIDs.insert(task.wrappedID, at: 0)
                    if appState.trackedDailyIDs.count > 3 {
                        appState.trackedDailyIDs = Array(appState.trackedDailyIDs.prefix(3))
                    }
                }
            } else {
                // 离开日常：移除日常追踪，并设为聚焦任务
                appState.trackedDailyIDs.removeAll { $0 == task.wrappedID }
                appState.focusQuestID = task.wrappedID
            }
            appState.save()
        }

        saveContext()
        loadTasks()
        logger.info("编辑任务: id=\(task.wrappedID), title=\(title), category=\(cat.rawValue), xp=\(xp)")
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

    /// 专注任务：以 appState 记录的聚焦状态为准（自动聚焦已在 loadTasks 时同步）
    var focusTask: TaskEntity? {
        guard let id = appState.focusQuestID else { return nil }
        return tasks.first(where: { $0.wrappedID == id && !$0.done })
    }

    /// 日常任务：以 appState 记录的追踪状态为准（自动补充已在 loadTasks 时同步）
    var trackedDailies: [TaskEntity] {
        appState.trackedDailyIDs.compactMap { id in
            tasks.first(where: { $0.wrappedID == id && $0.wrappedCat == .daily })
        }
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
