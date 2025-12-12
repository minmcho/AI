// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HealthRashAI",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "HealthRashAI",
            targets: ["HealthRashAI"])
    ],
    targets: [
        .target(
            name: "HealthRashAI",
            path: "HealthRashAI")
    ]
)
