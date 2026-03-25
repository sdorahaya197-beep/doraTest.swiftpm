// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "doraTest",
    platforms: [
        .iOS(.v17)
    ],
    targets: [
        .executableTarget(
            name: "doraTest"
        )
    ]
)
