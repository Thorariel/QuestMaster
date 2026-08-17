import SwiftUI

struct BoardView: View {
    @EnvironmentObject var vm: AppViewModel
    @Binding var detailTask: TaskEntity?
    @State private var selectedFilter: BoardFilter = .all

    enum BoardFilter: String, CaseIterable {
        case all = "all"
        case main = "main"
        case side = "side"
        case adventure = "adventure"
        case daily = "daily"

        var label: String {
            switch self {
            case .all: return "全部"
            case .main: return "主线"
            case .side: return "支线"
            case .adventure: return "奇遇"
            case .daily: return "日常"
            }
        }

        var category: TaskCategory? {
            switch self {
            case .all: return nil
            case .main: return .main
            case .side: return .side
            case .adventure: return .adventure
            case .daily: return .daily
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter tabs
            filterTabs
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

            // Content
            ScrollView(showsIndicators: false) {
                if selectedFilter == .all {
                    allCategoriesView
                } else {
                    singleCategoryView
                }
            }
            .background(Color.themeBG)
        }
        .background(Color.themeBG)
    }

    // MARK: - Filter Tabs
    private var filterTabs: some View {
        HStack(spacing: 4) {
            ForEach(BoardFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedFilter = filter
                    }
                } label: {
                    HStack(spacing: 4) {
                        if let cat = filter.category {
                            Circle()
                                .fill(cat.color)
                                .frame(width: 6, height: 6)
                        }
                        Text(filter.label)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(selectedFilter == filter ? .themeText : .themeTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selectedFilter == filter ? .white : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(color: selectedFilter == filter ? .black.opacity(0.06) : .clear, radius: 2)
                }
            }
        }
        .padding(3)
        .background(.themeBorder)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraSmall))
    }

    // MARK: - All Categories (Collapsible)
    private var allCategoriesView: some View {
        let hasQuests = TaskCategory.allCases.contains { !vm.tasks(for: $0, includeDone: false).isEmpty }

        return VStack(spacing: 10) {
            if !hasQuests {
                Text("✨ 所有任务都已完成，太棒了！")
                    .font(.system(size: 14))
                    .foregroundColor(.themeTextMuted)
                    .padding(.vertical, 40)
            }

            ForEach(TaskCategory.ordered, id: \.self) { cat in
                let tasks = vm.tasks(for: cat, includeDone: false)
                categorySection(cat: cat, tasks: tasks)
            }

            Spacer().frame(height: 20)
        }
        .padding(.horizontal, 20)
    }

    private func categorySection(cat: TaskCategory, tasks: [TaskEntity]) -> some View {
        let isCollapsed = vm.appState.collapsedCategories.contains(cat.rawValue)

        return VStack(spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    vm.toggleCollapsed(cat.rawValue)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.themeTextMuted)
                        .rotationEffect(.degrees(isCollapsed ? 0 : 90))

                    Text("\(cat.emoji) \(cat.label)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(cat.color)

                    Spacer()

                    Text("\(tasks.count)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(cat.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                        .background(cat.lightColor)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }

            if !isCollapsed {
                VStack(spacing: 0) {
                    if tasks.isEmpty {
                        Text("暂无任务")
                            .font(.system(size: 13))
                            .foregroundColor(.themeTextMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        ForEach(tasks) { task in
                            questCard(task: task)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.themeCard)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
    }

    // MARK: - Single Category View
    private var singleCategoryView: some View {
        let cat = selectedFilter.category!
        let allTasks = vm.tasks(for: cat)

        return VStack(spacing: 10) {
            if allTasks.isEmpty {
                Text("✨ 暂无任务，创建一个吧")
                    .font(.system(size: 14))
                    .foregroundColor(.themeTextMuted)
                    .padding(.vertical, 40)
            } else {
                ForEach(allTasks) { task in
                    questCard(task: task, showDone: true)
                }
            }
            Spacer().frame(height: 20)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Quest Card
    private func questCard(task: TaskEntity, showDone: Bool = false) -> some View {
        let cat = task.wrappedCat

        return Button {
            detailTask = task
        } label: {
            VStack(spacing: 6) {
                HStack(alignment: .top) {
                    Text(task.wrappedTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.themeText)
                    Spacer()
                    Text("+\(task.xp)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(cat.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(cat.lightColor)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                Text(task.wrappedDesc.isEmpty ? "\(cat.emoji) \(cat.label)任务" : task.wrappedDesc)
                    .font(.system(size: 13))
                    .foregroundColor(.themeTextSecondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text(task.done ? "✅ 已完成" : "\(cat.emoji) \(cat.label)")
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextMuted)
                    Spacer()
                    if task.progress > 0 && !task.done {
                        Text("\(task.progress)%")
                            .font(.system(size: 12))
                            .foregroundColor(.themeTextMuted)
                    }
                }
            }
            .padding(16)
            .background(.themeCard)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
            .opacity(task.done ? 0.65 : 1.0)
        }
    }
}

#Preview {
    let persistence = PersistenceController.preview
    let vm = AppViewModel(persistence: persistence)
    BoardView(detailTask: .constant(nil))
        .environmentObject(vm)
}
