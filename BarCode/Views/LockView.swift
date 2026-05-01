import SwiftUI

struct LockView: View {
  @Binding var unlocked: Bool
  @State private var failed = false

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "lock.fill")
        .font(.system(size: 48))
        .foregroundStyle(.secondary)
      Text("BarCode")
        .font(.title3.bold())
      Text("Authenticate to unlock")
        .font(.caption)
        .foregroundStyle(.secondary)
      if failed {
        Text("Authentication failed")
          .font(.caption)
          .foregroundStyle(.red)
      }
      Button {
        Task { await unlock() }
      } label: {
        Label("Unlock with Touch ID", systemImage: "touchid")
      }
      .buttonStyle(.borderedProminent)
      .keyboardShortcut(.return)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func unlock() async {
    let ok = await Authenticator.authenticate()
    if ok {
      unlocked = true
      failed = false
    } else {
      failed = true
    }
  }
}
