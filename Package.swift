// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "C2CBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "C2CBar", targets: ["C2CBar"])
    ],
    targets: [
        .executableTarget(
            name: "C2CBar",
            dependencies: ["C2CBarCore", "C2CBarAssets"],
            path: "Sources/C2CBar"
        ),
        .target(
            name: "C2CBarAssets",
            dependencies: ["C2CBarCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .target(name: "C2CBarCore"),
        .testTarget(
            name: "C2CBarAssetsTests",
            dependencies: ["C2CBarAssets", "C2CBarCore"]
        ),
        .testTarget(
            name: "C2CBarCoreTests",
            dependencies: ["C2CBarCore"]
        )
    ]
)
