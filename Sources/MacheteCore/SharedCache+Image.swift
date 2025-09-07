public import CDyld
import Foundation

public extension SharedCache {
  struct Image {
    /// Metadata about the image as it exists in the shared cache.
    @_spi(Guts)
    public let info: dyld_cache_image_info

    /// A pointer where the Mach-O image is reachable.
    @_spi(Guts)
    public var base: UnsafeRawPointer

    public private(set) var filePath: String

    init(info: dyld_cache_image_info, within cache: SharedCache) {
      self.info = info

      // For whatever reason the image address is as if the cache was unslid,
      // so we need to rebase it.
      base = UnsafeRawPointer(bitPattern: UInt(info.address))! + Int(cache.slide)

      // It's very likely that we'll want the path string in some way soon, so
      // pay the (relatively minimal) cost of copying it now.
      filePath = (cache.base + Int(info.pathFileOffset)).withMemoryRebound(to: UInt8.self, capacity: 1) {
        String(cString: $0)
      }
    }
  }
}

public extension SharedCache.Image {
  // (Assuming 64-bit.)
  @_spi(Guts)
  var header: mach_header_64 {
    base.load(as: mach_header_64.self)
  }

  var flags: MachHeader.Flags {
    MachHeader.Flags(rawValue: header.flags)
  }
}

extension SharedCache.Image: CustomStringConvertible {
  public var description: String {
    let ptr = UnsafeRawPointer(bitPattern: UInt(info.address))!
    return "[\(ptr)] \(filePath) <\(flags)>"
  }
}

extension SharedCache {
  var imageCount: Int {
    Int(guts.pointee.imagesCount)
  }

  var firstImage: UnsafePointer<dyld_cache_image_info> {
    (base + Int(guts.pointee.imagesOffset)).bindMemory(to: dyld_cache_image_info.self, capacity: imageCount)
  }

  public var images: some RandomAccessCollection<SharedCache.Image> {
    UnsafeBufferPointer<dyld_cache_image_info>(start: firstImage, count: imageCount)
      .map { SharedCache.Image(info: $0, within: self) }
  }
}
