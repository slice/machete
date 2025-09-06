public import Darwin

public struct VMProtection: OptionSet, Hashable, Equatable, Sendable {
  public let rawValue: vm_prot_t

  public init(rawValue: vm_prot_t) {
    self.rawValue = rawValue
  }

  public static var read: Self { Self(rawValue: VM_PROT_READ) }
  public static var write: Self { Self(rawValue: VM_PROT_WRITE) }
  public static var execute: Self { Self(rawValue: VM_PROT_EXECUTE) }
}

extension VMProtection: CustomStringConvertible {
  public var description: String {
    if contains(.execute) {
      return "--x"
    }
    if contains(.write) {
      return "rw-"
    }
    if contains(.read) {
      return "r--"
    }
    return "unk"
  }
}
