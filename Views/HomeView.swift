import SwiftUI

struct HomeView: View {
    @EnvironmentObject var vm: AppViewModel
    @Binding var detailTask: TaskEntity?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                header
                    .padding(.top, 8)

                // Level Card
                levelCard
                    .padding(.vertical, 16)

                // Focus Quest
                if let focus = vm.focusTask {
                    sectionLabel(title: "专注任务", count: nil)
                    focusCard(task: focus)
                }

                // Daily Quests
                sectionLabel(
                    title: "日常任务",
                    count: "\(vm.trackedDailies.filter { $0.done }.count)/\(vm.trackedDailies.count)"
                )
                dailyQuestList

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.themeBG)
    }

    // MARK: - Header
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.greeting)
                    .font(.system(size: 24, weight: .heavy))
                Text("还有 \(vm.activeCount) 个任务等着你")
                    .font(.system(size: 14))
                    .foregroundColor(.themeTextSecondary)
            }
            Spacer()

            // XP Chip
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                Text("\(vm.appState.xp)")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.themeGoldDark)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.themeGoldLight)
            .clipShape(Capsule())
        }
    }

    // MARK: - Level Card
    private var levelCard: some View {
        let info = vm.levelInfo
        let needed = xpForLevel(info.level)

        return ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.themePrimary, Color(hex: 0x7C6FD4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                HStack {
                    HStack(spacing: 10) {
                        Text("\(info.level)")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
                            .background(.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 1) {
                            Text(info.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            Text(info.subtitle)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(vm.totalEarnedXP)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("总XP")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                // XP Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.white.opacity(0.2))
                            .frame(height: 6)
                        Capsule()
                            .fill(.white)
                            .frame(width: geo.size.width * min(1, CGFloat(vm.appState.xp) / CGFloat(needed)), height: 6)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.default))
    }

    // MARK: - Focus Card
    private func focusCard(task: TaskEntity) -> some View {
        let cat = task.wrappedCat
        let pct = Int(task.progress)
        let remaining = Int(ceil(Double(100 - pct) / 25.0))

        return VStack(alignment: .leading, spacing: 8) {
            // 点击卡片信息部分弹出详情
            Button {
                detailTask = task
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(cat.emoji) \(cat.label)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(cat.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(cat.lightColor)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        Spacer()
                    }

                    Text(task.wrappedTitle)
                        .font(.system(size: 17, weight: .bold))

                    Text("+\(task.xp) XP · \(task.done ? "已完成" : "进行中")")
                        .font(.system(size: 13))
                        .foregroundColor(.themeTextSecondary)

                    HStack(spacing: 10) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.themeBorder)
                                    .frame(height: 6)
                                Capsule()
                                    .fill(cat.color)
                                    .frame(width: geo.size.width * CGFloat(task.progress) / 100.0, height: 6)
                            }
                        }
                        .frame(height: 6)

                        Text("\(pct)%")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.themeTextSecondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // 继续任务按钮保持独立
            Button {
                vm.advanceProgress(task)
            } label: {
                Text(pct >= 75 ? "✅ 完成任务" : "▶ 继续任务 (x\(remaining))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.themePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraSmall))
            }
        }
        .padding(18)
        .background(Color.themeCard)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.default))
        .cardShadow()
        .padding(.bottom, 16)
    }

    // MARK: - Daily Quest List
    private var dailyQuestList: some View {
        VStack(spacing: 8) {
            if vm.trackedDailies.isEmpty {
                Text("✨ 暂无日常任务，创建一个吧")
                    .font(.system(size: 14))
                    .foregroundColor(.themeTextMuted)
                    .padding(.vertical, 24)
            } else {
                ForEach(vm.trackedDailies) { task in
                    dailyItem(task: task)
                }
            }
        }
    }

    private func dailyItem(task: TaskEntity) -> some View {
        HStack(spacing: 12) {
            // Check circle - 只有点击这个圆圈才会完成/取消完成
            Button {
                if !task.done {
                    vm.toggleDone(task)
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(task.done ? Color.clear : Color.themeBorder, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if task.done {
                        Circle()
                            .fill(Color.themeSecondary)
                            .frame(width: 24, height: 24)
                        Image(systemName: "check")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 24, height: 24)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.done ? "取消完成" : "完成任务")

            // 点击卡片其余部分直接弹出详情（与任务列表页一致）
            Button {
                detailTask = task
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(task.wrappedTitle)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(task.done ? .themeTextMuted : .themeText)
                            .strikethrough(task.done)

                        Text("\(task.wrappedCat.emoji) \(task.wrappedCat.label)")
                            .font(.system(size: 12))
                            .foregroundColor(.themeTextMuted)
                    }

                    Spacer()

                    Text("+\(task.xp)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.themeGoldDark)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.themeCard)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
        .cardShadow()
    }

    // MARK: - Helpers
    private func sectionLabel(title: String, count: String?) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .bold))
            Spacer()
            if let count = count {
                Text(count)
                    .font(.system(size: 13))
                    .foregroundColor(.themeTextMuted)
            }
        }
        .padding(.bottom, 12)
    }
}

#Preview {
    let persistence = PersistenceController.preview
    let vm = AppViewModel(persistence: persistence)
    HomeView(detailTask: .constant(nil))
        .environmentObject(vm)
}
