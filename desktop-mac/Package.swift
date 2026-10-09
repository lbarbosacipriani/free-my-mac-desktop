// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FreeMyMacDesktop",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "FreeMyMacDesktop", targets: ["FreeMyMacDesktop"])
    ],
    targets: [
        .executableTarget(
            name: "FreeMyMacDesktop",
            path: "Sources"
        )
    ]
)
