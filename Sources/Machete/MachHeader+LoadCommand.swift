public import Foundation
public import MachO

public extension MachHeader {
  enum LoadCommand {
    case dylib(DylibLoadCommand)
    case unknown(type: MachHeader.LoadCommandType, size: Int)
  }
}

public extension MachHeader.LoadCommand {
  init(unsafeLoadingFrom pointer: UnsafePointer<load_command>) {
    let type = MachHeader.LoadCommandType(rawValue: pointer.pointee.cmd)
    if [MachHeader.LoadCommandType.loadDylib, .loadWeakDylib, .reexportDylib].contains(type) {
      self = .dylib(DylibLoadCommand(unsafeLoadingFrom: pointer))
    } else {
      self = .unknown(type: type, size: Int(pointer.pointee.cmdsize))
    }
  }
}

public struct DylibLoadCommand {
  public let type: MachHeader.LoadCommandType
  /// "library's path name"
  public let name: String
  /// "library's build time stamp"
  public let buildTimestamp: Date
}

public extension DylibLoadCommand {
  // PERF: Copies the dylib name.
  init(unsafeLoadingFrom pointer: UnsafePointer<load_command>) {
    // This seems suspicious but I think it's copying the return value while
    // rebound?
    let cmd = pointer.withMemoryRebound(to: dylib_command.self, capacity: 1) { $0.pointee }
    type = MachHeader.LoadCommandType(rawValue: cmd.cmd)
    buildTimestamp = Date(timeIntervalSince1970: TimeInterval(cmd.dylib.timestamp))

    // The dylib name lies relative to the load command.
    let dylibNamePointer = UnsafeRawPointer(pointer) + Int(cmd.dylib.name.offset)
    name = dylibNamePointer.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
  }
}
