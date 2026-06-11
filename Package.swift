// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HackerNewsCLI",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "hn", targets: ["hn"]),
        .library(name: "HNCore", targets: ["HNCore"]),
    ],
    targets: [
        .target(name: "HNCore"),
        .executableTarget(name: "hn", dependencies: ["HNCore"]),
        .testTarget(name: "HNCoreTests", dependencies: ["HNCore"]),
    ]
)
