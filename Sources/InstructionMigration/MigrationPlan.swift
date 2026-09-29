import Foundation

public struct MigrationResult: Equatable, Sendable {
    public let original: String
    public let migrated: String
    public let applied: [Finding]
    public let needsHuman: [Finding]
    public let added: [String]      // rule ids whose block was appended

    public var linesRemoved: Int { Self.count(original) - Self.survivingCount(original, migrated) }
    public var linesAdded: Int { Self.count(migrated) - Self.survivingCount(original, migrated) }

    static func count(_ s: String) -> Int { InstructionLinter.splitLines(s).count }
    static func survivingCount(_ a: String, _ b: String) -> Int {
        var pool = Dictionary(grouping: InstructionLinter.splitLines(b), by: { $0 }).mapValues(\.count)
        var n = 0
        for line in InstructionLinter.splitLines(a) {
            if let c = pool[line], c > 0 { pool[line] = c - 1; n += 1 }
        }
        return n
    }
}

public struct InstructionMigrator: Sendable {
    public let linter: InstructionLinter
    public init(linter: InstructionLinter = InstructionLinter()) { self.linter = linter }

    public func migrate(_ text: String) -> MigrationResult {
        let report = linter.lint(text)
        var lines = InstructionLinter.splitLines(text)
        let rulesByID = Dictionary(uniqueKeysWithValues: linter.rules.map { ($0.id, $0) })

        var applied: [Finding] = []
        var human: [Finding] = []
        var blocks: [(String, String)] = []
        var dropped = Set<Int>()

        for f in report.findings {
            switch f.action {
            case .review:
                human.append(f)
            case .delete:
                guard let ln = f.line, lines.indices.contains(ln - 1),
                      let rule = rulesByID[f.ruleID], case .linePattern(let p) = rule.matcher,
                      let re = try? NSRegularExpression(pattern: p, options: [.caseInsensitive]) else { continue }
                let kept = Self.dropMatchingSentences(lines[ln - 1], re)
                if Self.wordCount(kept) < 3 { dropped.insert(ln - 1) } else { lines[ln - 1] = kept }
                applied.append(f)
            case .add(let block):
                blocks.append((f.ruleID, block))
            }
        }

        var out = lines.enumerated().filter { !dropped.contains($0.offset) }.map(\.element)
        out = Self.stamped(out, with: linter.target)
        while let last = out.last, last.trimmingCharacters(in: .whitespaces).isEmpty { out.removeLast() }
        for (_, block) in blocks {
            out.append("")
            out.append(contentsOf: block.split(separator: "\n", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) })
        }
        return MigrationResult(original: text, migrated: out.joined(separator: "\n") + "\n",
                               applied: applied, needsHuman: human, added: blocks.map(\.0))
    }

    // MARK: helpers

    /// Splits on a terminator followed by whitespace or end of line, so "5.9" and "style.md" stay whole,
    /// and keeps each surviving sentence's original text, terminator included.
    static func dropMatchingSentences(_ line: String, _ re: NSRegularExpression) -> String {
        let bullet = line.prefix { $0 == " " || $0 == "-" || $0 == "*" }
        let body = String(line.dropFirst(bullet.count))
        let survivors = splitSentences(body).filter { !InstructionLinter.matches(re, $0) }
        guard !survivors.isEmpty else { return "" }
        return String(bullet) + survivors.joined(separator: " ")
    }

    static func splitSentences(_ s: String) -> [String] {
        var out: [String] = []
        var current = ""
        let chars = Array(s)
        for (i, c) in chars.enumerated() {
            current.append(c)
            let atEnd = i == chars.count - 1
            if ".!?".contains(c), atEnd || chars[i + 1].isWhitespace {
                let trimmed = current.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { out.append(trimmed) }
                current = ""
            }
        }
        let rest = current.trimmingCharacters(in: .whitespaces)
        if !rest.isEmpty { out.append(rest) }
        return out
    }

    static func wordCount(_ s: String) -> Int {
        let bullet = s.drop { $0 == " " || $0 == "-" || $0 == "*" }
        return bullet.split(whereSeparator: \.isWhitespace).count
    }

    static func stamped(_ lines: [String], with profile: ModelProfile) -> [String] {
        var out = lines
        if let i = out.prefix(5).firstIndex(where: { $0.hasPrefix(ModelProfile.stampPrefix) }) {
            out[i] = profile.stampLine
        } else {
            out.insert(profile.stampLine, at: 0)
        }
        return out
    }
}
