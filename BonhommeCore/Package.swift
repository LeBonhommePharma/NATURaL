// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BonhommeCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "BonhommeCore", targets: ["BonhommeCore"]),
    ],
    targets: [
        // C bridging target for BonhommeAccel (provides BonhommeAccel.h to Swift)
        .target(
            name: "clibBonhommeAccel",
            path: "Sources/clibBonhommeAccel",
            publicHeadersPath: "include"
        ),
        // Swift wrapper for the C++ accelerator
        .target(
            name: "BonhommeAccelSwift",
            dependencies: ["clibBonhommeAccel"],
            path: "Sources/BonhommeAccelSwift"
        ),
        // Main library — conditionally uses BonhommeAccelSwift when available
        .target(
            name: "BonhommeCore",
            dependencies: [
                "BonhommeAccelSwift",
            ],
            path: "Sources/BonhommeCore",
            swiftSettings: [
                .define("BONHOMME_ACCEL"),
            ]
        ),
        .testTarget(
            name: "BonhommeCoreTests",
            dependencies: ["BonhommeCore"],
            path: "Tests/BonhommeCoreTests"
        ),
    ]
)
