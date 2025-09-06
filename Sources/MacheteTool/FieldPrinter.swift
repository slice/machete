struct FieldPrinter<Target> {
  let target: Target
  var fields: [(String, String)] = []

  mutating func callAsFunction(_ name: String, _ key: KeyPath<Target, some Any>) {
    fields.append((name, "\(target[keyPath: key])"))
  }

  @_disfavoredOverload
  mutating func callAsFunction(_ name: String, _ value: String) {
    fields.append((name, value))
  }
}

// TODO: Recognize a flag to support JSON output.

func printFields<T>(of value: T, _ fields: (inout FieldPrinter<T>) -> Void) {
  var printer = FieldPrinter(target: value)
  fields(&printer)

  let longestNameCount = printer.fields.map(\.0).max(by: { $0.count < $1.count })!.count

  for (name, value) in printer.fields {
    let paddedName = String(repeating: " ", count: longestNameCount - name.count) + name
    print("\u{1b}[97m\(paddedName)\u{1b}[0m", value)
  }
}
