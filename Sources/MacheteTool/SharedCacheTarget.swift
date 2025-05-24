import ArgumentParser

enum SharedCacheTarget {
  case inMemory
  // TODO: external
}

extension SharedCacheTarget: ExpressibleByArgument {
  init?(argument: String) {
    switch argument {
    case "in-memory", ".":
      self = .inMemory
    default:
      return nil
    }
  }
}
