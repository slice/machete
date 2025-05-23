// swift-tools-version:6.0

import PackageDescription

let package = Package(
  name: "Machete",
  platforms: [.macOS(.v14)],
  products: [
    .executable(name: "machete", targets: ["Machete"]),
  ],
  targets: [
    .target(name: "CDyld"),
    .executableTarget(
      name: "Machete",
      dependencies: ["CDyld"],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableExperimentalFeature("MemberImportVisibility"),
      ]
    ),
  ]
)
