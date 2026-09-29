import Foundation

public enum Staleness: Equatable, Sendable {
    case unstamped
    case stale(from: ModelProfile)
    case current
}

public struct LintReport: Equatable, Sendable {
    public let findings: [Finding]
    public let staleness: Staleness

    public var isClean: Bool { findings.isEmpty && staleness == .current }
    public func count(_ s: Severity) -> Int { findings.filter { $0.severity == s }.count }
}

public struct InstructionLinter: Sendable {
    public let rules: [Rule]
    public let target: ModelProfile

    public init(rules: [Rule] = OpusRules.all, target: ModelProfile = .opus55) {
        self.rules = rules
        self.target = target
    }

    /// Words that make a line safety-adjacent. A line containing one of these is never edited
    /// mechanically: a matching `.delete` rule is downgraded to `.review`.
    static let protectedTerms = ["delet", "force-push", "force push", "destructive", "drop table",
                                 "rm -rf", "production", "secret", "credential"]

    static func isProtected(_ line: String) -> Bool {
        let l = line.lowercased()
        return protectedTerms.contains { l.contains($0) }
    }

    public func lint(_ text: String) -> LintReport {
        let lines = Self.splitLines(text)
        let inFence = Self.fenceMask(lines)
        var findings: [Finding] = []

        for rule in rules {
            switch rule.matcher {
            case .linePattern(let pattern):
                guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
                for (i, line) in lines.enumerated() where !inFence[i] && !line.hasPrefix(ModelProfile.stampPrefix) {
                    guard Self.matches(re, line) else { continue }
                    var action = rule.action
                    if action == .delete, Self.isProtected(line) { action = .review }
                    findings.append(Finding(ruleID: rule.id, title: rule.title, line: i + 1,
                                            excerpt: line.trimmingCharacters(in: .whitespaces),
                                            severity: rule.severity, action: action, rationale: rule.rationale))
                }
            case .absent(let pattern):
                guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
                let present = lines.enumerated().contains { !inFence[$0.offset] && Self.matches(re, $0.element) }
                if !present {
                    findings.append(Finding(ruleID: rule.id, title: rule.title, line: nil, excerpt: "",
                                            severity: rule.severity, action: rule.action, rationale: rule.rationale))
                }
            }
        }
        return LintReport(findings: findings, staleness: staleness(of: text))
    }

    public func staleness(of text: String) -> Staleness {
        guard let stamp = ModelProfile.stamp(in: text) else { return .unstamped }
        return stamp.rank < target.rank ? .stale(from: stamp) : .current
    }

    // MARK: helpers

    static func splitLines(_ text: String) -> [String] {
        text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    }

    /// true for every line that sits inside a ``` fence (fence lines included).
    static func fenceMask(_ lines: [String]) -> [Bool] {
        var open = false
        return lines.map { line in
            let isFence = line.trimmingCharacters(in: .whitespaces).hasPrefix("```")
            if isFence { open.toggle(); return true }
            return open
        }
    }

    static func matches(_ re: NSRegularExpression, _ s: String) -> Bool {
        re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil
    }
}
