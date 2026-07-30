import SwiftUI

enum AppTab: String {
    case home, board, stats, profile
}

struct ContentView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var selectedTab: AppTab = .home
    @State private var showAddSheet = false
    @State private var detailTask: TaskEntity? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Status bar area
            statusBar

            // Main content
            ZStack {
                Color.themeBG.ignoresSafeArea()

                TabView(selection: $selectedTab) {
                    HomeView(detailTask: $detailTask)
                        .tag(AppTab.home)

                    BoardView(detailTask: $detailTask)
                        .tag(AppTab.board)

                    StatsView()
                        .tag(AppTab.stats)

                    ProfileView()
                        .tag(AppTab.profile)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            // Tab bar
            tabBar
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showAddSheet) {
            AddTaskView()
        }
        .sheet(item: $detailTask) { task in
            TaskDetailView(task: task)
        }
    }

    // MARK: - Status Bar
    private var statusBar: some View {
        HStack {
            Text(Date(), style: .time)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.themeText)
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "wifi")
                    .font(.system(size: 11))
                Image(systemName: "battery.100")
                    .font(.system(size: 12))
            }
            .foregroundColor(.themeText)
        }
        .padding(.horizontal, 28)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color.themeBG)
    }

    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            tabItem(icon: "house.fill", label: "首页", tab: .home)
            tabItem(icon: "list.bullet.clipboard", label: "任务榜", tab: .board)
            Spacer()
            tabItem(icon: "chart.bar.fill", label: "统计", tab: .stats)
            tabItem(icon: "person.fill", label: "个人", tab: .profile)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 20)
        .padding(.top, 8)
        .background(
            .regularMaterial,
            in: Rectangle()
        )
        .overlay(alignment: .top) {
            Color.themeBorder.frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            // Add button
            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(.themePrimary)
                            .shadow(color: .themePrimary.opacity(0.35), radius: 8, x: 0, y: 4)
                    )
            }
            .offset(y: -38)
        }
    }

    private func tabItem(icon: String, label: String, tab: AppTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(selectedTab == tab ? .themePrimary : .themeTextMuted)
                Text(label)
                    .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .medium))
                    .foregroundColor(selectedTab == tab ? .themePrimary : .themeTextMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }
}

#Preview {
    let persistence = PersistenceController.preview
    let vm = AppViewModel(persistence: persistence)
    ContentView()
        .environment(\.managedObjectContext, persistence.container.viewContext)
        .environmentObject(vm)
}
