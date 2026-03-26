// swift-tools-version: 5.9
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "doraTest",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "doraTest",
            targets: ["AppModule"],
            bundleIdentifier: "com.example.doraTest",
            displayVersion: "1.0",
            bundleVersion: "1",
            supportedDeviceFamilies: [
                .phone,
                .pad
            ],
            appIcon: .placeholder(icon: .person),
            accentColor: .presetColor(.blue)
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "Sources"
        )
    ]
)
