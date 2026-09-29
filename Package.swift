// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-9110-coder",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "RFC 9110 Coder",
            targets: ["RFC 9110 Coder"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-byte.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-coder.git", branch: "main", traits: ["Checkpoint", "Map", "Pair", "Predicate", "Repetition", "Skip", "Choice", "Either", "IteratorLeaves"]),
        .package(url: "https://github.com/swift-atoms/swift-parser.git", branch: "main", traits: ["Always", "Choice", "Either", "FlatMap", "IteratorLeaves", "Map", "Repetition", "Pair", "Predicate", "Skip", "Iterator"]),
        .package(url: "https://github.com/swift-atoms/swift-serializer.git", branch: "main", traits: ["Either", "Map", "Pair", "Repetition"]),
        .package(
            url: "https://github.com/swift-atoms/swift-standard-library-extensions.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-atoms/swift-cursor.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-either.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-product.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-5322.git", branch: "main"),
        .package(url: "https://github.com/swift-ietf/swift-rfc-9110.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-pair.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "RFC 9110 Coder",
            dependencies: [
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Coder", package: "swift-coder"),
                .product(name: "Cursor", package: "swift-cursor"),
                .product(name: "Cursor", package: "swift-cursor"),
                .product(name: "Either", package: "swift-either"),
                .product(name: "Parser", package: "swift-parser"),
                .product(name: "Product", package: "swift-product"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
                .product(name: "RFC 9110", package: "swift-rfc-9110"),
                .product(name: "Serializer", package: "swift-serializer"),
                .product(
                    name: "Standard Library Extensions",
                    package: "swift-standard-library-extensions"
                ),
                .product(name: "Pair", package: "swift-pair"),
            ]
        ),
        .testTarget(
            name: "RFC 9110 Coder Tests",
            dependencies: [
                "RFC 9110 Coder",
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Cursor", package: "swift-cursor"),
                .product(name: "Coder", package: "swift-coder"),
                .product(name: "Parser", package: "swift-parser"),
                .product(name: "RFC 5322", package: "swift-rfc-5322"),
                .product(name: "RFC 9110", package: "swift-rfc-9110"),
                .product(name: "Serializer", package: "swift-serializer"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
