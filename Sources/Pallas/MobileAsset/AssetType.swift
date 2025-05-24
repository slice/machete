// https://gist.github.com/Siguza/0331c183c8c59e4850cd0b62fd501424#file-pallas-sh-L3606
// https://theapplewiki.com/wiki/List_of_Asset_Types#Asset_types
public struct AssetType: RawRepresentable, Hashable, Equatable, Sendable {
  public let rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

extension AssetType: Codable {
  public init(from decoder: any Decoder) throws {
    rawValue = try decoder.singleValueContainer().decode(String.self)
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
