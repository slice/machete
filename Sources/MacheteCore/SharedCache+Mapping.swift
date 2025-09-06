public import CDyld

public extension SharedCache {
  struct Mapping {
    @_spi(Guts)
    public var guts: dyld_cache_mapping_info

    @_spi(Guts)
    public init(guts: dyld_cache_mapping_info) {
      self.guts = guts
    }
  }
}

public extension SharedCache.Mapping {
  func accessibleStartAddress(within cache: SharedCache) -> UnsafeRawPointer {
    cache.base + cache.slide + Int(guts.address)
  }

  var destinationStart: UnsafeRawPointer {
    UnsafeRawPointer(bitPattern: UInt(guts.address))!
  }

  var destinationEnd: UnsafeRawPointer {
    UnsafeRawPointer(bitPattern: UInt(guts.address + guts.size))!
  }

  var size: Int {
    Int(guts.size)
  }

  var fileOffset: Int {
    Int(guts.fileOffset)
  }

  var maxProtection: VMProtection {
    VMProtection(rawValue: vm_prot_t(guts.maxProt))
  }

  var initialProtection: VMProtection {
    VMProtection(rawValue: vm_prot_t(guts.initProt))
  }
}

extension SharedCache.Mapping: CustomStringConvertible {
  public var description: String {
    "\(initialProtection) <\(maxProtection)> \(fileOffset.formattedAddress)..\((fileOffset + size).formattedAddress) -> \(destinationStart)..\(destinationEnd) [\(size.formattedByteCount)]"
  }
}

public extension SharedCache {
  var mappings: [Mapping] {
    let count = Int(guts.pointee.mappingCount)
    let start = (base + Int(guts.pointee.mappingOffset)).bindMemory(to: dyld_cache_mapping_info.self, capacity: count)
    return UnsafeBufferPointer(start: start, count: count).map { Mapping(guts: $0) }
  }
}
