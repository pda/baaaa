// swift-tools-version:5.9
import PackageDescription
import Foundation

let testingFrameworkSearchPath = [
    "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
    "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks",
].first { FileManager.default.fileExists(atPath: "\($0)/Testing.framework") }

let testingSwiftSettings: [SwiftSetting] = testingFrameworkSearchPath.map {
    [.unsafeFlags(["-F", $0])]
} ?? []

let testingLinkerSettings: [LinkerSetting] = testingFrameworkSearchPath.map {
    [.unsafeFlags(["-F", $0, "-Xlinker", "-rpath", "-Xlinker", $0]), .linkedFramework("Testing")]
} ?? []

let package = Package(
    name: "Baaaa",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Baaaa",
            resources: [
                .copy("Resources/esheep.png")
            ]
        ),
        .testTarget(
            name: "BaaaaTests",
            dependencies: ["Baaaa"],
            path: "Tests/BaaaaTests",
            swiftSettings: testingSwiftSettings,
            linkerSettings: testingLinkerSettings
        )
    ]
)
