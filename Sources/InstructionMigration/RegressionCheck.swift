import Foundation

public struct CheckResult: Equatable, Sendable {
    public let name: String
    public let passed: Bool
    public let detail: String
}

/// The "small regression eval" run before a migrated file is rolled out. It does not ask a model
/// anything; it asserts the invariants a migration must never break.
public enum RegressionCheck {
    public static func run(_ result: MigrationResult, linter: InstructionLinter = InstructionLinter()) -> [CheckResult] {
        var checks: [CheckResult] = []

        // 1. Protected lines survive byte-for-byte.
        let origLines = InstructionLinter.splitLines(result.original)
        let newSet = Set(InstructionLinter.splitLines(result.migrated))
        let lost = origLines.filter { InstructionLinter.isProtected($0) && !newSet.contains($0) }
        checks.append(CheckResult(name: "protected lines preserved", passed: lost.isEmpty,
                                  detail: lost.isEmpty ? "every safety-adjacent line survived"
                                                       : "lost: \(lost.joined(separator: " | "))"))

        // 2. Nothing mechanical is left, and no absence rule still fires.
        let after = linter.lint(result.migrated)
        let leftovers = after.findings.filter { $0.action == .delete || { if case .add = $0.action { return true }; return false }($0) }
        checks.append(CheckResult(name: "no mechanical findings remain", passed: leftovers.isEmpty,
                                  detail: leftovers.isEmpty ? "second lint pass is quiet on mechanical rules"
                                                            : leftovers.map(\.ruleID).joined(separator: ", ")))

        // 3. Stamp is current.
        checks.append(CheckResult(name: "model stamp current", passed: after.staleness == .current,
                                  detail: "\(after.staleness)"))

        // 4. Fenced code is untouched.
        let fenced = { (s: String) -> [String] in
            let lines = InstructionLinter.splitLines(s)
            let mask = InstructionLinter.fenceMask(lines)
            return zip(lines, mask).filter { $0.1 }.map(\.0)
        }
        checks.append(CheckResult(name: "fenced code untouched", passed: fenced(result.original) == fenced(result.migrated),
                                  detail: "code fences are examples, never edited"))

        // 5. Idempotent.
        let again = InstructionMigrator(linter: linter).migrate(result.migrated)
        checks.append(CheckResult(name: "idempotent", passed: again.migrated == result.migrated,
                                  detail: "migrating the output changes nothing"))
        return checks
    }
}
