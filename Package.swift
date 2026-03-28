// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "LabForgeMenuBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "LabForgeMenuBar",
            targets: ["LabForgeMenuBar"]
        )
    ],
    targets: [
        .executableTarget(
            name: "LabForgeMenuBar",
            path: "Sources"
        )
    ]
)
