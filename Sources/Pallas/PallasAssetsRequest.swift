public import Foundation

public struct PallasAssetsRequest {
  public var clientVersion = 2

  // "AssetType"
  public var type: AssetType
  // "AssetAudience"
  public var audience: AssetAudience

  // "ProductType", e.g. "Mac15,10"
  public var device: String
  // "HWModelStr", e.g. "J514mAP"
  public var model: String
  // "ProductVersion", e.g. "15.1"
  public var version: String
  // "Build" (_and_ "BuildVersion"?), e.g. "24B83"
  public var buildVersion: String

  // "CompatibilityVersion"
  // "AllowSameBuildVersion"

  public init(type: AssetType, audience: AssetAudience, device: String, model: String, version: String, buildVersion: String) {
    self.type = type
    self.audience = audience
    self.device = device
    self.model = model
    self.version = version
    self.buildVersion = buildVersion
  }
}

extension PallasAssetsRequest: Codable {
  public enum CodingKeys: String, CodingKey {
    case audience = "AssetAudience"
    case buildVersion = "BuildVersion"
    case clientVersion = "ClientVersion"
    case device = "ProductType"
    case model = "HWModelStr"
    case type = "AssetType"
    case version = "ProductVersion"
  }
}

public extension PallasAssetsRequest {
  func response() async throws -> Data {
    let request: URLRequest = try {
      var request = URLRequest(url: URL(string: "https://gdmf.apple.com/v2/assets")!)
      request.httpMethod = "POST"
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.addValue("application/json", forHTTPHeaderField: "Accept")
      request.httpBody = try JSONEncoder().encode(self)
      return request
    }()

    // TODO: The server uses Apple Root CA, which _might_ be untrusted by default.
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      throw PallasError.httpNotOk(response)
    }

    guard let jwt = String(data: data, encoding: .utf8) else {
      throw PallasError.illFormedResponse(reason: "server response wasn't utf8", response)
    }
    let jwtPieces = jwt.split(separator: ".")
    guard jwtPieces.count == 3 else {
      throw PallasError.illFormedResponse(reason: "server response wasn't comprised of 3 pieces", response)
    }

    let payloadBase64JSON = jwtPieces[1].convertingURLSafeBase64ToBase64.paddedBase64
    guard let payloadJSON = Data(base64Encoded: payloadBase64JSON) else {
      throw PallasError.illFormedResponse(reason: "couldn't decode payload as base64", response)
    }

    return payloadJSON
  }
}

private extension StringProtocol {
  var convertingURLSafeBase64ToBase64: String {
    replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
  }

  var paddedBase64: String {
    self + String(repeating: "=", count: (4 - count % 4) % 4)
  }
}
