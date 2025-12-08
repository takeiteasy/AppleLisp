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
            name: "repl",
            targets: ["repl"]
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
            name: "repl",
            dependencies: [
                "AppleLisp",
                "CEditline",
                "CNcurses",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .systemLibrary(
            name: "CEditline"
        ),
        .systemLibrary(
            name: "CNcurses"
        )
    ]
)

