import ArgumentParser
import Foundation
import MacheteCore

@main
struct MacheteTool: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "machete",
    abstract: "A reverse engineering multi-tool for Apple platforms.",
    version: "0.0.0",
    subcommands: [Image.self],
  )
}

extension MacheteTool {
  struct Image: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Manipulate Mach-O images.",
      subcommands: [List.self],
      aliases: ["i", "im", "img"],
    )
  }
}

extension MacheteTool.Image {
  struct List: AsyncParsableCommand {
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

    mutating func run() async throws {
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

      for image in SharedCache.inMemory.images where matchers.allSatisfy({ $0(image) }) {
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
