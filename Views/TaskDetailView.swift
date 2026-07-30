import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss

    let task: TaskEntity

    private var cat: TaskCategory { task.wrappedCat }

    private var isTracked: Bool {
        if task.wrappedCat == .daily {
            return vm.appState.trackedDailyIDs.contains(task.wrappedID)
        }
        return vm.appState.focusQuestID == task.wrappedID
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(.themeBorder)
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    categoryTag
                    titleSection
                    descriptionSection
                    infoRow
                    if !task.done { progressSection }
                    actionButtons
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .background(Color.themeCard)
    }

    private var categoryTag: some View {
        Text("\(cat.emoji) \(cat.label)")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(cat.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(cat.lightColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var titleSection: some View {
        Text(task.wrappedTitle)
            .font(.system(size: 22, weight: .heavy))
    }

    private var descriptionSection: some View {
        Text(task.wrappedDesc.isEmpty ? "\(cat.emoji) \(cat.label)任务" : task.wrappedDesc)
            .font(.system(size: 14))
            .foregroundColor(.themeTextSecondary)
            .lineSpacing(4)
    }

    private var infoRow: some View {
        HStack(spacing: 12) {
            infoItem(value: "+\(task.xp)", label: "经验值")
            infoItem(value: "\(task.progress)%", label: "进度")
            infoItem(value: cat.label, label: "类别")
        }
    }

    private func infoItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.themeText)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.themeTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.themeBG)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraSmall))
    }

    private var progressSection: some View {
        VStack(spacing: 4) {
            HStack {
                Text("进度")
                    .font(.system(size: 12))
                    .foregroundColor(.themeTextMuted)
                Spacer()
                Text("\(task.progress)%")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(cat.color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.themeBorder)
                        .frame(height: 6)
                    Capsule()
                        .fill(cat.color)
                        .frame(width: geo.size.width * CGFloat(task.progress) / 100.0, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private var actionButtons: some View {
        Group {
            if task.done {
                HStack(spacing: 10) {
                    actionButton(title: "✅ 已完成", color: .themeBorder, textColor: .themeTextMuted) {
                        vm.toggleDone(task)
                        dismiss()
                    }
                    actionButton(title: "🗑️ 删除", color: .themeBG, textColor: .themeCoral, flex: 0.5) {
                        vm.deleteTask(task)
                        dismiss()
                    }
                }
            } else {
                HStack(spacing: 10) {
                    actionButton(
                        title: task.progress >= 75 ? "✅ 完成任务" : "▶ 推进进度",
                        color: task.progress >= 75 ? .themeSecondary : .themePrimary,
                        textColor: .white
                    ) {
                        vm.advanceProgress(task)
                        if task.done { dismiss() }
                    }
                    actionButton(
                        title: isTracked ? "📍 已追踪" : "📍 追踪",
                        color: isTracked ? .themeBorder : .themePrimary,
                        textColor: isTracked ? .themeTextMuted : .white,
                        flex: 0.7
                    ) {
                        vm.toggleTracking(task)
                    }
                    actionButton(
                        title: "🗑️",
                        color: .themeBG,
                        textColor: .themeCoral,
                        flex: 0.4
                    ) {
                        vm.deleteTask(task)
                        dismiss()
                    }
                }
            }
        }
    }

    private func actionButton(title: String, color: Color, textColor: Color, flex: CGFloat = 1, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraSmall))
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    let persistence = PersistenceController.preview
    let vm = AppViewModel(persistence: persistence)
    if let task = vm.tasks.first {
        TaskDetailView(task: task)
            .environmentObject(vm)
    } else {
        Text("No tasks")
    }
}
