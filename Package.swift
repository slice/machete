// swift-tools-version:6.0

import PackageDescription

let swiftSettings: [SwiftSetting] = [
  .swiftLanguageMode(.v6),
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("InternalImportsByDefault"),
  .enableExperimentalFeature("MemberImportVisibility"),
  .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
]

let package = Package(
  name: "Machete",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "machete", targets: ["MacheteTool"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections", from: "1.2.0"),
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
  ],
  targets: [
    .target(name: "CDyld"),
    .target(
      name: "Taxonomy",
      swiftSettings: swiftSettings,
    ),
    .target(
      name: "MacheteCore",
      dependencies: [
        "CDyld",
        .product(name: "Collections", package: "swift-collections"),
      ],
      swiftSettings: swiftSettings,
    ),
    .executableTarget(
      name: "MacheteTool",
      dependencies: [
        "MacheteCore",
        "Taxonomy",
        .product(name: "Collections", package: "swift-collections"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      swiftSettings: swiftSettings,
    ),
  ],
)
