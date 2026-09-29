import Foundation

/// The model generation an instruction file (CLAUDE.md and friends) is written for.
/// The stamp lives in the file itself so "which model was this tuned for?" is answerable by grep.
public struct ModelProfile: Equatable, Hashable, Sendable {
    public let id: String
    public let rank: Int

    public init(id: String, rank: Int) {
        self.id = id
        self.rank = rank
    }

    public static let opus5 = ModelProfile(id: "opus-5", rank: 5_0)
    public static let opus55 = ModelProfile(id: "opus-5.5", rank: 5_5)

    static let known: [ModelProfile] = [.opus5, .opus55]

    public static func named(_ id: String) -> ModelProfile? {
        known.first { $0.id == id.lowercased() }
    }

    static let stampPrefix = "<!-- instruction-profile:"

    /// Reads `<!-- instruction-profile: opus-5 -->` from the first 5 lines only.
    public static func stamp(in text: String) -> ModelProfile? {
        for line in text.split(separator: "\n", omittingEmptySubsequences: false).prefix(5) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix(stampPrefix), trimmed.hasSuffix("-->") else { continue }
            let body = trimmed.dropFirst(stampPrefix.count).dropLast(3)
            return named(body.trimmingCharacters(in: .whitespaces))
        }
        return nil
    }

    public var stampLine: String { "\(Self.stampPrefix) \(id) -->" }
}
