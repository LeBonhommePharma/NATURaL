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
        .target(
            name: "BonhommeCore",
            path: "Sources/BonhommeCore"
        ),
    ]
)
