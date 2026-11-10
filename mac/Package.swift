// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SmokeLog",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "SmokeLog", path: "Sources/SmokeLog")
    ]
)
