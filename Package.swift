// swift-tools-version: 6.0
import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "UseCaseMacro",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "UseCaseMacro",
            targets: ["UseCaseMacro"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"603.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing.git", exact: "0.6.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.18.1"),
    ],
    targets: [
        .target(
            name: "UseCaseMacro",
            dependencies: [
                "UseCaseMacroFoundation",
                "UseCaseMacroMacros",
            ],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
        .target(
            name: "UseCaseMacroFoundation",
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
        .macro(
            name: "UseCaseMacroMacros",
            dependencies: [
                "UseCaseMacroFoundation",
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .unsafeFlags(
                    [
                        "-Xfrontend", "-entry-point-function-name",
                        "-Xfrontend", "wWinMain",
                    ],
                    .when(platforms: [.windows])
                ),
            ]
        ),
        .testTarget(
            name: "UseCaseMacroTests",
            dependencies: [
                "UseCaseMacro",
                "UseCaseMacroMacros",
                .product(name: "MacroTesting", package: "swift-macro-testing"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
    ]
)
