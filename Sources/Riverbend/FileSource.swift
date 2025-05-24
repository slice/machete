public import Foundation

public struct FileSource {
  private var content: Data

  public static func reading(fileAt url: URL) async throws -> Self {
    // Always prefer memory mapping; IPSWs can be ~20 GB.
    let content = try Data(contentsOf: url, options: .alwaysMapped)
    return FileSource(content: content)
  }
}

extension FileSource: Source {
  public typealias Piece = Data

  public var byteCount: Int {
    content.count
  }

  public var startIndex: Int {
    content.startIndex
  }

  public var endIndex: Int {
    content.endIndex
  }

  public func piece(at range: Range<Int>) async throws -> Piece {
    content[range]
  }
}
