// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EosioSwiftEcc",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "EosioSwiftEcc",
            targets: ["Recover", "EosioSwiftEcc"]),
    ],
    dependencies: [
        .package(name: "EosioSwift", url: "https://github.com/EOSIO/eosio-swift", .branch("spm-support")),
        // Have to use SSH form since the repo is currently private.
        .package(name: "openssl", url: "git@github.com:EOSIO/openssl-xcframework.git", .branch("master")),
        .package(url: "https://github.com/realm/SwiftLint", from: "0.39.1")
    ],
    targets: [
        .target(
            name: "Recover",
            dependencies: ["openssl"],
            path: "Sources/Recover"
        ),
        .target(
            name: "EosioSwiftEcc",
            dependencies: ["Recover", "EosioSwift"],
            path: "Sources/EosioSwiftEcc"
        ),
        .testTarget(
            name: "EosioSwiftEccTests",
            dependencies: ["EosioSwiftEcc"]),
    ]
)
