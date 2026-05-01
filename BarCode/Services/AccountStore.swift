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
