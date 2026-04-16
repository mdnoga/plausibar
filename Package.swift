// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Plausibar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Plausibar")
    ]
)
