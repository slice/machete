public extension AssetType {
  /** i.e. iOS, tvOS, watchOS, audioOS (HomePod), and xrOS (Vision Pro). */
  @inlinable
  static var embedded: Self {
    Self(rawValue: "com.apple.MobileAsset.SoftwareUpdate")
  }

  @inlinable
  static var embeddedRecovery: Self {
    Self(rawValue: "com.apple.MobileAsset.RecoveryOSUpdate")
  }

  @inlinable
  static var embeddedRapidSecurityResponse: Self {
    Self(rawValue: "com.apple.MobileAsset.SplatSoftwareUpdate")
  }
}
