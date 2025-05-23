import Foundation
import MachO

// TODO(skip): This is gross and ought to use macros, but swift-syntax compile
// times are miserable.

extension MachHeader {
  // https://github.com/apple-oss-distributions/xnu/blob/e3723e1f17661b24996789d8afc084c0c3303b26/EXTERNAL_HEADERS/mach-o/loader.h#L263
  public struct LoadCommandType: RawRepresentable, Sendable, Equatable, Hashable {
    public let rawValue: UInt32

    /// "After MacOS X 10.1 when a new load command is added that is required to
    /// be understood by the dynamic linker for the image to execute properly the
    /// LC_REQ_DYLD bit will be or'ed into the load command constant.  If the
    /// dynamic linker sees such a load command it it does not understand will
    /// issue a "unknown load command required for execution" error and refuse to
    /// use the image.  Other load commands without this bit that are not
    /// understood will simply be ignored."
    public var required: Bool {
      rawValue & LC_REQ_DYLD != 0
    }

    public init(rawValue: UInt32) {
      self.rawValue = rawValue
    }

    /// "segment of this file to be mapped"
    public static let segment = Self(rawValue: UInt32(LC_SEGMENT))
    /// "link-edit stab symbol table info"
    public static let symbolTable = Self(rawValue: UInt32(LC_SYMTAB))
    /// "link-edit gdb symbol table info (obsolete)"
    public static let symbolSegment = Self(rawValue: UInt32(LC_SYMSEG))
    /// "thread"
    public static let thread = Self(rawValue: UInt32(LC_THREAD))
    /// "unix thread (includes a stack)"
    public static let unixThread = Self(rawValue: UInt32(LC_UNIXTHREAD))
    /// "load a specified fixed VM shared library"
    public static let loadFixedVMSharedLibrary = Self(rawValue: UInt32(LC_LOADFVMLIB))
    /// "fixed VM shared library identification"
    public static let fixedVMSharedLibraryIdentification = Self(rawValue: UInt32(LC_IDFVMLIB))
    /// "object identification info (obsolete)"
    public static let objectIdentification = Self(rawValue: UInt32(LC_IDENT))
    /// "fixed VM file inclusion (internal use)"
    public static let fixedVMFileInclusion = Self(rawValue: UInt32(LC_FVMFILE))
    /// "prepage command (internal use)"
    public static let prepage = Self(rawValue: UInt32(LC_PREPAGE))
    /// "dynamic link-edit symbol table info"
    public static let dynamicSymbolTable = Self(rawValue: UInt32(LC_DYSYMTAB))
    /// "load a dynamically linked shared library"
    public static let loadDylib = Self(rawValue: UInt32(LC_LOAD_DYLIB))
    /// "dynamically linked shared lib ident"
    public static let dylibIdentification = Self(rawValue: UInt32(LC_ID_DYLIB))
    /// "load a dynamic linker"
    public static let loadDynamicLinker = Self(rawValue: UInt32(LC_LOAD_DYLINKER))
    /// "dynamic linker identification"
    public static let dynamicLinkerIdentification = Self(rawValue: UInt32(LC_ID_DYLINKER))
    /// "modules prebound for a dynamically linked shared library"
    public static let preboundDylib = Self(rawValue: UInt32(LC_PREBOUND_DYLIB))
    /// "image routines"
    public static let routines = Self(rawValue: UInt32(LC_ROUTINES))
    /// "sub framework"
    public static let subFramework = Self(rawValue: UInt32(LC_SUB_FRAMEWORK))
    /// "sub umbrella"
    public static let subUmbrella = Self(rawValue: UInt32(LC_SUB_UMBRELLA))
    /// "sub client"
    public static let subClient = Self(rawValue: UInt32(LC_SUB_CLIENT))
    /// "sub library"
    public static let subLibrary = Self(rawValue: UInt32(LC_SUB_LIBRARY))
    /// "two-level namespace lookup hints"
    public static let twoLevelHints = Self(rawValue: UInt32(LC_TWOLEVEL_HINTS))
    /// "prebind checksum"
    public static let prebindChecksum = Self(rawValue: UInt32(LC_PREBIND_CKSUM))
    /// "load a dynamically linked shared library that is allowed to be missing (all symbols are weak imported)."
    public static let loadWeakDylib = Self(rawValue: UInt32(LC_LOAD_WEAK_DYLIB))
    /// "64-bit segment of this file to be mapped"
    public static let segment64Bit = Self(rawValue: UInt32(LC_SEGMENT_64))
    /// "64-bit image routines"
    public static let routines64Bit = Self(rawValue: UInt32(LC_ROUTINES_64))
    /// "the uuid"
    public static let uuid = Self(rawValue: UInt32(LC_UUID))
    /// "runpath additions"
    public static let rpath = Self(rawValue: UInt32(LC_RPATH))
    /// "local of code signature"
    public static let codeSignature = Self(rawValue: UInt32(LC_CODE_SIGNATURE))
    /// "local of info to split segments"
    public static let segmentSplitInformation = Self(rawValue: UInt32(LC_SEGMENT_SPLIT_INFO))
    /// "load and re-export dylib"
    public static let reexportDylib = Self(rawValue: UInt32(LC_REEXPORT_DYLIB))
    /// "delay load of dylib until first use"
    public static let lazyLoadDylib = Self(rawValue: UInt32(LC_LAZY_LOAD_DYLIB))
    /// "encrypted segment information"
    public static let encryptionInfo = Self(rawValue: UInt32(LC_ENCRYPTION_INFO))
    /// "compressed dyld information"
    public static let dyldInfo = Self(rawValue: UInt32(LC_DYLD_INFO))
    /// "compressed dyld information only"
    public static let dyldInfoOnly = Self(rawValue: UInt32(LC_DYLD_INFO_ONLY))
    /// "load upward dylib"
    public static let loadUpwardDylib = Self(rawValue: UInt32(LC_LOAD_UPWARD_DYLIB))
    /// "build for MacOSX min OS version"
    public static let versionMinMacOSX = Self(rawValue: UInt32(LC_VERSION_MIN_MACOSX))
    /// "build for iPhoneOS min OS version"
    public static let versionMinIPhoneOS = Self(rawValue: UInt32(LC_VERSION_MIN_IPHONEOS))
    /// "compressed table of function start addresses"
    public static let functionStarts = Self(rawValue: UInt32(LC_FUNCTION_STARTS))
    /// "string for dyld to treat like environment variable"
    public static let dyldEnvironment = Self(rawValue: UInt32(LC_DYLD_ENVIRONMENT))
    /// "replacement for LC_UNIXTHREAD"
    public static let main = Self(rawValue: UInt32(LC_MAIN))
    /// "table of non-instructions in __text"
    public static let dataInCode = Self(rawValue: UInt32(LC_DATA_IN_CODE))
    /// "source version used to build binary"
    public static let sourceVersion = Self(rawValue: UInt32(LC_SOURCE_VERSION))
    /// "Code signing DRs copied from linked dylibs"
    public static let dylibCodeSignDRs = Self(rawValue: UInt32(LC_DYLIB_CODE_SIGN_DRS))
    /// "64-bit encrypted segment information"
    public static let encryptionInfo64 = Self(rawValue: UInt32(LC_ENCRYPTION_INFO_64))
    /// "linker options in MH_OBJECT files"
    public static let linkerOption = Self(rawValue: UInt32(LC_LINKER_OPTION))
    /// "optimization hints in MH_OBJECT files"
    public static let linkerOptimizationHint = Self(rawValue: UInt32(LC_LINKER_OPTIMIZATION_HINT))
    /// "build for AppleTV min OS version"
    public static let versionMinTVOS = Self(rawValue: UInt32(LC_VERSION_MIN_TVOS))
    /// "build for Watch min OS version"
    public static let versionMinWatchOS = Self(rawValue: UInt32(LC_VERSION_MIN_WATCHOS))
    /// "arbitrary data included within a Mach-O file"
    public static let note = Self(rawValue: UInt32(LC_NOTE))
    /// "build for platform min OS version"
    public static let buildVersion = Self(rawValue: UInt32(LC_BUILD_VERSION))
    /// "used with linkedit_data_command, payload is trie"
    public static let dyldExportsTrie = Self(rawValue: UInt32(LC_DYLD_EXPORTS_TRIE))
    /// "used with linkedit_data_command"
    public static let dyldChainedFixups = Self(rawValue: UInt32(LC_DYLD_CHAINED_FIXUPS))
    /// "used with fileset_entry_command"
    public static let filesetEntry = Self(rawValue: UInt32(LC_FILESET_ENTRY))
  }
}

extension MachHeader.LoadCommandType: CustomStringConvertible {
  public var description: String {
    switch self {
    case .segment: "LC_SEGMENT"
    case .symbolTable: "LC_SYMTAB"
    case .symbolSegment: "LC_SYMSEG"
    case .thread: "LC_THREAD"
    case .unixThread: "LC_UNIXTHREAD"
    case .loadFixedVMSharedLibrary: "LC_LOADFVMLIB"
    case .fixedVMSharedLibraryIdentification: "LC_IDFVMLIB"
    case .objectIdentification: "LC_IDENT"
    case .fixedVMFileInclusion: "LC_FVMFILE"
    case .prepage: "LC_PREPAGE"
    case .dynamicSymbolTable: "LC_DYSYMTAB"
    case .loadDylib: "LC_LOAD_DYLIB"
    case .dylibIdentification: "LC_ID_DYLIB"
    case .loadDynamicLinker: "LC_LOAD_DYLINKER"
    case .dynamicLinkerIdentification: "LC_ID_DYLINKER"
    case .preboundDylib: "LC_PREBOUND_DYLIB"
    case .routines: "LC_ROUTINES"
    case .subFramework: "LC_SUB_FRAMEWORK"
    case .subUmbrella: "LC_SUB_UMBRELLA"
    case .subClient: "LC_SUB_CLIENT"
    case .subLibrary: "LC_SUB_LIBRARY"
    case .twoLevelHints: "LC_TWOLEVEL_HINTS"
    case .prebindChecksum: "LC_PREBIND_CKSUM"
    case .loadWeakDylib: "LC_LOAD_WEAK_DYLIB"
    case .segment64Bit: "LC_SEGMENT_64"
    case .routines64Bit: "LC_ROUTINES_64"
    case .uuid: "LC_UUID"
    case .rpath: "LC_RPATH"
    case .codeSignature: "LC_CODE_SIGNATURE"
    case .segmentSplitInformation: "LC_SEGMENT_SPLIT_INFO"
    case .reexportDylib: "LC_REEXPORT_DYLIB"
    case .lazyLoadDylib: "LC_LAZY_LOAD_DYLIB"
    case .encryptionInfo: "LC_ENCRYPTION_INFO"
    case .dyldInfo: "LC_DYLD_INFO"
    case .dyldInfoOnly: "LC_DYLD_INFO_ONLY"
    case .loadUpwardDylib: "LC_LOAD_UPWARD_DYLIB"
    case .versionMinMacOSX: "LC_VERSION_MIN_MACOSX"
    case .versionMinIPhoneOS: "LC_VERSION_MIN_IPHONEOS"
    case .functionStarts: "LC_FUNCTION_STARTS"
    case .dyldEnvironment: "LC_DYLD_ENVIRONMENT"
    case .main: "LC_MAIN"
    case .dataInCode: "LC_DATA_IN_CODE"
    case .sourceVersion: "LC_SOURCE_VERSION"
    case .dylibCodeSignDRs: "LC_DYLIB_CODE_SIGN_DRS"
    case .encryptionInfo64: "LC_ENCRYPTION_INFO_64"
    case .linkerOption: "LC_LINKER_OPTION"
    case .linkerOptimizationHint: "LC_LINKER_OPTIMIZATION_HINT"
    case .versionMinTVOS: "LC_VERSION_MIN_TVOS"
    case .versionMinWatchOS: "LC_VERSION_MIN_WATCHOS"
    case .note: "LC_NOTE"
    case .buildVersion: "LC_BUILD_VERSION"
    case .dyldExportsTrie: "LC_DYLD_EXPORTS_TRIE"
    case .dyldChainedFixups: "LC_DYLD_CHAINED_FIXUPS"
    case .filesetEntry: "LC_FILESET_ENTRY"
    default: String(format: "0x%02x", rawValue)
    }
  }
}
