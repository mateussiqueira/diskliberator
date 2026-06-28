// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DiskLiberator",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "DiskLiberator",
            dependencies: [],
            path: "Sources/DiskLiberator"
        )
    ]
)
