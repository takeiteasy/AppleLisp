// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppleLisp",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "AppleLisp",
            targets: ["AppleLisp"]
        ),
        .executable(
            name: "apll",
            targets: ["apll"]
        ),
        .executable(
            name: "aplld",
            targets: ["aplld"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "AppleLisp",
            resources: [
                .copy("Resources/wisp_jsc.js")
            ]
        ),
        .executableTarget(
            name: "apll",
            dependencies: [
                "AppleLisp",
                "CEditline",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/apll"
        ),
        .executableTarget(
            name: "aplld",
            dependencies: [
                "AppleLisp",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/aplld",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        ),
        .testTarget(
            name: "AppleLispTests",
            dependencies: ["AppleLisp"]
        ),
        .systemLibrary(
            name: "CEditline",
            path: "Sources/CEditline"
        )
    ]
)