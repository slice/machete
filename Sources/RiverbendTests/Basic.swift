import Foundation
@testable import Riverbend
import System
import Testing

@Test(.disabled())
func hugeFile() async throws {
  let source = try await FileSource.reading(fileAt: URL(filePath: "/Volumes/1M2/ipsw-poking/UniversalMac_26.0_25A5351b_Restore.ipsw")!)
  #expect(source.byteCount == 18_110_649_555)
  #expect(source.startIndex == 0)
  #expect(source.byteCount == source.endIndex)
}

extension Data {
  var hex: String {
    map { String(format: "%02x", $0) }.joined(separator: " ")
  }
}

@Test
func hugeHTTP() async throws {
  let source = try await HTTPSource.getting(URL(string: "https://updates.cdn-apple.com/2025SummerSeed/fullrestores/093-28610/036AE4A3-8A7D-44F1-A26F-ED754C346A74/UniversalMac_26.0_25A5351b_Restore.ipsw")!)
  #expect(source.byteCount == 18_110_649_555)
  #expect(source.startIndex == 0)
  #expect(source.byteCount == source.endIndex)

  func findFromEnd(_ bytes: some DataProtocol) async throws -> Range<Data.Index>? {
    let bufferSize = 2048
    var position = source.byteCount
    var location: Range<Data.Index>?

    repeat {
      // Offset the jump by the length of the desired sequence. This introduces an overlap between
      // read chunks such that we're able to find what we want even if it spans across buffer boundaries.
      position -= bufferSize - bytes.count
      guard position > source.startIndex else { return nil }
      let piece = try await source.piece(at: position ..< min(position + bufferSize, source.byteCount))
      location = piece.firstRange(of: bytes)
    } while location == nil

    // Rebase the range to be in terms of the entire file.
    let start = position + location!.lowerBound
    return start ..< start + bytes.count
  }

  // Don't bother searching for a standard EOCD, since IPSWs are huge; just look for the EOCD64.
  let eocd64Offset: UInt64
  do {
    let eocd64LocatorMagic = try await findFromEnd([0x50, 0x4B, 0x06, 0x07])!
    var eocd64LocatorPiece = try await source.read(startingAt: eocd64LocatorMagic.startIndex, maxLength: 1024)
    eocd64LocatorPiece.removeFirst(8)
    eocd64Offset = eocd64LocatorPiece.read(UInt64.self)
  }

  // Read the EOCD64, which should tell us where the CD is.
  var entries: Data
  do {
    var eocd64Piece = try await source.read(startingAt: Int(eocd64Offset), maxLength: 1024)
    eocd64Piece.removeFirst(40)
    let centralDirSize = eocd64Piece.read(UInt64.self)
    let centralDirOffset = eocd64Piece.read(UInt64.self)
    // TODO: Don't read the whole thing… but what do we need to read?
    entries = try await source.read(startingAt: Int(centralDirOffset), maxLength: Int(centralDirSize))
  }

  while !entries.isEmpty {
    // Check for the central directory file header (CDFH).
    let magic = entries.read(UInt32.self)
    guard magic == 0x0201_4B50 else { // 0x50, 0x4b, 0x01, 0x02 (little endian)
      preconditionFailure("not a valid cdfh? (magic \(magic))")
    }

    _ = entries.read(bytes: 16)
    // These need to be UInt64 because they're upgraded to 64-bit values if necessary.
    var compressedSize = UInt64(entries.read(UInt32.self))
    var uncompressedSize = UInt64(entries.read(UInt32.self))

    let fileNameLength = entries.read(UInt16.self)
    let extraLength = entries.read(UInt16.self)
    let fileCommentLength = entries.read(UInt16.self)
    _ = entries.read(bytes: 8)
    var relativeOffset = UInt64(entries.read(UInt32.self))
    let fileName = String(data: entries.read(bytes: Int(fileNameLength)), encoding: .utf8)!

    if extraLength > 0 {
      var extra = entries.read(bytes: Int(extraLength))
      if extra.read(UInt16.self) == 1 /* ZIP64 extended information */ {
        // Instead of using the size, deduce it from which values contain the sentinel.
        _ = extra.read(UInt16.self)

        func upgradeIfNeeded(_ upgradeable: inout UInt64) {
          // 0xffffffff means "use the ZIP64 data to get the real value".
          guard upgradeable == UInt32.max else { return }
          upgradeable = extra.read(UInt64.self)
        }

        upgradeIfNeeded(&uncompressedSize)
        upgradeIfNeeded(&compressedSize)
        upgradeIfNeeded(&relativeOffset)
      }
    }

    print(fileName, "\(compressedSize) compressed, \(uncompressedSize) uncompressed", "@\(relativeOffset)")
    _ = entries.read(bytes: Int(fileCommentLength))
  }
}

private extension Data {
  @inline(__always)
  mutating func read(bytes: Int) -> Data {
    let taken = prefix(bytes)
    removeFirst(bytes)
    return taken
  }

  @inline(__always)
  private mutating func _read<T: BinaryInteger>(_: T.Type) -> T {
    let stride = MemoryLayout<T>.stride
    precondition(count >= stride)
    // This assumes that the machine is little-endian.
    let parsed = withUnsafeBytes {
      $0.loadUnaligned(as: T.self)
    }
    removeFirst(stride)
    return parsed
  }

  @inline(__always)
  mutating func read(_: UInt64.Type) -> UInt64 {
    _read(UInt64.self)
  }

  @inline(__always)
  mutating func read(_: UInt32.Type) -> UInt32 {
    _read(UInt32.self)
  }

  @inline(__always)
  mutating func read(_: UInt16.Type) -> UInt16 {
    _read(UInt16.self)
  }
}
