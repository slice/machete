public extension AssetAudience {
  /** iOS system updates. */
  @inlinable
  static var iOSRelease: Self { Self(rawValue: "01c1d682-6e8f-4908-b724-5501fe3f5e5c") }

  /** iOS assets unrelated to system updates. */
  @inlinable
  static var iOSGeneric: Self { Self(rawValue: "0c88076f-c292-4dad-95e7-304db9d29d34") }

  /** iOS security updates. */
  @inlinable
  static var iOSSecurity: Self { Self(rawValue: "c724cb61-e974-42d3-a911-ffd4dce11eda") }
}
