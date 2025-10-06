// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "icalendar-vcard-kit",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ICalendar",
            targets: ["ICalendar"]
        ),
        .library(
            name: "VCard",
            targets: ["VCard"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ICalendar"
        ),
        .testTarget(
            name: "ICalendarTests",
            dependencies: ["ICalendar"]
        ),
        .target(
            name: "VCard"
        ),
        .testTarget(
            name: "VCardTests",
            dependencies: ["VCard"]
        ),

    ]
)
