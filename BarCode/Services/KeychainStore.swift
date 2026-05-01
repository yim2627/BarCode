import Foundation
import Security

enum KeychainError: Error, LocalizedError {
  case saveFailed(OSStatus)

  var errorDescription: String? {
    switch self {
    case .saveFailed(let status):
      let msg = SecCopyErrorMessageString(status, nil) as String? ?? "unknown"
      return "Keychain save failed (status \(status)): \(msg)"
    }
  }
}

enum KeychainStore {
  static let service = "com.jiseong.BarCode.totp"

  static func save(secret: Data, account: String) throws {
    let deleteQuery: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    SecItemDelete(deleteQuery as CFDictionary)

    let attrs: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecValueData as String: secret,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
    ]
    let status = SecItemAdd(attrs as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw KeychainError.saveFailed(status)
    }
  }

  static func load(account: String) -> Data? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    var result: AnyObject?
    guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
    return result as? Data
  }

  static func delete(account: String) {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
    SecItemDelete(query as CFDictionary)
  }
}
