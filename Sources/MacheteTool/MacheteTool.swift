public import ArgumentParser
import CDyld
import Foundation
@_spi(Guts) @_spi(Formatting) import MacheteCore
import Pallas

@main
struct MacheteTool: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "machete",
    abstract: "A reverse engineering multi-tool for Apple platforms.",
    version: "0.0.0",
    subcommands: [Image.self, Pallas.self, Cache.self],
  )
}

extension MacheteTool {
  struct Image: ParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Manipulate Mach-O images.",
      subcommands: [List.self],
      aliases: ["i", "im", "img"],
    )
  }

  struct Cache: ParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Manipulate dyld shared caches.",
      subcommands: [Info.self],
      aliases: ["c", "cac"],
    )
  }

  struct Pallas: ParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Interact with Pallas (one of Apple's asset metadata servers, used to distribute software updates and other dynamically retrieved content).",
      subcommands: [Request.self],
      aliases: ["p"],
    )
  }
}

extension MacheteTool.Cache {
  struct Info: ParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Print information about a shared cache.",
      aliases: ["i"],
    )

    @Argument(help: "The shared cache to print information about.", completion: .list(["in-memory", "."]))
    var sharedCache: SharedCacheTarget = .inMemory

    mutating func run() throws {
      let header = { (text: String) -> String in
        "\u{1b}[1;36m\(text)\u{1b}[0m"
      }

      func printCache(_ cache: SharedCache) {
        // TODO: Put some of these behind flags.
        printFields(of: cache.guts.pointee) { print in
          print("Magic", cache.magic)
          print("Mapping Offset", \.mappingOffset.formattedAddress)
          print("Mapping Count", \.mappingCount)
          print("dyld Base Address", \.dyldBaseAddress.formattedAddress)
          print("Local Symbols Offset", \.localSymbolsOffset.formattedAddress)
          print("Local Symbols Size", \.localSymbolsSize)
          print("UUID", UUID(uuid: cache.guts.pointee.uuid).uuidString)
          print("Type", \.cacheType)
          print("Subtype", \.cacheSubType)
          print("Branch Pools Offset", \.branchPoolsOffset)
          print("Branch Pools Count", \.branchPoolsCount)
          print("Unslid mach_header Address", \.dyldInCacheMH.formattedAddress)
          print("Unslid _dyld_start Address", \.dyldInCacheEntry.formattedAddress)
          print("First Image Text Info Offset", \.imagesTextOffset.formattedAddress)
          print("Image Text Info Count", \.imagesTextCount)
          print("Code Signature Blob Offset", \.codeSignatureOffset.formattedAddress)
          print("Code Signature Blob Size", \.codeSignatureSize.formattedAddress)
          print("Platform", \.platform)
          print("Shared Region Start", \.sharedRegionStart.formattedAddress)
          print("Shared Region Size", \.sharedRegionSize.formattedAddress)
          print("Unslid Image Array Address", \.dylibsImageArrayAddr.formattedAddress)
          print("Image Array Size", \.dylibsImageArraySize)
          print("Subcache Count", \.subCacheArrayCount)
          print("First Image Info Offset", \.imagesOffset.formattedAddress)
          print("Image Info Count", \.imagesCount)
          print("Atlas Offset", \.cacheAtlasOffset.formattedAddress)
          print("Atlas Size", \.cacheAtlasSize)
        }

        let mappings = cache.mappings
        print()
        print(header("Mappings (\(mappings.count)):"))
        for (index, mapping) in mappings.enumerated() {
          print("Mapping \(index + 1): \(mapping)")
        }
      }

      try sharedCache.withResolved { cache in
        print(header("Cache (@\(cache.base))"))
        printCache(cache)

        let subcaches = cache.subcaches
        for (index, subcache) in subcaches.enumerated() {
          print()
          print(header("Subcache \(index + 1)/\(subcaches.count) (+\(subcache.cacheVMOffset.formattedAddress)):"))

          let subcacheBase = cache.base + subcache.cacheVMOffset
          printCache(SharedCache(unsafePointingTo: subcacheBase, slide: Int(bitPattern: subcacheBase)))
        }
      }
    }
  }
}

extension MacheteTool.Image {
  struct List: ParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "List Mach-O images in a shared cache.",
      aliases: ["l", "ls"],
    )

    @Argument(help: "The shared cache to list images from.", completion: .list(["in-memory", "."]))
    var sharedCache: SharedCacheTarget = .inMemory

    @Option(name: [.customLong("path"), .customShort("p")], help: """
    Filter images by a case-insensitive substring match in their absolute file path.
    """)
    var searchPath: String?

    @Option(name: [.customLong("n"), .customShort("n")], help: """
    Filter images by a case-insensitive exact match of their name (the last path component of their absolute file path).
    For example: `viewbridge` or `libobjc.A.dylib`.
    """)
    var searchName: String?

    @Option(name: [.customLong("loading"), .customShort("l")], help: """
    Filter images by a case-insensitive substring match in the string representation of their load commands.
    """)
    var searchLoadCommand: String?

    @Flag(name: [.customLong("print-load-commands"), .customShort("c")], help: """
    Print a string representation of each image's load commands.
    """)
    var printLoadCommands = false

    mutating func run() throws {
      try sharedCache.withResolved { cache in
        var matchers: [(_ image: SharedCache.Image) -> Bool] = []

        if let searchPath {
          matchers.append { image in
            image.filePath.localizedCaseInsensitiveContains(searchPath)
          }
        }
        if let searchLoadCommand {
          matchers.append { image in
            image.loadCommands.contains {
              String(describing: $0).localizedCaseInsensitiveContains(searchLoadCommand)
            }
          }
        }
        if let searchName {
          matchers.append { image in
            guard let lastSlash = image.filePath.lastIndex(of: "/") else {
              return false
            }
            let lastSegment = image.filePath[image.filePath.index(after: lastSlash)...]
            return lastSegment.localizedCaseInsensitiveCompare(searchName) == .orderedSame
          }
        }

        for (index, image) in cache.images.enumerated() {
          let addr = UnsafeRawPointer(bitPattern: UInt(image.info.address))!
          guard matchers.allSatisfy({ $0(image) }) else { continue }
          print(image)

          if printLoadCommands {
            for loadCommand in image.loadCommands {
              print("  ", loadCommand)
            }
          }
        }
      }
    }
  }
}

extension MacheteTool.Pallas {
  struct Request: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: """
      Make a request to Pallas and print the extracted JSON response verbatim. Other portions of the response are dropped.
      """,
      discussion: """
      The JSON is not formatted on your behalf, so it's likely worth piping the output to jq(1) or similar.
      """,
      aliases: ["r", "req"],
    )

    @Option(name: [.customLong("type"), .customShort("t")], help: "The requested asset type (AssetType).")
    var type: AssetType = .embedded

    @Option(name: [.customLong("audience"), .customShort("a")], help: "The requested asset audience (AssetAudience).")
    var audience: AssetAudience = .iOSRelease

    @Option(name: [.customLong("device"), .customShort("d")], help: "The requested device (ProductType), e.g. Mac15,10")
    var device: String

    @Option(name: [.customLong("model"), .customShort("m")], help: "The requested model (HWModelStr), e.g. J514mAP")
    var model: String

    @Option(name: [.customLong("version"), .customShort("v")], help: "The requested version (ProductVersion), e.g. 15.1")
    var version: String

    @Option(name: [.customLong("build-version"), .customShort("b")], help: "The requested build version (BuildVersion), e.g. 24B83")
    var buildVersion: String

    mutating func run() async throws {
      let request = PallasAssetsRequest(
        type: type,
        audience: audience,
        device: device,
        model: model,
        version: version,
        buildVersion: buildVersion,
      )

      let jsonData = try await request.response()
      guard let json = String(data: jsonData, encoding: .utf8) else {
        // TODO: This should print to stderr.
        print("couldn't decode JSON as UTF-8")
        throw ExitCode.failure
      }

      print(json)
    }
  }
}

extension AssetType: ExpressibleByArgument {
  init?(argument: String) {
    switch argument {
    case "embedded": self = .embedded
    case "embeddedRecovery": self = .embeddedRecovery
    case "embeddedRapidSecurityResponse": self = .embeddedRapidSecurityResponse
    case "mac": self = .mac
    case "macRecovery": self = .macRecovery
    case "macSystemFallbackRecovery": self = .macSystemFallbackRecovery
    case "macRapidSecurityResponse": self = .macRapidSecurityResponse
    default: self.init(rawValue: argument)
    }
  }
}

extension AssetAudience: ExpressibleByArgument {
  init?(argument: String) {
    switch argument {
    case "ios": self = .iOSRelease
    case "iOSSecurity": self = .iOSSecurity
    case "iOSGeneric": self = .iOSGeneric
    case "macOS": self = .macOS
    case "macGeneric": self = .macGeneric
    default: self.init(rawValue: argument)
    }
  }
}
