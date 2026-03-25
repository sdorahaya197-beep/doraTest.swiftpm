// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "doraTest",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(name: "doraTest", targets: ["doraTest"])
    ],
    targets: [
        .executableTarget(
            name: "doraTest",
            path: "Sources"
        )
    ]
)
