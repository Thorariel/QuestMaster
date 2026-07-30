import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var desc: String = ""
    @State private var selectedCat: TaskCategory = .side
    @State private var xpValue: Double = 25
    @State private var showTitleError = false

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(.themeBorder)
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Text("创建新任务")
                .font(.system(size: 20, weight: .heavy))
                .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 16) {
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
                                    xpValue = Double(cat.defaultXP)
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
                    dismiss()
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
                    createTask()
                } label: {
                    Text("创建")
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
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .background(Color.themeCard)
    }

    private func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.themeTextSecondary)
            content()
        }
    }

    private func createTask() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            showTitleError = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showTitleError = false
            }
            return
        }

        vm.addTask(
            title: trimmed,
            desc: desc.trimmingCharacters(in: .whitespaces),
            cat: selectedCat,
            xp: Int(xpValue)
        )
        dismiss()
    }
}

#Preview {
    let persistence = PersistenceController.preview
    let vm = AppViewModel(persistence: persistence)
    AddTaskView()
        .environmentObject(vm)
}
