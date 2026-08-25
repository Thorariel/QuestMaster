import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss

    let task: TaskEntity

    @State private var isEditing = false

    private var cat: TaskCategory { task.wrappedCat }

    private var isTracked: Bool {
        guard task.isTriggered else { return false }
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

                if task.isTriggered {
                    if !task.done { progressSection }
                    actionButtons
                } else {
                    pendingTriggeredView
                }
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

    private var pendingTriggeredView: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                Label("未触发任务", systemImage: "lock.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeText)

                Text("满足触发条件后会自动发布任务")
                    .font(.system(size: 13))
                    .foregroundColor(.themeTextSecondary)

                let summary = TaskTriggerConfig.from(task: task).summary
                if !summary.isEmpty {
                    Text(summary)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.themePrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.themePrimaryLight)
                        .clipShape(Capsule())
                }
            }

            VStack(spacing: 10) {
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

                actionButton(
                    title: "🗑️ 删除",
                    color: .themeBG,
                    textColor: .themeCoral
                ) {
                    vm.deleteTask(task)
                    dismiss()
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
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
    /// 用户目标经验值（不随类别切换而 clamp，保留原始值）
    @State private var originalXP: Double = 10
    /// 当前显示的已收敛经验值（保存时使用）
    @State private var xpValue: Double = 10
    @State private var showTitleError = false
    @State private var showCategoryChangeAlert = false
    @State private var showDailyBlockedAlert = false

    @State private var triggerEnabled = false
    @State private var triggerConfig = TaskTriggerConfig()

    init(task: TaskEntity, isEditing: Binding<Bool>) {
        self.task = task
        self._isEditing = isEditing
        _title = State(initialValue: task.wrappedTitle)
        _desc = State(initialValue: task.wrappedDesc)

        let initialCat = task.wrappedCat
        _selectedCat = State(initialValue: initialCat)

        // 保留任务原始经验值作为基准，不被 clamp 覆盖
        let rawXP = Double(task.xp)
        _originalXP = State(initialValue: rawXP)
        // 显示值收敛到当前类别允许的范围内
        _xpValue = State(initialValue: min(max(rawXP, initialCat.xpRange.lowerBound), initialCat.xpRange.upperBound))

        if initialCat == .daily {
            _triggerConfig = State(initialValue: TaskTriggerConfig())
            _triggerEnabled = State(initialValue: false)
        } else {
            let initialTrigger = TaskTriggerConfig.from(task: task)
            _triggerConfig = State(initialValue: initialTrigger)
            _triggerEnabled = State(initialValue: initialTrigger.type != .none)
        }
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
                                    // 条件触发任务不能改成日常任务
                                    if cat == .daily && triggerEnabled {
                                        showDailyBlockedAlert = true
                                        return
                                    }

                                    selectedCat = cat

                                    // 切换到日常任务时清空触发条件
                                    if cat == .daily {
                                        triggerEnabled = false
                                        triggerConfig = TaskTriggerConfig()
                                    }

                                    // 基于原始目标值重新收敛，避免 clamp 后丢失原始值
                                    xpValue = min(max(originalXP, cat.xpRange.lowerBound), cat.xpRange.upperBound)
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
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // XP Slider
                    formField(label: "经验值") {
                        HStack(spacing: 12) {
                            Slider(
                                value: Binding(
                                    get: { xpValue },
                                    set: { newValue in
                                        // 只有用户手动滑动时更新，同时同步原始目标值
                                        xpValue = newValue
                                        originalXP = newValue
                                    }
                                ),
                                in: selectedCat.xpRange,
                                step: selectedCat.xpStep
                            )
                            .tint(.themePrimary)

                            Text("\(Int(xpValue))")
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundColor(.themePrimary)
                                .frame(minWidth: 40)
                        }
                    }

                    // Trigger condition
                    if selectedCat == .daily {
                        Text("日常任务不支持条件触发")
                            .font(.system(size: 12))
                            .foregroundColor(.themeTextMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        TaskTriggerEditor(
                            enabled: $triggerEnabled,
                            config: $triggerConfig
                        )
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
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .overlay {
            if showCategoryChangeAlert {
                CategoryChangeAlertView(
                    oldCat: task.wrappedCat,
                    newCat: selectedCat,
                    oldXP: Int(task.xp),
                    newXP: Int(xpValue),
                    onCancel: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showCategoryChangeAlert = false
                        }
                    },
                    onConfirm: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showCategoryChangeAlert = false
                        }
                        performSave()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
                .zIndex(1)
            }
        }
        .alert("不可修改", isPresented: $showDailyBlockedAlert) {
            Button("好", role: .cancel) {}
        } message: {
            Text("条件触发任务不能修改为日常任务。")
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

        guard !(selectedCat == .daily && triggerEnabled) else {
            showDailyBlockedAlert = true
            return
        }

        // 如果修改了任务类别，先弹出确认提示
        if selectedCat != task.wrappedCat {
            withAnimation(.easeInOut(duration: 0.15)) {
                showCategoryChangeAlert = true
            }
            return
        }

        performSave()
    }

    private func performSave() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)

        let effectiveTrigger: TaskTriggerConfig

        if selectedCat == .daily {
            effectiveTrigger = TaskTriggerConfig()
        } else {
            effectiveTrigger = triggerEnabled ? triggerConfig : TaskTriggerConfig()
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            vm.updateTask(
                task,
                title: trimmed,
                desc: desc.trimmingCharacters(in: .whitespaces),
                cat: selectedCat,
                xp: Int(xpValue),
                triggerConfig: effectiveTrigger
            )
            isEditing = false
        }
    }
}

// MARK: - 改派确认弹窗
struct CategoryChangeAlertView: View {
    let oldCat: TaskCategory
    let newCat: TaskCategory
    let oldXP: Int
    let newXP: Int
    let onCancel: () -> Void
    let onConfirm: () -> Void

    private var xpChanged: Bool { oldXP != newXP }
    private var capChanged: Bool {
        Int(oldCat.xpRange.upperBound) != Int(newCat.xpRange.upperBound)
    }
    private var xpDecreased: Bool { newXP < oldXP }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 标题区
                VStack(spacing: 4) {
                    Text("⚔️ 任务改派")
                        .font(.system(size: 20, weight: .heavy))
                    Text("此任务将更换类别重新发布，请批准！")
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextSecondary)
                        .padding(.top, 10)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)

                // 变更明细
                VStack(spacing: 8) {
                    changeRow(
                        label: "任务类别",
                        oldValue: "\(oldCat.emoji) \(oldCat.label)",
                        newValue: "\(newCat.emoji) \(newCat.label)"
                    )
                    changeRow(
                        label: "经验值",
                        oldValue: "\(oldXP)",
                        newValue: "\(newXP)",
                        highlight: xpChanged && xpDecreased,
                        suffix: "点"
                    )
                    changeRow(
                        label: "经验上限",
                        oldValue: "\(Int(oldCat.xpRange.upperBound))",
                        newValue: "\(Int(newCat.xpRange.upperBound))",
                        highlight: capChanged && newXP < oldXP,
                        suffix: "点"
                    )
                }
                .padding(12)
                .background(Color.themeBG)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
                .padding(.horizontal, 20)

                // 提示文案
                Text("确认后经验值将按新类别规则计算")
                    .font(.system(size: 12))
                    .foregroundColor(.themeTextMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 14)

                // 按钮
                HStack(spacing: 10) {
                    Button(action: onCancel) {
                        Text("再想想")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.themeTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.themeBG)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraSmall))
                    }

                    Button(action: onConfirm) {
                        Text("确认")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.themePrimary)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraSmall))
                    }
                }
                .padding(20)
            }
            .background(.themeCard)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.default))
            .padding(.horizontal, 32)
        }
    }

    private func changeRow(label: String, oldValue: String, newValue: String, highlight: Bool = false, suffix: String = "") -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.themeTextMuted)
                .frame(width: 56, alignment: .leading)

            Text("\(oldValue)\(suffix)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeTextSecondary)
                .strikethrough()

            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.themeTextMuted)

            Text("\(newValue)\(suffix)")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(highlight ? .themeCoral : .themeText)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.themeCard)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraSmall))
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
