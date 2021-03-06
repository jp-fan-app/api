// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "JPFanAppServer",
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/fluent-mysql.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/auth.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/console.git", from: "3.0.0"),
        .package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", from: "17.0.2")
    ],
    targets: [
        .target(name: "App", dependencies: [
            "SwiftyJSON", 
            "Command", 
            "Authentication", 
            "FluentMySQL", 
            "Vapor"
        ]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

