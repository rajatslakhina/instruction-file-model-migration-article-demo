# InstructionMigration

A small Swift library that lints and migrates agent instruction files (CLAUDE.md and friends) between model generations, built for the article **"Your CLAUDE.md Is Full of Lines Opus 5.5 Doesn't Need. Version It Like Code."**

Article: (added after publish)

Rules come from Addy Osmani's [Getting the most out of Opus 5.5 in Claude and Claude Code](https://claude.dev/blog/getting-the-most-out-of-opus-5-5/) (claude.dev, 22 Sep 2026).

## What it does

- **Stamp**: a file declares `<!-- instruction-profile: opus-5 -->` in its first five lines; lint reports `unstamped`, `stale` or `current` against the target model.
- **Rules as data** (`OpusRules.swift`): remove "think carefully" lines, flag requests to reproduce reasoning, flag vague design instructions, add a stop policy, add a task-file rule. Each rule carries a rationale.
- **Three actions**: `delete` (auto-applied), `review` (a human decides), `add` (append a block). Lines near `delet`/`force-push`/`production`/`secret` are never auto-edited.
- **Regression check** (`RegressionCheck.swift`): protected lines survive, no mechanical findings remain, stamp current, fenced code untouched, migration is idempotent.

```swift
let result = InstructionMigrator().migrate(text)
let checks = RegressionCheck.run(result)
precondition(checks.allSatisfy(\.passed))
print(result.migrated)
```

## How to run it

```sh
git clone https://github.com/rajatslakhina/instruction-file-model-migration-article-demo
cd instruction-file-model-migration-article-demo
open Demo.xcodeproj      # pick an iPhone Simulator, press Run
swift test               # library tests, no Xcode needed
```

The demo app edits a sample Opus-5-era CLAUDE.md, lists findings by lane, migrates it and shows the five regression checks.

## Verification status

- `swift build` and `swift test` (10 tests, 0 failures) ran on Swift 6.1.3, Linux x86_64.
- `Demo.xcodeproj` uses a local package reference (`relativePath = "."`); its `project.pbxproj` was checked for brace/paren balance and dangling ids.
- **The demo app was NOT launched on an iOS Simulator and there is no screenshot.** This run had no Mac shell and no granted access to drive Xcode, so the SwiftUI target was reviewed by hand only and has not been compiled.
