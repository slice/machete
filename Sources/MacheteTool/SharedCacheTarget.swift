import ArgumentParser
@_spi(Guts) @_spi(Formatting) import MacheteCore

enum SharedCacheTarget {
  case inMemory
  case filePath(String)
}

extension SharedCacheTarget: ExpressibleByArgument {
  init?(argument: String) {
    switch argument {
    case "in-memory", ".":
      self = .inMemory
    default:
      self = .filePath(argument)
    }
  }
}

extension SharedCacheTarget {
  func withResolved(_ work: (_ cache: SharedCache) throws -> Void) rethrows {
    switch self {
    case .inMemory:
      try work(.inMemory)
    case let .filePath(path):
      try SharedCache.withMemoryMapped(file: path) { try work($0) }
    }
  }
}
