import MachO

public extension SharedCache.Image {
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
