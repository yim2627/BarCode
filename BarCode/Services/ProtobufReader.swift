import Foundation

/// Minimal Protocol Buffers wire-format reader — only the parts we need
/// for the Google Authenticator migration payload.
///
/// Wire types we handle:
///   0 — varint
///   2 — length-delimited (bytes / string / embedded message)
/// Wire types 1 (64-bit fixed) and 5 (32-bit fixed) are skipped if seen.
struct ProtobufReader {
  let data: Data
  private var offset: Int = 0

  init(_ data: Data) { self.data = data }

  var isAtEnd: Bool { offset >= data.count }

  /// Reads a base-128 varint and advances. Returns nil on EOF or overflow.
  mutating func readVarint() -> UInt64? {
    var result: UInt64 = 0
    var shift: UInt64 = 0
    while offset < data.count {
      let byte = data[offset]
      offset += 1
      result |= UInt64(byte & 0x7F) << shift
      if byte & 0x80 == 0 { return result }
      shift += 7
      if shift >= 64 { return nil }
    }
    return nil
  }

  /// Reads a tag and returns (field number, wire type).
  mutating func readTag() -> (field: Int, wireType: Int)? {
    guard let v = readVarint() else { return nil }
    return (Int(v >> 3), Int(v & 0x07))
  }

  /// Reads a length-prefixed byte sequence (wire type 2).
  mutating func readLengthDelimited() -> Data? {
    guard let len = readVarint() else { return nil }
    let n = Int(len)
    guard n >= 0, offset + n <= data.count else { return nil }
    let slice = data.subdata(in: offset..<(offset + n))
    offset += n
    return slice
  }

  /// Skips the value portion of an unknown field given its wire type.
  mutating func skip(wireType: Int) {
    switch wireType {
    case 0: _ = readVarint()
    case 1: offset += 8
    case 2: _ = readLengthDelimited()
    case 5: offset += 4
    default: offset = data.count   // unknown — bail
    }
    if offset > data.count { offset = data.count }
  }
}
