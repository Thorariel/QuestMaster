import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Profile Card
                profileCard
                    .padding(.vertical, 20)

                // Badges
                Text("成就徽章")
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 12)

                badgeGrid

                Spacer().frame(height: 20)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.themeBG)
    }

    private var profileCard: some View {
        let info = vm.levelInfo

        return VStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.themePrimaryLight, .themePurpleLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Text("🎯")
                    .font(.system(size: 32))
            }

            Text("少侠")
                .font(.system(size: 20, weight: .heavy))

            Text(info.title)
                .font(.system(size: 14))
                .foregroundColor(.themeTextSecondary)

            Text("Lv.\(info.level)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.themePrimary)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(.themeCard)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.default))
        .cardShadow()
    }

    private var badgeGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
            ForEach(Badge.all) { badge in
                let unlocked = badge.check(vm.appState)

                VStack(spacing: 4) {
                    Text(unlocked ? badge.icon : "🔒")
                        .font(.system(size: 28))
                        .saturation(unlocked ? 1 : 0)
                        .opacity(unlocked ? 1 : 0.35)

                    Text(unlocked ? badge.name : "???")
                        .font(.system(size: 10))
                        .foregroundColor(.themeTextSecondary)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
                .background(.themeCard)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.small))
                .cardShadow()
            }
        }
    }
}

#Preview {
    let persistence = PersistenceController.preview
    let vm = AppViewModel(persistence: persistence)
    ProfileView()
        .environmentObject(vm)
}
