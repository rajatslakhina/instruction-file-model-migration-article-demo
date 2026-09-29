import SwiftUI
import InstructionMigration

struct MigrationDemoView: View {
    @ObservedObject var viewModel: MigrationDemoViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("CLAUDE.md") {
                    TextEditor(text: $viewModel.text)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 170)
                }
                Section(header: Text("Findings (\(viewModel.report.findings.count))"),
                        footer: Text(stalenessText)) {
                    ForEach(Array(viewModel.report.findings.enumerated()), id: \.offset) { _, f in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(f.title).font(.subheadline.bold())
                                Spacer()
                                Text(actionLabel(f.action)).font(.caption2.bold())
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(color(f.action).opacity(0.2), in: Capsule())
                            }
                            Text(f.line.map { "line \($0): \(f.excerpt)" } ?? "whole file")
                                .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                    }
                }
                if let r = viewModel.result {
                    Section("Migration: \(r.applied.count) auto-fixed, \(r.needsHuman.count) for a human, +\(r.added.count) blocks") {
                        ForEach(viewModel.checks, id: \.name) { c in
                            Label(c.name, systemImage: c.passed ? "checkmark.circle.fill" : "xmark.octagon.fill")
                                .foregroundStyle(c.passed ? .green : .red)
                                .font(.caption)
                        }
                        Button("Adopt migrated file") { viewModel.adopt() }
                    }
                }
            }
            .navigationTitle("Instruction Migration")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Migrate to Opus 5.5") { viewModel.migrate() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") { viewModel.reset() }
                }
            }
        }
    }

    private var stalenessText: String {
        switch viewModel.report.staleness {
        case .unstamped: return "No model stamp."
        case .stale(let p): return "Written for \(p.id); target is opus-5.5."
        case .current: return "Stamp is current."
        }
    }

    private func actionLabel(_ a: RuleAction) -> String {
        switch a { case .delete: return "AUTO"; case .review: return "HUMAN"; case .add: return "ADD" }
    }

    private func color(_ a: RuleAction) -> Color {
        switch a { case .delete: return .blue; case .review: return .orange; case .add: return .green }
    }
}
