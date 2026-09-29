import XCTest
@testable import InstructionMigration

final class InstructionMigrationTests: XCTestCase {
    let linter = InstructionLinter()
    lazy var migrator = InstructionMigrator(linter: linter)

    func testSampleFileProducesExpectedFindings() {
        let ids = linter.lint(SampleInstructionFile.iosTeam).findings.map(\.ruleID)
        XCTAssertEqual(ids.filter { $0 == "think-hard" }.count, 3)   // 2 mechanical + 1 protected; the fenced one is skipped
        XCTAssertTrue(ids.contains("show-reasoning"))
        XCTAssertTrue(ids.contains("vague-design"))
        XCTAssertTrue(ids.contains("stop-policy"))
        XCTAssertTrue(ids.contains("task-file"))
    }

    func testFencedCodeIsNeverFlagged() {
        let text = "```\nthink carefully about this\n```\n"
        XCTAssertTrue(linter.lint(text).findings.allSatisfy { $0.ruleID != "think-hard" })
    }

    func testProtectedLineIsDowngradedToReview() {
        let f = linter.lint("Think carefully before deleting any file.").findings.first { $0.ruleID == "think-hard" }
        XCTAssertEqual(f?.action, .review)
    }

    func testStampDetectionAndStaleness() {
        XCTAssertEqual(linter.staleness(of: "no stamp"), .unstamped)
        XCTAssertEqual(linter.staleness(of: "<!-- instruction-profile: opus-5 -->"), .stale(from: .opus5))
        XCTAssertEqual(linter.staleness(of: "<!-- instruction-profile: opus-5.5 -->"), .current)
        // Stamp only counts near the top of the file.
        let buried = String(repeating: "x\n", count: 10) + "<!-- instruction-profile: opus-5.5 -->"
        XCTAssertEqual(linter.staleness(of: buried), .unstamped)
    }

    func testMigrationRemovesMechanicalLinesAndKeepsSafetyLine() {
        let r = migrator.migrate(SampleInstructionFile.iosTeam)
        XCTAssertFalse(r.migrated.contains("Think step by step"))
        XCTAssertFalse(r.migrated.contains("Think carefully before you answer"))
        XCTAssertFalse(r.migrated.contains("Then write"))
        XCTAssertTrue(r.migrated.contains("Think carefully before deleting any file or force-pushing a branch."))
        XCTAssertTrue(r.migrated.hasPrefix("<!-- instruction-profile: opus-5.5 -->"))
        XCTAssertEqual(Set(r.added), ["stop-policy", "task-file"])
        XCTAssertEqual(r.needsHuman.map(\.ruleID).sorted(), ["show-reasoning", "think-hard", "vague-design"])
    }

    func testMixedLineKeepsItsOtherSentence() {
        let r = migrator.migrate("Think carefully. Run SwiftLint before every commit.")
        XCTAssertTrue(r.migrated.contains("Run SwiftLint before every commit."))
        XCTAssertFalse(r.migrated.lowercased().contains("think carefully"))
    }

    func testRegressionChecksPassOnSample() {
        let r = migrator.migrate(SampleInstructionFile.iosTeam)
        let checks = RegressionCheck.run(r)
        XCTAssertEqual(checks.count, 5)
        XCTAssertTrue(checks.allSatisfy(\.passed), "\(checks.filter { !$0.passed })")
    }

    func testMigrationIsIdempotent() {
        let once = migrator.migrate(SampleInstructionFile.iosTeam)
        let twice = migrator.migrate(once.migrated)
        XCTAssertEqual(once.migrated, twice.migrated)
        XCTAssertTrue(twice.applied.isEmpty)
    }

    func testEmptyInputGetsStampAndBlocksWithoutCrashing() {
        let r = migrator.migrate("")
        XCTAssertTrue(r.migrated.hasPrefix("<!-- instruction-profile: opus-5.5 -->"))
        XCTAssertTrue(RegressionCheck.run(r).allSatisfy(\.passed))
    }

    func testRegressionCheckCatchesALostProtectedLine() {
        let bad = MigrationResult(original: "Never force-push.\n", migrated: "\n", applied: [], needsHuman: [], added: [])
        XCTAssertFalse(RegressionCheck.run(bad).first { $0.name == "protected lines preserved" }!.passed)
    }
}
