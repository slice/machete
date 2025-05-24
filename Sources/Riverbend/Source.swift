public protocol Source {
  associatedtype Piece: RandomAccessCollection where Piece.Element == UInt8

  var byteCount: Int { get }

  var startIndex: Piece.Index { get }
  var endIndex: Piece.Index { get }
  func piece(at range: Range<Piece.Index>) async throws -> Piece
}

public extension Source where Piece.Index == Int {
  func read(startingAt start: Int, maxLength length: Int) async throws -> Piece {
    precondition(start >= startIndex, "bad start index")
    return try await piece(at: start ..< min(start + length, endIndex))
  }
}
