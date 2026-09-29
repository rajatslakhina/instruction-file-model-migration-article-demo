import Foundation

/// Rules for moving an instruction file from Opus 5 habits to Opus 5.5.
/// Source: Addy Osmani, "Getting the most out of Opus 5.5 in Claude and Claude Code",
/// claude.dev, 22 Sep 2026. Each rationale paraphrases one section of that playbook.
public enum OpusRules {
    public static let thinkLines = Rule(
        id: "think-hard",
        title: "\"Think carefully\" line",
        matcher: .linePattern(#"\bthink\s+(very\s+)?(carefully|hard|deeply|step[\s-]by[\s-]step)\b"#),
        severity: .warning,
        action: .delete,
        rationale: "The model thinks before every reply and decides how much itself; the playbook says to delete these lines."
    )

    public static let showReasoning = Rule(
        id: "show-reasoning",
        title: "Asks for reasoning to be reproduced in the reply",
        matcher: .linePattern(#"\b(show|reproduce|print|reveal|include)\s+(your\s+)?(full\s+)?(internal\s+)?(reasoning|chain[\s-]of[\s-]thought|thinking)\b"#),
        severity: .error,
        action: .review,
        rationale: "The playbook lists requests to reproduce internal reasoning as a flag category. Replace with \"explain why you chose this in three sentences\" (human decision)."
    )

    public static let vagueDesign = Rule(
        id: "vague-design",
        title: "Vague design instruction",
        matcher: .linePattern(#"\bavoid\s+(a\s+)?(generic|bland|boring)\b"#),
        severity: .warning,
        action: .review,
        rationale: "A general \"avoid generic\" swaps one default for another; the playbook says to name the specific patterns to leave out."
    )

    public static let stopPolicy = Rule(
        id: "stop-policy",
        title: "No stop/continue policy",
        matcher: .absent(#"\bstop\s+and\s+ask\b"#),
        severity: .warning,
        action: .add(block: """
            ## Stops
            When a step doesn't need my input, keep going. Put status notes in the same message as your next action.
            Stop and ask only when you can't continue without me, or before anything destructive: deleting data, force-pushing, or changing anything outside this repository.
            """),
        rationale: "Long runs otherwise pause to offer \"want me to continue?\". The playbook says to name the stops you want."
    )

    public static let taskFile = Rule(
        id: "task-file",
        title: "Task list not kept in a file",
        matcher: .absent(#"\bTASKS\.md\b|\bchecklist\s+in\b"#),
        severity: .info,
        action: .add(block: """
            ## Long runs
            Keep a checklist in TASKS.md. Tick each item when it's done, and add anything new you find.
            """),
        rationale: "A list in a file survives context compaction; scrollback does not."
    )

    public static let all: [Rule] = [thinkLines, showReasoning, vagueDesign, stopPolicy, taskFile]
}
