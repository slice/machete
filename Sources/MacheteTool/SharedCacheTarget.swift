import ArgumentParser
import MacheteCore

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
  func withResolved(_ work: (_ cache: SharedCache) -> Void) throws {
    switch self {
    case .inMemory:
      work(.inMemory)
    case let .filePath(path):
      fatalError("unimplemented")
    }
  }
}
