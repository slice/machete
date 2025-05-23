// swift-tools-version:6.0

import PackageDescription

// swiftformat:options --wraparguments before-first
let package = Package(
  name: "Machete",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "machete", targets: ["Machete"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections", .upToNextMinor(from: "1.2.0")),
  ],
  targets: [
    .target(name: "CDyld"),
    .executableTarget(
      name: "Machete",
      dependencies: [
        "CDyld",
        .product(name: "Collections", package: "swift-collections"),
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableExperimentalFeature("MemberImportVisibility"),
      ]
    ),
  ]
)
