import Foundation

/// Decodes Google Authenticator's "Transfer accounts" payload:
///   otpauth-migration://offline?data=<base64-encoded-protobuf>
///
/// Schema (reverse-engineered, public domain):
///   message MigrationPayload {
///     repeated OtpParameters otp_parameters = 1;
///     int32 version       = 2;
///     int32 batch_size    = 3;
///     int32 batch_index   = 4;
///     int32 batch_id      = 5;
///   }
///   message OtpParameters {
///     bytes  secret    = 1;
///     string name      = 2;
///     string issuer    = 3;
///     enum Algorithm   = 4;   // 1=SHA1, 2=SHA256, 3=SHA512, 4=MD5
///     enum DigitCount  = 5;   // 1=six, 2=eight
///     enum OtpType     = 6;   // 1=HOTP, 2=TOTP
///     int64 counter    = 7;   // HOTP only
///   }
///
/// BarCode is TOTP-only; HOTP entries are flagged so the UI can skip them.
enum MigrationURL {
  struct ParsedAccount {
    let name: String
    let issuer: String
    let secret: Data
    let digits: Int
    let isTOTP: Bool
  }

  static func parse(_ string: String) -> [ParsedAccount]? {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.lowercased().hasPrefix("otpauth-migration://"),
          let url = URL(string: trimmed),
          let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let dataParam = comps.queryItems?.first(where: { $0.name.lowercased() == "data" })?.value,
          let payload = decodeBase64(dataParam) else { return nil }

    return decodePayload(payload)
  }

  /// Base64 with URL-safe alternate characters and missing padding tolerated.
  private static func decodeBase64(_ string: String) -> Data? {
    let normalised = string
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    var padded = normalised
    let mod = padded.count % 4
    if mod > 0 { padded += String(repeating: "=", count: 4 - mod) }
    return Data(base64Encoded: padded)
  }

  private static func decodePayload(_ data: Data) -> [ParsedAccount]? {
    var reader = ProtobufReader(data)
    var accounts: [ParsedAccount] = []

    while !reader.isAtEnd {
      guard let tag = reader.readTag() else { return nil }
      if tag.field == 1 && tag.wireType == 2 {
        guard let inner = reader.readLengthDelimited(),
              let account = decodeOtpParameters(inner) else { continue }
        accounts.append(account)
      } else {
        reader.skip(wireType: tag.wireType)
      }
    }
    return accounts
  }

  private static func decodeOtpParameters(_ data: Data) -> ParsedAccount? {
    var reader = ProtobufReader(data)
    var secret = Data()
    var name = ""
    var issuer = ""
    var digits = 6
    var isTOTP = true   // assume TOTP if the type field is missing or unspecified

    while !reader.isAtEnd {
      guard let tag = reader.readTag() else { return nil }
      switch (tag.field, tag.wireType) {
      case (1, 2):
        if let bytes = reader.readLengthDelimited() { secret = bytes }
      case (2, 2):
        if let bytes = reader.readLengthDelimited(),
           let s = String(data: bytes, encoding: .utf8) { name = s }
      case (3, 2):
        if let bytes = reader.readLengthDelimited(),
           let s = String(data: bytes, encoding: .utf8) { issuer = s }
      case (4, 0):
        // algorithm — BarCode only generates SHA1, so we read and discard.
        // Non-SHA1 entries will produce wrong codes; the UI shows a warning.
        _ = reader.readVarint()
      case (5, 0):
        if let v = reader.readVarint() {
          digits = (v == 2) ? 8 : 6
        }
      case (6, 0):
        if let v = reader.readVarint() {
          isTOTP = (v != 1)   // 1 = HOTP, anything else treated as TOTP
        }
      default:
        reader.skip(wireType: tag.wireType)
      }
    }

    guard !secret.isEmpty else { return nil }
    return ParsedAccount(
      name: name,
      issuer: issuer,
      secret: secret,
      digits: digits,
      isTOTP: isTOTP
    )
  }
}
