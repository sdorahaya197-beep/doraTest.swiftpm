// swift-tools-version: 5.5
import PackageDescription

let package = Package(
    name: "doraTest",
    platforms: [
        .iOS("15.2")
    ],
    targets: [
        .executableTarget(
            name: "doraTest",
            path: ".",
            exclude: ["README.md"]
        )
    ]
)
