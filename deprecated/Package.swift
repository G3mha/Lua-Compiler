// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "compilers",
    platforms: [
        .macOS(.v13),
        .custom("Linux", versionString: "1.0")
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
            name: "compilers",
            targets: ["compilers"]),
    ],
    targets: [
        .executableTarget(
            name: "compilers",
            dependencies: [],
            swiftSettings: [
                .unsafeFlags(["-O"]),
            ]),
    ]
)
