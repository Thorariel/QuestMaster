import Foundation
import CoreData

// MARK: - 备份数据结构

struct TaskBackupItem: Codable {
    let id: String
    let title: String
    let desc: String
    let cat: String
    let xp: Int32
    let done: Bool
    let progress: Int32
    let createdAt: Date?
    let displayOrder: Int32

    // 触发条件字段（旧备份可能没有，故使用 Optional）
    let isTriggered: Bool?
    let triggerType: String?
    let triggerLocation: String?
    let triggerDate: Date?
}

struct BackupFile: Codable {
    let version: Int
    let createdAt: Date
    let appState: AppStateStore
    let tasks: [TaskBackupItem]
}

struct BackupImportSummary {
    let importedTasks: Int
    let skippedTasks: Int
}

// MARK: - 备份错误

enum BackupError: LocalizedError {
    case unreadableFile
    case invalidBackup

    var errorDescription: String? {
        switch self {
        case .unreadableFile:
            return "无法读取所选文件，可能尚未下载到本机，请先在「文件」App 中打开一次。"
        case .invalidBackup:
            return "所选文件不是有效的 QuestMaster 备份文件，或已损坏。"
        }
    }
}

// MARK: - 每日备份管理

enum BackupManager {
    static let backupVersion = 1
    static let backupsDirectoryName = "Backups"
    static let lastBackupDateKey = "com.questmaster.lastBackupDate"
    static let keepDays = 3

    /// 沙盒 Documents/Backups 目录（配合 Info.plist 的 UIFileSharingEnabled，可在「文件」App 的"我的 iPhone"中看到）
    static var backupsDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = documents.appendingPathComponent(backupsDirectoryName, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func filename(for date: Date) -> String {
        "backup-\(date.formatted(.iso8601.year().month().day())).json"
    }

    /// 所有备份文件，按创建时间从新到旧排列
    static var backupFiles: [URL] {
        let urls = (try? FileManager.default.contentsOfDirectory(at: backupsDirectory, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])) ?? []
        return urls
            .filter { $0.pathExtension == "json" }
            .sorted { lhs, rhs in
                let l = (try? lhs.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                let r = (try? rhs.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
                return l > r
            }
    }

    /// 最新的备份文件 URL
    static var latestBackupURL: URL? {
        backupFiles.first
    }

    // MARK: - 生成与写入

    static func makeBackup(context: NSManagedObjectContext, appState: AppStateStore) throws -> BackupFile {
        let request = TaskEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskEntity.createdAt, ascending: false)]
        let tasks = try context.fetch(request)

        let items = tasks.map { task in
            TaskBackupItem(
                id: task.wrappedID,
                title: task.wrappedTitle,
                desc: task.wrappedDesc,
                cat: task.wrappedCat.rawValue,
                xp: task.xp,
                done: task.done,
                progress: task.progress,
                createdAt: task.createdAt,
                displayOrder: task.displayOrder,
                isTriggered: task.isTriggered,
                triggerType: task.triggerType,
                triggerLocation: task.triggerLocation,
                triggerDate: task.triggerDate
            )
        }
        return BackupFile(version: backupVersion, createdAt: Date(), appState: appState, tasks: items)
    }

    /// 写入备份并返回文件 URL
    @discardableResult
    static func write(_ backup: BackupFile) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(backup)

        let url = backupsDirectory.appendingPathComponent(filename(for: backup.createdAt))
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - 读取与导入

    /// 从任意位置（如 iCloud Drive / 文件 App）读取并解码备份文件
    static func loadBackup(from url: URL) throws -> BackupFile {
        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var data: Data?

        coordinator.coordinate(readingItemAt: url, options: [], error: &coordinationError) { readURL in
            data = try? Data(contentsOf: readURL)
        }

        if let coordinationError { throw coordinationError }
        guard let data else { throw BackupError.unreadableFile }
        return try JSONDecoder().decode(BackupFile.self, from: data)
    }

    // MARK: - 每日检查

    static func lastBackupDate() -> String? {
        UserDefaults.standard.string(forKey: lastBackupDateKey)
    }

    static func markBackedUpToday() {
        let today = Date().formatted(date: .numeric, time: .omitted)
        UserDefaults.standard.set(today, forKey: lastBackupDateKey)
    }

    // MARK: - 只保留最近 3 天，清理更早的备份

    static func pruneOldBackups(keep days: Int = keepDays) {
        let fm = FileManager.default
        let urls = (try? fm.contentsOfDirectory(at: backupsDirectory, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles])) ?? []

        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        for url in urls {
            let creationDate = (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? .distantPast
            if creationDate < cutoff {
                try? fm.removeItem(at: url)
            }
        }
    }
}
