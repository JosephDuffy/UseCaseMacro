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
        .package(url: "https://github.com/swiftlang/swift-syntax", "600.0.0"..<"604.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing.git", exact: "0.7.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.19.5"),
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
                // This is used in UseCaseMacro but it's not needed to compile and adding it
                // prevents the prebuilt SwiftSyntax from being used.
//                "UseCaseMacroFoundation",
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
        // I usually put API tests in with the main test target but then it depends on
        // UseCaseMacro and UseCaseMacroFoundation, which prevents the prebuilt SwiftSyntax from
        // being used.
        .testTarget(
            name: "UseCaseMacroAPITests",
            dependencies: ["UseCaseMacro"],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
        .testTarget(
            name: "UseCaseMacroTests",
            dependencies: [
                "UseCaseMacroMacros",
                .product(name: "MacroTesting", package: "swift-macro-testing"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
    ]
)
