import CDyld

public struct SharedCache {
  /// Where the header of the shared cache is reachable.
  var guts: UnsafePointer<dyld_cache_header>

  var slide: UInt
}

public extension SharedCache {
  var base: UnsafeRawPointer { UnsafeRawPointer(guts) }
}

public extension SharedCache {
  init(unsafeLoadingFrom base: consuming UnsafeRawPointer, slide: UInt) {
    guts = base.bindMemory(to: dyld_cache_header.self, capacity: 1)
    self.slide = slide
  }
}

public extension SharedCache {
  var magic: String {
    withUnsafeBytes(of: guts.pointee.magic) {
      $0.withMemoryRebound(to: UInt8.self) { String(cString: $0.baseAddress!) }
    }
  }
}
