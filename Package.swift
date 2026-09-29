// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "InstructionMigration",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "InstructionMigration",
            targets: ["InstructionMigration"]
        )
    ],
    targets: [
        .target(
            name: "InstructionMigration",
            path: "Sources/InstructionMigration"
        ),
        .testTarget(
            name: "InstructionMigrationTests",
            dependencies: ["InstructionMigration"],
            path: "Tests/InstructionMigrationTests"
        )
    ]
)
