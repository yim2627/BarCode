import Foundation

enum Base32 {
  private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")

  static func decode(_ input: String) -> Data? {
    let cleaned = input.uppercased().filter { !$0.isWhitespace && $0 != "=" && $0 != "-" }
    guard !cleaned.isEmpty else { return nil }

    var bits = ""
    for ch in cleaned {
      guard let idx = alphabet.firstIndex(of: ch) else { return nil }
      bits += String(idx, radix: 2).leftPadded(to: 5)
    }

    var bytes = Data()
    var i = bits.startIndex
    while bits.distance(from: i, to: bits.endIndex) >= 8 {
      let end = bits.index(i, offsetBy: 8)
      let chunk = String(bits[i..<end])
      guard let byte = UInt8(chunk, radix: 2) else { return nil }
      bytes.append(byte)
      i = end
    }
    return bytes
  }
}

private extension String {
  func leftPadded(to length: Int) -> String {
    count >= length ? self : String(repeating: "0", count: length - count) + self
  }
}
