// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "EasyMeal",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "EasyMeal",
            targets: ["EasyMeal"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "7.0.0"),
        .package(url: "https://github.com/ashleymills/Reachability.swift.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "EasyMeal",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFunctions", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "Reachability", package: "Reachability.swift")
            ])
    ]
) 