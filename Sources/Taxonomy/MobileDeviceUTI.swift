import Foundation

public struct MobileDeviceUTI: Identifiable, CustomStringConvertible, Sendable, Hashable {
  public let id: String
  public let description: String
  public let deviceModelCodes: [String]
}

public extension MobileDeviceUTI {
  /// All exported Uniform Type Identifiers representing mobile devices, taken from `CoreTypes.bundle`'s `MobileDevices.bundle`.
  ///
  /// - Note: Many of these devices are duplicated due to enclosure colors and other variations.
  ///   This results in many instances with identical `description` and `deviceModelCodes`, but different `id`s.
  static let all: Set<MobileDeviceUTI> = {
    let bundlePath = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Library/MobileDevices.bundle"
    let mobileDevices = Bundle(path: bundlePath)
    guard let exportedTypeDeclarations = mobileDevices?.infoDictionary?["UTExportedTypeDeclarations"] as? [[String: Any]] else {
      fatalError("MobileDevices.bundle doesn't match expected format")
    }

    return Set(exportedTypeDeclarations.compactMap { exported -> MobileDeviceUTI? in
      guard let description = exported["UTTypeDescription"] as? String,
            let spec = exported["UTTypeTagSpecification"] as? [String: Any],
            let modelCodes = spec["com.apple.device-model-code"] as? [String],
            let id = exported["UTTypeIdentifier"] as? String else { return nil }

      // Exclude generic model codes.
      let filteredModelCodes = modelCodes.filter { !["iPhone", "iPad", "iPod"].contains($0) }

      return MobileDeviceUTI(id: id, description: description, deviceModelCodes: filteredModelCodes)
    })
  }()
}
