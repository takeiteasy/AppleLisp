// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacLisp",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "MacLisp",
            targets: ["MacLisp"]
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
            name: "MacLisp",
            resources: [
                .copy("Resources/wisp_jsc.js")
            ]
        ),
        .executableTarget(
            name: "repl",
            dependencies: [
                "MacLisp",
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

