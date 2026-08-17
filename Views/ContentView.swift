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

    // MARK: - Tab Bar
    private var tabBar: some View {
        ZStack(alignment: .bottom) {
            // MARK: 背景层：材质铺满整个 tabBar 区域，并延伸到屏幕物理底部
            VStack(spacing: 0) {
                Color.themeBorder.frame(height: 1)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Rectangle()
                    .fill(.regularMaterial)
                    .ignoresSafeArea(edges: .bottom)
            )

            // MARK: 四个 tab 按钮
            HStack(spacing: 0) {
                tabItem(icon: "house.fill", label: "首页", tab: .home)
                tabItem(icon: "list.bullet.clipboard", label: "任务榜", tab: .board)
                Spacer()
                tabItem(icon: "chart.bar.fill", label: "统计", tab: .stats)
                tabItem(icon: "person.fill", label: "个人", tab: .profile)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 2)

            // MARK: + 按钮：用 offset 上移半个按钮高度，tabBar 上边缘正好切在按钮 75% 位置
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
            .offset(y: -26)
        }
        //tabbar高度
        .frame(height: 32)
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
            //任务栏按钮距离
            .padding(.horizontal, 18)
            //任务栏按钮高度
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
