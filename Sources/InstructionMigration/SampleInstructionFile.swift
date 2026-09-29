import Foundation

/// A deliberately Opus-5-era CLAUDE.md for a fictional iOS team. Used by the demo app and the tests.
public enum SampleInstructionFile {
    public static let iosTeam = """
    <!-- instruction-profile: opus-5 -->
    # CLAUDE.md, Checkout iOS

    ## Working style
    Think carefully before you answer.
    - Think step by step through every refactor.
    - Show your full reasoning in the reply so reviewers can follow along.
    Think carefully before deleting any file or force-pushing a branch.

    ## UI
    Avoid generic looking screens.

    ## Build
    ```
    # Example prompt we used to paste: think carefully about the module graph
    xcodebuild -scheme Checkout -destination 'platform=iOS Simulator,name=iPhone 16'
    ```
    Run SwiftLint before every commit.
    """
}
