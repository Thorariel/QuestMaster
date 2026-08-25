import SwiftUI

@main
struct QuestMasterApp: App {
    let persistenceController = PersistenceController.shared

    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var viewModel: AppViewModel

    init() {
        let persistence = PersistenceController.shared
        _viewModel = StateObject(wrappedValue: AppViewModel(persistence: persistence))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(viewModel)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.checkDailyReset()
                viewModel.checkDailyBackup()
                viewModel.evaluateTriggers()
            }
        }
    }
}

// Preview helper
struct QuestMasterApp_Previews: PreviewProvider {
    static var previews: some View {
        let persistence = PersistenceController.preview
        let vm = AppViewModel(persistence: persistence)
        ContentView()
            .environment(\.managedObjectContext, persistence.container.viewContext)
            .environmentObject(vm)
    }
}
