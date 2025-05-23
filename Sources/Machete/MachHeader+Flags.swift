import Foundation
import MachO
public import OrderedCollections

// TODO(skip): This is gross and ought to use macros, but swift-syntax compile
// times are miserable.

extension MachHeader {
  // https://github.com/apple-oss-distributions/xnu/blob/e3723e1f17661b24996789d8afc084c0c3303b26/EXTERNAL_HEADERS/mach-o/loader.h#L125
  public struct Flags: RawRepresentable, OptionSet, Hashable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }

    public static let noUndefinedReferences = Self(rawValue: UInt32(MH_NOUNDEFS))
    public static let incrementallyLinked = Self(rawValue: UInt32(MH_INCRLINK))
    public static let dynamicallyLinked = Self(rawValue: UInt32(MH_DYLDLINK))
    public static let bindingUndefinedReferencesAtLoad = Self(rawValue: UInt32(MH_BINDATLOAD))
    public static let prebound = Self(rawValue: UInt32(MH_PREBOUND))
    public static let splitSegments = Self(rawValue: UInt32(MH_SPLIT_SEGS))
    public static let sharedLibraryLazyInitialization = Self(rawValue: UInt32(MH_LAZY_INIT))
    public static let twoLevelNamespaceBindings = Self(rawValue: UInt32(MH_TWOLEVEL))
    public static let forcingFlatNameSpaceBindings = Self(rawValue: UInt32(MH_FORCE_FLAT))
    public static let noMultipleDefinitionsPerSymbol = Self(rawValue: UInt32(MH_NOMULTIDEFS))
    public static let withoutFixingPrebinding = Self(rawValue: UInt32(MH_NOFIXPREBINDING))
    public static let prebindable = Self(rawValue: UInt32(MH_PREBINDABLE))
    public static let allTwoLevelModulesBound = Self(rawValue: UInt32(MH_ALLMODSBOUND))
    // swift-format-ignore
    public static let sectionsDividableViaSymbols = Self(rawValue: UInt32(MH_SUBSECTIONS_VIA_SYMBOLS))
    public static let canonical = Self(rawValue: UInt32(MH_CANONICAL))
    public static let containsExternalWeakSymbols = Self(rawValue: UInt32(MH_WEAK_DEFINES))
    public static let usesWeakSymbols = Self(rawValue: UInt32(MH_BINDS_TO_WEAK))
    public static let allowStackExecution = Self(rawValue: UInt32(MH_ALLOW_STACK_EXECUTION))
    public static let rootSafe = Self(rawValue: UInt32(MH_ROOT_SAFE))
    public static let setUidSafe = Self(rawValue: UInt32(MH_SETUID_SAFE))
    public static let noReexportedDylibs = Self(rawValue: UInt32(MH_NO_REEXPORTED_DYLIBS))
    public static let pie = Self(rawValue: UInt32(MH_PIE))
    public static let deadStrippableDylib = Self(rawValue: UInt32(MH_DEAD_STRIPPABLE_DYLIB))
    public static let hasTLVDescriptors = Self(rawValue: UInt32(MH_HAS_TLV_DESCRIPTORS))
    public static let noHeapExecution = Self(rawValue: UInt32(MH_NO_HEAP_EXECUTION))
    public static let appExtensionSafe = Self(rawValue: UInt32(MH_APP_EXTENSION_SAFE))
    // swift-format-ignore
    public static let nListOutOfSyncWithDyldInfo = Self(rawValue: UInt32(MH_NLIST_OUTOFSYNC_WITH_DYLDINFO))
    public static let simulatorSupported = Self(rawValue: UInt32(MH_SIM_SUPPORT))
    public static let dylibInCache = Self(rawValue: UInt32(MH_DYLIB_IN_CACHE))
  }
}

extension MachHeader.Flags {
  public static let allFlagsDescribed: OrderedDictionary<Self, String> = [
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
