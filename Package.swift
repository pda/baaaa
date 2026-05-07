// swift-tools-version:5.9
import PackageDescription
import Foundation

func selectedDeveloperDir() -> String? {
    if let developerDir = ProcessInfo.processInfo.environment["DEVELOPER_DIR"], !developerDir.isEmpty {
        return developerDir
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcode-select")
    process.arguments = ["-p"]

    let output = Pipe()
    process.standardOutput = output
    process.standardError = Pipe()

    do {
        try process.run()
    } catch {
        return nil
    }

    process.waitUntilExit()
    guard process.terminationStatus == 0 else { return nil }

    let data = output.fileHandleForReading.readDataToEndOfFile()
    let path = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    return path.isEmpty ? nil : path
}

let testingFrameworkSearchPath = [
    selectedDeveloperDir().map {
        "\($0)/Platforms/MacOSX.platform/Developer/Library/Frameworks"
    },
    "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
].compactMap { $0 }.first { FileManager.default.fileExists(atPath: "\($0)/Testing.framework") }

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
