// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Flick",
    defaultLocalization: "zh-Hans",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "Flick", targets: ["Flick"])],
    targets: [
        .executableTarget(name: "Flick", resources: [.process("Resources")]),
        .testTarget(name: "FlickTests", dependencies: ["Flick"])
    ]
)
