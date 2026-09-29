import SwiftUI
import InstructionMigration

@MainActor
final class MigrationDemoViewModel: ObservableObject {
    @Published var text = SampleInstructionFile.iosTeam
    @Published private(set) var result: MigrationResult?
    @Published private(set) var checks: [CheckResult] = []

    private let migrator = InstructionMigrator()

    var report: LintReport { migrator.linter.lint(text) }

    func migrate() {
        let r = migrator.migrate(text)
        result = r
        checks = RegressionCheck.run(r)
    }

    func adopt() {
        guard let r = result else { return }
        text = r.migrated
        result = nil
        checks = []
    }

    func reset() {
        text = SampleInstructionFile.iosTeam
        result = nil
        checks = []
    }
}
