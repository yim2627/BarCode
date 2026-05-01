import Foundation

struct Account: Identifiable, Codable, Equatable {
  let id: UUID
  var name: String
  var issuer: String
  var digits: Int
  var period: TimeInterval

  init(
    id: UUID = UUID(),
    name: String,
    issuer: String = "",
    digits: Int = 6,
    period: TimeInterval = 30
  ) {
    self.id = id
    self.name = name
    self.issuer = issuer
    self.digits = digits
    self.period = period
  }
}
