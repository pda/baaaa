// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Baaaa",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Baaaa",
            resources: [
                .copy("Resources/esheep.png")
            ]
        )
    ]
)
