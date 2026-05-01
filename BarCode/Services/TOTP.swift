import Foundation
import CryptoKit

enum TOTP {
  static func code(
    secret: Data,
    time: Date = Date(),
    period: TimeInterval = 30,
    digits: Int = 6
  ) -> String {
    let counter = UInt64(time.timeIntervalSince1970 / period)
    var be = counter.bigEndian
    let counterData = Data(bytes: &be, count: 8)

    let key = SymmetricKey(data: secret)
    let mac = HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: key)
    let hmac = Data(mac)

    let offset = Int(hmac[hmac.count - 1] & 0x0f)
    let truncated =
      (UInt32(hmac[offset] & 0x7f) << 24) |
      (UInt32(hmac[offset + 1]) << 16) |
      (UInt32(hmac[offset + 2]) << 8) |
       UInt32(hmac[offset + 3])

    let modulus = UInt32(pow(10.0, Double(digits)))
    let code = truncated % modulus
    return String(format: "%0\(digits)d", code)
  }

  static func remaining(time: Date = Date(), period: TimeInterval = 30) -> TimeInterval {
    period - time.timeIntervalSince1970.truncatingRemainder(dividingBy: period)
  }
}
