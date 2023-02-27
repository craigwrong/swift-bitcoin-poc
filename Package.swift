// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "CornModel",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "CornModel",
            targets: ["CornModel"]),
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.3.0")
    ],
    targets: [
        .binaryTarget(name: "secp256k1",
            url: "https://github.com/craigwrong/secp256k1/releases/download/22.0.1-craigwrong.1/secp256k1.xcframework.zip", checksum: "fff5415b72449331212cb75c71a47445cbe54fed061dc82153dcadbffae10f69"
            ),
        .target(
            name: "ECHelper",
            dependencies: ["secp256k1"]),
        .target(
            name: "CornModel",
            dependencies: ["ECHelper", "BigInt"]),
        .testTarget(
            name: "CornModelTests",
            dependencies: ["CornModel"]),
    ]
)
