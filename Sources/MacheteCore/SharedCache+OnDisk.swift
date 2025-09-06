import CDyld
@preconcurrency import Darwin
import Foundation

public extension SharedCache {
  static func withMemoryMapped(file path: String, _ operation: (SharedCache) throws -> Void) rethrows {
    func mmapAllMappings(in cache: SharedCache, to region: UnsafeMutableRawPointer, base: UnsafeRawPointer? = nil, fd: CInt) {
      let mappings = cache.mappings
      let firstMappingDestStart = mappings.first!.destinationStart

      let offsetFromBase = if let base {
        firstMappingDestStart - base
      } else {
        0
      }
      for mapping in mappings {
        let offsetWithinRegion = Int(mapping.destinationStart - firstMappingDestStart) + offsetFromBase
        let destination = region + offsetWithinRegion

        // TODO: not unmapping? maybe vm_deallocate is enough
        let mapped = mmap(destination, mapping.size, PROT_READ, MAP_FIXED | MAP_PRIVATE, fd, Int64(mapping.fileOffset))
        guard mapped != MAP_FAILED else { fatalError("mmap failed") }
      }
    }

    // Read the first 4,096 bytes of the shared cache, which should give us the header and mappings at least.
    // Once we have the mappings we can memory-map the rest in.
    try readingHead(fileAt: path) { fd, page, _ in
      // Restrict the accessible lifetime of the header-only SharedCache, since it's inherently
      // undefined behavior to access e.g. subcaches from it.
      let (region, regionSize, firstBaseMappingStart) = {
        let headerOnlyCache = SharedCache(unsafePointingTo: page, slide: Int(bitPattern: page))

        // sharedRegionSize represents the space needed to map in all subcaches, too.
        let regionSize = Int(headerOnlyCache.guts.pointee.sharedRegionSize)
        let region = allocateAnywhere(bytes: regionSize)

        mmapAllMappings(in: headerOnlyCache, to: region, fd: fd)

        return (region, regionSize, headerOnlyCache.mappings.first!.destinationStart)
      }()

      // Now that we've mapped in the base cache, we can create another SharedCache wrapper
      // that is able to read past the header.
      let baseCache = SharedCache(unsafePointingTo: region, slide: Int(bitPattern: region))
      for subcache in baseCache.subcaches {
        readingHead(fileAt: path + subcache.fileNameSuffix) { fd, page, _ in
          let loadedSubcache = SharedCache(unsafePointingTo: page, slide: Int(bitPattern: page))
          mmapAllMappings(in: loadedSubcache, to: region, base: firstBaseMappingStart, fd: fd)
        }
      }

      defer {
        guard vm_deallocate(mach_task_self_, vm_address_t(bitPattern: region), vm_size_t(regionSize)) == KERN_SUCCESS else {
          fatalError("couldn't vm_deallocate shared cache (\(regionSize) bytes)")
        }
      }

      let slide = (-1 * Int(bitPattern: firstBaseMappingStart)) + Int(bitPattern: region)
      try operation(SharedCache(unsafePointingTo: region, slide: slide))
    }
  }
}

private func die(_ message: String) -> Never {
  let err = String(cString: strerror(errno))
  fatalError("\(message): \(err)")
}

private func readingHead<T>(bytes _: Int = 4096, fileAt path: String, _ work: (_ fd: CInt, _ firstPage: UnsafeMutableRawPointer, _ totalLength: Int) throws -> T) rethrows -> T {
  let fd = Darwin.open(path, O_RDONLY, 0)
  guard fd >= 0 else {
    die("open")
  }
  defer {
    guard Darwin.close(fd) == 0 else {
      die("close")
    }
  }

  var statInfo = stat()
  guard Darwin.fstat(fd, &statInfo) == 0 else {
    die("fstat")
  }
  let totalLength = Int(statInfo.st_size)

  let reading = 4096
  let page = UnsafeMutableRawPointer.allocate(byteCount: reading, alignment: 0)
  defer {
    page.deallocate()
  }
  guard Darwin.pread(fd, page, reading, 0) == reading else {
    fatalError("couldn't read first page")
  }

  return try work(fd, page, totalLength)
}

private func allocateAnywhere(bytes: Int) -> UnsafeMutableRawPointer {
  var regionAddress: vm_address_t = 0
  guard vm_allocate(mach_task_self_, &regionAddress, vm_size_t(bytes), VM_FLAGS_ANYWHERE) == KERN_SUCCESS else {
    fatalError("couldn't vm_allocate \(bytes) bytes")
  }
  return UnsafeMutableRawPointer(bitPattern: regionAddress)!
}
