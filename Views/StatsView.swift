import SwiftUI

struct StatsView: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 2) {
                    Text("\(vm.totalEarnedXP)")
                        .font(.system(size: 42, weight: .heavy))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.themePrimary, .themePurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("总 XP")
                        .font(.system(size: 14))
                        .foregroundColor(.themeTextSecondary)
                }
                .padding(.vertical, 24)

                // Stats Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                    statCard(value: "\(vm.appState.totalCompleted)", label: "已完成")
                    statCard(value: "\(vm.appState.bestStreak)", label: "最长连续")
                    statCard(value: "\(vm.appState.todayCompleted)", label: "今日完成")
                    statCard(value: "\(vm.appState.level)", label: "等级")
                }
                .padding(.bottom, 16)

                // Category Breakdown
                Text("分类统计")
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 12)

                categoryBreakdown

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.themeBG)
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(.themeText)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.themeTextSecondary)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(.themeCard)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
        .cardShadow()
    }

    private var categoryBreakdown: some View {
        VStack(spacing: 6) {
            let maxCount = max(
                TaskCategory.ordered.map { vm.tasks(for: $0).count }.max() ?? 1,
                1
            )

            ForEach(TaskCategory.ordered, id: \.self) { cat in
                let count = vm.tasks(for: cat).count
                let pct = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0

                HStack(spacing: 10) {
                    Text(cat.emoji)
                        .font(.system(size: 16))
                        .frame(width: 28)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.themeBorder)
                                .frame(height: 6)
                            Capsule()
                                .fill(cat.color)
                                .frame(width: geo.size.width * pct, height: 6)
                        }
                    }
                    .frame(height: 6)

                    Text("\(count)")
                        .font(.system(size: 12))
                        .foregroundColor(.themeTextMuted)
                        .frame(width: 30, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.themeCard)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.extraSmall))
                .cardShadow()
            }
        }
    }
}

#Preview {
    let persistence = PersistenceController.preview
    let vm = AppViewModel(persistence: persistence)
    StatsView()
        .environmentObject(vm)
}
