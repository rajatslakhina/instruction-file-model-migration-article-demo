import SwiftUI

@main
struct DemoApp: App {
    @StateObject private var viewModel = MigrationDemoViewModel()

    var body: some Scene {
        WindowGroup {
            MigrationDemoView(viewModel: viewModel)
        }
    }
}
