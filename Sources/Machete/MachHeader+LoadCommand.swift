public extension MachHeader {
  enum LoadCommand: UInt32, RawRepresentable, Sendable {
    case segment = 0x1
    case symbolTable = 0x2
    case symbolSegment = 0x3
    case thread = 0x4
    case unixThread = 0x5
    case loadFixedVMSharedLibrary = 0x6
    case fixedVMSharedLibraryIdentification = 0x7
    case objectIdentification = 0x8
    case fixedVMFileInclusion = 0x9
    case prepage = 0xa
    case dynamicSymbolTable = 0xb
    case loadDylib = 0xc
    case dylibIdentification = 0xd
    case loadDynamicLinker = 0xe
    case dynamicLinkerIdentification = 0xf
    case preboundDylib = 0x10
    case routines = 0x11
    case subFramework = 0x12
    case subUmbrella = 0x13
    case subClient = 0x14
    case subLibrary = 0x15
    case twoLevelHints = 0x16
    case prebindChecksum = 0x17
  }
}

extension MachHeader.LoadCommand: CustomStringConvertible {
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
    }
  }
}
