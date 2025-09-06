@_spi(Formatting)
public extension FixedWidthInteger {
  var formattedAddress: String {
    // NOTE: Avoiding String(format: "...") which is a Foundation method.
    var hexed = String(self, radix: 16, uppercase: false)

    do {
      let inserting = 16 - hexed.count
      if inserting > 0 {
        hexed = String(repeating: "0", count: inserting) + hexed
      }
    }

    return "0x\(hexed)"
  }
}
