import Foundation

public enum Severity: Int, Comparable, Sendable {
    case info = 0, warning, error
    public static func < (a: Severity, b: Severity) -> Bool { a.rawValue < b.rawValue }
}

public enum RuleAction: Equatable, Sendable {
    /// Mechanical, safe to apply: strip the matched phrase.
    case delete
    /// Content is ambiguous or safety-adjacent; a human must decide.
    case review
    /// The file is missing something; append `block`.
    case add(block: String)
}

/// A rule is data: an id, a matcher, a rationale that cites the vendor guidance it came from.
public struct Rule: Sendable {
    public enum Matcher: Sendable {
        /// Fires on every line matching the regex (case-insensitive).
        case linePattern(String)
        /// Fires once when NO line of the file matches the regex.
        case absent(String)
    }

    public let id: String
    public let title: String
    public let matcher: Matcher
    public let severity: Severity
    public let action: RuleAction
    public let rationale: String

    public init(id: String, title: String, matcher: Matcher, severity: Severity,
                action: RuleAction, rationale: String) {
        self.id = id; self.title = title; self.matcher = matcher
        self.severity = severity; self.action = action; self.rationale = rationale
    }
}

public struct Finding: Equatable, Sendable {
    public let ruleID: String
    public let title: String
    /// 1-based. `nil` for absence findings, which belong to the whole file.
    public let line: Int?
    public let excerpt: String
    public let severity: Severity
    public let action: RuleAction
    public let rationale: String
}
