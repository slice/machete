public import Foundation

public struct HTTPSource {
  private let url: URL
  private let contentLength: Int

  public static func getting(_ url: URL) async throws -> Self {
    var request = URLRequest(url: url)
    request.httpMethod = "HEAD"
    let (_, httpResponse) = try await request.response()

    guard httpResponse.value(forHTTPHeaderField: "accept-ranges") == "bytes" else {
      throw HTTPSource.Error.serverNotAcceptingRanges(httpResponse)
    }

    guard let contentLength = httpResponse.value(forHTTPHeaderField: "content-length").flatMap(Int.init) else {
      throw HTTPSource.Error.noContentLength(httpResponse)
    }

    return Self(url: url, contentLength: contentLength)
  }
}

extension HTTPSource: Source {
  public typealias Piece = Data

  public var byteCount: Int { contentLength }
  public var startIndex: Int { 0 }
  public var endIndex: Int { contentLength }

  public func piece(at range: Range<Int>) async throws -> Data {
    let entire = startIndex ..< endIndex
    guard entire.contains(range) else {
      preconditionFailure("requested out-of-bounds piece \(range), entire source: \(entire)")
    }
    var request = URLRequest(url: url)
    request.addValue("bytes=\(range.lowerBound)-\(range.upperBound - 1)", forHTTPHeaderField: "range")

    let data: Data
    do {
      let started = Date.now
      defer {
        let elapsedSeconds = started.timeIntervalSinceNow * -1
        print("requested \(range) (\(range.count) bytes), took \((elapsedSeconds * 1000).rounded())ms")
      }

      (data, _) = try await request.response()
    }
    assert(data.count == range.count, "wanted \(range.count) bytes, but server returned \(data.count) bytes")
    return data
  }
}

public extension HTTPSource {
  enum Error: Swift.Error {
    case noContentLength(HTTPURLResponse)
    case serverNotAcceptingRanges(HTTPURLResponse)
    case notOK(HTTPURLResponse)
  }
}

extension HTTPSource.Error: CustomStringConvertible {
  public var description: String {
    switch self {
    case .noContentLength: "server didn't return Content-Length"
    case .serverNotAcceptingRanges: "server didn't return Accept-Ranges: bytes"
    case let .notOK(response): "server returned HTTP \(response.statusCode)"
    }
  }
}

// MARK: -

private extension URLRequest {
  func response() async throws -> (Data, HTTPURLResponse) {
    let (data, response) = try await URLSession.shared.data(for: self)
    guard let httpResponse = response as? HTTPURLResponse else {
      preconditionFailure("response isn't HTTPURLResponse")
    }
    guard (200 ..< 300).contains(httpResponse.statusCode) else {
      throw HTTPSource.Error.notOK(httpResponse)
    }
    return (data, httpResponse)
  }
}
