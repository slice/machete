import Foundation

public struct MachHeader {}

public extension MachHeader {
  // https://github.com/apple-oss-distributions/xnu/blob/e3723e1f17661b24996789d8afc084c0c3303b26/EXTERNAL_HEADERS/mach-o/loader.h#L125
  struct Flags: RawRepresentable, OptionSet, Hashable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }

    public static let noUndefinedReferences = Self(rawValue: 1 << 0)
    public static let incrementallyLinked = Self(rawValue: 1 << 1)
    public static let dynamicallyLinked = Self(rawValue: 1 << 2)
    public static let bindingUndefinedReferencesAtLoad = Self(rawValue: 1 << 3)
    public static let prebound = Self(rawValue: 1 << 4)
    public static let splitSegments = Self(rawValue: 1 << 5)
    public static let sharedLibraryLazyInitialization = Self(rawValue: 1 << 6)
    public static let twoLevelNamespaceBindings = Self(rawValue: 1 << 7)
    public static let forcingFlatNameSpaceBindings = Self(rawValue: 1 << 8)
    public static let noMultipleDefinitionsPerSymbol = Self(rawValue: 1 << 9)
    public static let withoutFixingPrebinding = Self(rawValue: 1 << 10)
    public static let prebindable = Self(rawValue: 1 << 11)
    public static let allTwoLevelModulesBound = Self(rawValue: 1 << 12)
    public static let sectionsDividableViaSymbols = Self(rawValue: 1 << 13)
    public static let canonical = Self(rawValue: 1 << 14)
    public static let containsExternalWeakSymbols = Self(rawValue: 1 << 15)
    public static let usesWeakSymbols = Self(rawValue: 1 << 16)
    public static let allowStackExecution = Self(rawValue: 1 << 17)
    public static let rootSafe = Self(rawValue: 1 << 18)
    public static let setUidSafe = Self(rawValue: 1 << 19)
    public static let noReexportedDylibs = Self(rawValue: 1 << 20)
    public static let pie = Self(rawValue: 1 << 21)
    public static let deadStrippableDylib = Self(rawValue: 1 << 22)
    public static let hasTLVDescriptors = Self(rawValue: 1 << 23)
    public static let noHeapExecution = Self(rawValue: 1 << 24)
    public static let appExtensionSafe = Self(rawValue: 1 << 25)
    public static let nListOutOfSyncWithDyldInfo = Self(rawValue: 1 << 26)
    public static let simulatorSupported = Self(rawValue: 1 << 27)
    public static let dylibInCache = Self(rawValue: 1 << 31)
  }
}

public extension MachHeader.Flags {
  static let allFlagsDescribed: [Self: String] = [
    .noUndefinedReferences: "MH_NOUNDEFS",
    .incrementallyLinked: "MH_INCRLINK",
    .dynamicallyLinked: "MH_DYLDLINK",
    .bindingUndefinedReferencesAtLoad: "MH_BINDATLOAD",
    .prebound: "MH_PREBOUND",
    .splitSegments: "MH_SPLIT_SEGS",
    .sharedLibraryLazyInitialization: "MH_LAZY_INIT",
    .twoLevelNamespaceBindings: "MH_TWOLEVEL",
    .forcingFlatNameSpaceBindings: "MH_FORCE_FLAT",
    .noMultipleDefinitionsPerSymbol: "MH_NOMULTIDEFS",
    .withoutFixingPrebinding: "MH_NOFIXPREBINDING",
    .prebindable: "MH_PREBINDABLE",
    .allTwoLevelModulesBound: "MH_ALLMODSBOUND",
    .sectionsDividableViaSymbols: "MH_SUBSECTIONS_VIA_SYMBOLS",
    .canonical: "MH_CANONICAL",
    .containsExternalWeakSymbols: "MH_WEAK_DEFINES",
    .usesWeakSymbols: "MH_BINDS_TO_WEAK",
    .allowStackExecution: "MH_ALLOW_STACK_EXECUTION",
    .rootSafe: "MH_ROOT_SAFE",
    .setUidSafe: "MH_SETUID_SAFE",
    .noReexportedDylibs: "MH_NO_REEXPORTED_DYLIBS",
    .pie: "MH_PIE",
    .deadStrippableDylib: "MH_DEAD_STRIPPABLE_DYLIB",
    .appExtensionSafe: "MH_APP_EXTENSION_SAFE",
    .nListOutOfSyncWithDyldInfo: "MH_NLIST_OUTOFSYNC_WITH_DYLDINFO",
    .simulatorSupported: "MH_SIM_SUPPORT",
    .dylibInCache: "MH_DYLIB_IN_CACHE",
  ]
}

extension MachHeader.Flags: CaseIterable {
  public static var allCases: [MachHeader.Flags] {
    allFlagsDescribed.map(\.0)
  }
}

extension MachHeader.Flags: CustomStringConvertible {
  public var description: String {
    var flagNames: [String] = []
    var remainingFlags = self

    for (flag, name) in Self.allFlagsDescribed where remainingFlags.contains(flag) {
      flagNames.append(name)
      remainingFlags.subtract(flag)
    }

    // Describe any flags we don't know about.
    if !remainingFlags.isEmpty {
      flagNames.append(String(format: "0x%08x", remainingFlags.rawValue))
    }

    if flagNames.isEmpty {
      return "[]"
    } else {
      return flagNames.joined(separator: " | ")
    }
  }
}
