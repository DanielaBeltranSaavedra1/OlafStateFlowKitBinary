// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OlafStateFlowKitBinary",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "OlafStateFlowKit",
            targets: ["OlafStateFlowKit"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "OlafStateFlowKit",
            path: "OlafStateFlowKit.xcframework"
        )
    ]
)
