import Foundation
import Combine

@MainActor
final class AccountStore: ObservableObject {
  @Published private(set) var accounts: [Account] = []
  private let storageKey = "barcode.accounts.v1"

  init() { load() }

  func add(name: String, issuer: String, secret: Data) throws {
    let account = Account(name: name, issuer: issuer)
    try KeychainStore.save(secret: secret, account: account.id.uuidString)
    accounts.append(account)
    persist()
  }

  /// Adds many accounts at once. Returns the number successfully saved.
  /// Failures (e.g. Keychain errors) are skipped rather than aborting the
  /// whole batch.
  @discardableResult
  func addBatch(_ items: [(name: String, issuer: String, secret: Data, digits: Int, period: TimeInterval)]) -> Int {
    var added = 0
    for item in items {
      let account = Account(
        name: item.name,
        issuer: item.issuer,
        digits: item.digits,
        period: item.period
      )
      do {
        try KeychainStore.save(secret: item.secret, account: account.id.uuidString)
        accounts.append(account)
        added += 1
      } catch {
        continue
      }
    }
    if added > 0 { persist() }
    return added
  }

  func remove(_ account: Account) {
    KeychainStore.delete(account: account.id.uuidString)
    accounts.removeAll { $0.id == account.id }
    persist()
  }

  func secret(for account: Account) -> Data? {
    KeychainStore.load(account: account.id.uuidString)
  }

  private func load() {
    guard let data = UserDefaults.standard.data(forKey: storageKey),
          let list = try? JSONDecoder().decode([Account].self, from: data) else { return }
    accounts = list
  }

  private func persist() {
    guard let data = try? JSONEncoder().encode(accounts) else { return }
    UserDefaults.standard.set(data, forKey: storageKey)
  }
}
