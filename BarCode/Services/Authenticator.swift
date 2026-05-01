import LocalAuthentication

enum Authenticator {
  static func authenticate(reason: String = "Unlock BarCode") async -> Bool {
    let context = LAContext()
    context.localizedFallbackTitle = "Use Password"
    var error: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
      return false
    }
    do {
      return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
    } catch {
      return false
    }
  }
}
