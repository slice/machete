public import CDyld
public import Foundation

public extension SharedCache {
  struct Subcache {
    @_spi(Guts)
    public var guts: dyld_subcache_entry

    init(guts: dyld_subcache_entry) {
      self.guts = guts
    }
  }
}

public extension SharedCache.Subcache {
  var uuid: UUID {
    UUID(uuid: guts.uuid)
  }

  /** "The offset of this subcache from the main cache base address." */
  var cacheVMOffset: Int {
    Int(guts.cacheVMOffset)
  }

  var fileNameSuffix: String {
    let maxSuffixLength = 32
    // Null-terminated.
    let bytes = withUnsafeBytes(of: guts.fileSuffix) { ptr in
      [UInt8](unsafeUninitializedCapacity: maxSuffixLength) { buf, len in
        len = ptr.copyBytes(to: buf, count: maxSuffixLength)
      }
    }
    return String(decoding: bytes.prefix(while: { $0 != 0 }), as: UTF8.self)
  }
}
