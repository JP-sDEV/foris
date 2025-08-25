// swift-tools-version: 5.9
// Package.swift for Foris iOS App Dependencies

import PackageDescription

let package = Package(
    name: "foris",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "foris",
            targets: ["foris"]
        ),
    ],
    dependencies: [
        // Apollo GraphQL
        .package(
            url: "https://github.com/apollographql/apollo-ios.git",
            from: "1.7.0"
        ),
        
        // Google Sign-In
        .package(
            url: "https://github.com/google/GoogleSignIn-iOS.git",
            from: "7.0.0"
        ),
        
        // Keychain wrapper for secure storage
        .package(
            url: "https://github.com/kishikawakatsumi/KeychainAccess.git",
            from: "4.2.2"
        ),
        
        // Image loading and caching
        .package(
            url: "https://github.com/onevcat/Kingfisher.git",
            from: "7.9.0"
        ),
        
        // Network reachability
        .package(
            url: "https://github.com/ashleymills/Reachability.swift.git",
            from: "5.0.0"
        )
    ],
    targets: [
        .target(
            name: "foris",
            dependencies: [
                .product(name: "Apollo", package: "apollo-ios"),
                .product(name: "ApolloAPI", package: "apollo-ios"),
                .product(name: "ApolloWebSocket", package: "apollo-ios"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "Reachability", package: "Reachability.swift")
            ]
        ),
        .testTarget(
            name: "forisTests",
            dependencies: ["foris"]
        )
    ]
)