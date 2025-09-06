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

  var loadCommands: some Sequence<MachHeader.LoadCommand> {
    let firstLoadCommand = base + MemoryLayout<mach_header_64>.stride
    return LoadCommands(startingAt: firstLoadCommand, byteSizeOfAllCommands: Int(header.sizeofcmds))
  }
}

struct LoadCommands: IteratorProtocol, Sequence {
  typealias Element = MachHeader.LoadCommand

  var first: UnsafeRawPointer
  var offset: Int = 0
  let byteSizeOfAllCommands: Int

  init(startingAt firstLoadCommand: UnsafeRawPointer, byteSizeOfAllCommands: Int) {
    first = firstLoadCommand
    self.byteSizeOfAllCommands = byteSizeOfAllCommands
  }

  mutating func next() -> MachHeader.LoadCommand? {
    guard offset < byteSizeOfAllCommands else { return nil }

    let current = (first + offset).bindMemory(to: load_command.self, capacity: 1)
    defer { offset += Int(current.pointee.cmdsize) }

    return MachHeader.LoadCommand(unsafeLoadingFrom: current)
  }
}

extension SharedCache.Image: CustomStringConvertible {
  public var description: String {
    let ptr = UnsafeRawPointer(bitPattern: UInt(info.address))!
    return "[\(ptr)] \(filePath) <\(flags)>"
  }
}
