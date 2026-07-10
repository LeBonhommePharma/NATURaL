// swift-tools-version: 5.9
import PackageDescription

// ═══════════════════════════════════════════════════════════════════════════
// BONHOMME_ACCEL — opt-in C++ acceleration (default OFF)
// ═══════════════════════════════════════════════════════════════════════════
//
// Default graph (no env):
//   BonhommeCore → (no Accel deps) → `swift test` / Xcode app builds stay Swift-only.
//
// Opt-in (host / advanced):
//   BONHOMME_ACCEL=1 swift build
//   BONHOMME_ACCEL=1 BONHOMME_ACCEL_LIB=/path/to/dir-with-libBonhommeAccel.a swift build
//
// Ship iOS device / simulator slices first:
//   make accel-ios
//   BONHOMME_ACCEL=1 BONHOMME_ACCEL_LIB=$PWD/../BonhommeAccel/dist/iphoneos swift build
//
// Xcode device builds: see BonhommeAccel/TESTING.md § Path C and
// BonhommeAccel/xcconfig/BonhommeAccel.ios.xcconfig.
//
// Invariant: never wire Accel into the default test path. Keep dependencies empty
// unless BONHOMME_ACCEL=1 is explicitly set when Package.swift is evaluated.
// ═══════════════════════════════════════════════════════════════════════════

let enableAccel = Context.environment["BONHOMME_ACCEL"] == "1"
/// Directory containing prebuilt `libBonhommeAccel.a` (CMake output).
let accelLibDir = Context.environment["BONHOMME_ACCEL_LIB"] ?? "../BonhommeAccel/build"

var coreDependencies: [Target.Dependency] = []
var coreSwiftSettings: [SwiftSetting] = []
var coreLinkerSettings: [LinkerSetting] = []

if enableAccel {
    coreDependencies = ["BonhommeAccelSwift"]
    coreSwiftSettings = [.define("BONHOMME_ACCEL")]
    // Resolve ba_* from the prebuilt CMake static library at final link.
    // Metal/Foundation are required when Accel was built with BA_ENABLE_METAL=ON.
    coreLinkerSettings = [
        .linkedLibrary("c++"),
        .linkedFramework("Metal"),
        .linkedFramework("Foundation"),
        .unsafeFlags(["-L\(accelLibDir)", "-lBonhommeAccel"]),
    ]
}

let package = Package(
    name: "BonhommeCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        // Primary product used by all app targets (Bonhomme, Watch, TV, Vision).
        .library(name: "BonhommeCore", targets: ["BonhommeCore"]),
        // Opt-in product: Swift wrappers over the C API. Not linked by default
        // app targets. Prefer BONHOMME_ACCEL=1 (wires via BonhommeCore) over
        // depending on this product alone — BonhommeCore must define BONHOMME_ACCEL
        // for EntropyCalculator / CrossDomainValidator to call into Accel.
        .library(name: "BonhommeAccelSwift", targets: ["BonhommeAccelSwift"]),
    ],
    targets: [
        // C bridging target for BonhommeAccel (provides BonhommeAccel.h to Swift).
        // Header + empty shim only — real symbols live in libBonhommeAccel.a (CMake).
        .target(
            name: "clibBonhommeAccel",
            path: "Sources/clibBonhommeAccel",
            publicHeadersPath: "include"
        ),
        // Swift wrapper for the C++ accelerator (ba_* API).
        .target(
            name: "BonhommeAccelSwift",
            dependencies: ["clibBonhommeAccel"],
            path: "Sources/BonhommeAccelSwift"
        ),
        // Main library. Accel is conditional on BONHOMME_ACCEL=1 at package resolve.
        .target(
            name: "BonhommeCore",
            dependencies: coreDependencies,
            path: "Sources/BonhommeCore",
            swiftSettings: coreSwiftSettings,
            linkerSettings: coreLinkerSettings
        ),
        // Path A tests — always depend only on BonhommeCore. When Package.swift is
        // evaluated without BONHOMME_ACCEL=1, Accel is not in the graph at all.
        .testTarget(
            name: "BonhommeCoreTests",
            dependencies: ["BonhommeCore"],
            path: "Tests/BonhommeCoreTests"
        ),
    ]
)
