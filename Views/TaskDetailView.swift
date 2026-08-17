import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss

    let task: TaskEntity

    @State private var isEditing = false

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

            if isEditing {
                TaskEditFormView(
                    task: task,
                    isEditing: $isEditing
                )
            } else {
                detailContent
            }
        }
        .presentationDetents(isEditing ? [.large] : [.medium, .large])
        .presentationDragIndicator(.hidden)
        .background(Color.themeCard)
    }

    private var detailContent: some View {
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
        VStack(spacing: 10) {
            // 编辑按钮
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isEditing = true
                }
            } label: {
                Label("编辑任务", systemImage: "pencil")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.themePrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraSmall))
            }
            .buttonStyle(ScaleButtonStyle())

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

// MARK: - Task Edit Form
struct TaskEditFormView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss

    let task: TaskEntity
    @Binding var isEditing: Bool

    @State private var title: String = ""
    @State private var desc: String = ""
    @State private var selectedCat: TaskCategory = .side
    @State private var xpValue: Double = 25
    @State private var showTitleError = false

    init(task: TaskEntity, isEditing: Binding<Bool>) {
        self.task = task
        self._isEditing = isEditing
        _title = State(initialValue: task.wrappedTitle)
        _desc = State(initialValue: task.wrappedDesc)
        _selectedCat = State(initialValue: task.wrappedCat)
        _xpValue = State(initialValue: Double(task.xp))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // 编辑标题
                    Text("编辑任务")
                        .font(.system(size: 20, weight: .heavy))
                        .padding(.bottom, 4)

                    // Title field
                    formField(label: "任务名称") {
                        TextField("输入任务名称...", text: $title)
                            .font(.system(size: 15))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.themeBG)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraSmall))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.extraSmall)
                                    .stroke(showTitleError ? Color.themeCoral : Color.themeBorder, lineWidth: 2)
                            )
                    }

                    // Description field
                    formField(label: "描述（可选）") {
                        TextField("任务描述...", text: $desc)
                            .font(.system(size: 15))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.themeBG)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraSmall))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.extraSmall)
                                    .stroke(Color.themeBorder, lineWidth: 2)
                            )
                    }

                    // Category picker
                    formField(label: "任务类别") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                            ForEach(TaskCategory.allCases, id: \.self) { cat in
                                Button {
                                    selectedCat = cat
                                } label: {
                                    HStack(spacing: 8) {
                                        Text(cat.emoji)
                                            .font(.system(size: 18))
                                        Text(cat.label)
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(selectedCat == cat ? cat.color : .themeText)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppRadius.extraSmall)
                                            .stroke(selectedCat == cat ? cat.color : Color.themeBorder, lineWidth: 2)
                                    )
                                    .background(
                                        selectedCat == cat ? cat.lightColor : Color.themeBG
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraSmall))
                                }
                            }
                        }
                    }

                    // XP Slider
                    formField(label: "经验值") {
                        HStack(spacing: 12) {
                            Slider(value: $xpValue, in: 5...100, step: 5)
                                .tint(.themePrimary)

                            Text("\(Int(xpValue))")
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundColor(.themePrimary)
                                .frame(minWidth: 40)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            // Action buttons
            HStack(spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing = false
                    }
                } label: {
                    Text("取消")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.themeTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.themeBG)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraSmall))
                }

                Button {
                    saveTask()
                } label: {
                    Text("保存")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.themePrimary)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraSmall))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    private func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.themeTextSecondary)
            content()
        }
    }

    private func saveTask() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            showTitleError = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showTitleError = false
            }
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            vm.updateTask(
                task,
                title: trimmed,
                desc: desc.trimmingCharacters(in: .whitespaces),
                cat: selectedCat,
                xp: Int(xpValue)
            )
            isEditing = false
        }
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
