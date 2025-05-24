public extension AssetType {
  @inlinable
  static var mac: Self {
    Self(rawValue: "com.apple.MobileAsset.MacSoftwareUpdate")
  }

  @inlinable
  static var macRecovery: Self {
    Self(rawValue: "com.apple.MobileAsset.MacRecoveryOSUpdate")
  }

  // Probably means "System Fallback Recovery"; the system-wide recoveryOS
  // that isn't tied to a specific macOS installation (which was introduced after
  // macOS 12).
  @inlinable
  static var macSystemFallbackRecovery: Self {
    Self(rawValue: "com.apple.MobileAsset.SFRSoftwareUpdate")
  }

  @inlinable
  static var macRapidSecurityResponse: Self {
    Self(rawValue: "com.apple.MobileAsset.MacSplatSoftwareUpdate")
  }
}
