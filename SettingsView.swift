//
//  SettingView.swift
//  QuestMaster
//
//  Created by Lei Song on 2026/8/15.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var vm: AppViewModel
    @Binding var showSettings: Bool

    @State private var showFileImporter = false
    @State private var message: String?

    var body: some View {
        VStack(spacing: 0) {
            // 顶部导航：返回 + 标题
            header

            // 内容区
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    backupSection
                    identitySection
                    notificationSection
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color.themeBG)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert(
            "备份导入",
            isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })
        ) {
            Button("好", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }

    // MARK: - 顶部导航
    private var header: some View {
        ZStack {
            HStack {
                Button {
                    showSettings = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                        Text("个人")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.themePrimary)
                    .padding(.vertical, 8)
                    .padding(.trailing, 8)
                }
                Spacer()
            }

            Text("设置")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.themeText)
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    // MARK: - 备份管理
    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("备份管理")

            // 自动备份说明
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.themePrimary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("每日自动备份")
                        .font(.system(size: 14, weight: .semibold))
                    Text("保留最近 \(BackupManager.keepDays) 份，可在「文件」App 的“我的 iPhone”中查看")
                        .font(.system(size: 11))
                        .foregroundColor(.themeTextMuted)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.themeCard)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))

            // 备份文件列表
            let files = BackupManager.backupFiles

            if files.isEmpty {
                Text("暂无备份，每天首次打开 App 会自动生成")
                    .font(.system(size: 13))
                    .foregroundColor(.themeTextMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.themeCard)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
            } else {
                ForEach(files, id: \.self) { url in
                    HStack(spacing: 10) {
                        Image(systemName: "doc.fill")
                            .foregroundColor(.themeTextMuted)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "backup-", with: ""))
                                .font(.system(size: 14, weight: .semibold))
                            Text(fileSizeString(url))
                                .font(.system(size: 11))
                                .foregroundColor(.themeTextMuted)
                        }
                        Spacer()
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.themePrimary)
                        }
                    }
                    .padding(14)
                    .background(Color.themeCard)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
                }
            }

            // 导出最新备份到 iCloud Drive
            if let latest = BackupManager.latestBackupURL {
                ShareLink(item: latest) {
                    Label("导出最新备份到 iCloud Drive", systemImage: "icloud.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.themePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
                }
            }

            // 导入备份
            Button {
                showFileImporter = true
            } label: {
                Label("导入备份", systemImage: "tray.and.arrow.down")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.themePrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.themePrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
            }
        }
    }

    // MARK: - 占位设置项
    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("身份设置")
            settingPlaceholder(icon: "person.crop.circle", title: "身份设置", subtitle: "即将上线")
        }
    }

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("通知")
            settingPlaceholder(icon: "bell.badge", title: "通知", subtitle: "即将上线")
        }
    }

    private func settingPlaceholder(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.themeTextMuted)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.themeText)
            Spacer()
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.themeTextMuted)
        }
        .padding(14)
        .background(Color.themeCard)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(.themeText)
    }

    // MARK: - 导入处理
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let backup = try BackupManager.loadBackup(from: url)
                let summary = try vm.importBackup(backup)
                message = "导入成功！新增 \(summary.importedTasks) 个任务，跳过 \(summary.skippedTasks) 个重复任务。"
            } catch {
                message = "导入失败：\(error.localizedDescription)"
            }
        case .failure(let error):
            message = "导入失败：\(error.localizedDescription)"
        }
    }

    private func fileSizeString(_ url: URL) -> String {
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

#Preview {
    let persistence = PersistenceController.preview
    let vm = AppViewModel(persistence: persistence)
    SettingsView(showSettings: .constant(true))
        .environmentObject(vm)
}
