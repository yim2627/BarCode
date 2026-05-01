import SwiftUI
import AppKit

struct CodeRow: View {
  let account: Account
  @EnvironmentObject var store: AccountStore
  @State private var code: String = "------"
  @State private var remaining: TimeInterval = 30
  @State private var copied = false
  @State private var hovering = false
  @State private var confirmingDelete = false

  private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(account.name)
          .font(.headline)
          .lineLimit(1)
        if !account.issuer.isEmpty {
          Text(account.issuer)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
      Spacer()
      if confirmingDelete {
        Button("Cancel") { confirmingDelete = false }
          .buttonStyle(.borderless)
          .keyboardShortcut(.cancelAction)
        Button("Delete") { store.remove(account) }
          .buttonStyle(.borderedProminent)
          .tint(.red)
          .controlSize(.small)
      } else {
        Text(formatted(code))
          .font(.system(.title3, design: .monospaced).weight(.semibold))
          .foregroundStyle(copied ? Color.green : Color.primary)
          .animation(.easeInOut(duration: 0.15), value: copied)
        CountdownRing(remaining: remaining, period: account.period)
          .frame(width: 22, height: 22)
        if hovering {
          Button {
            confirmingDelete = true
          } label: {
            Image(systemName: "trash")
              .symbolRenderingMode(.monochrome)
              .foregroundColor(.red)
              .font(.system(size: 14, weight: .medium))
          }
          .buttonStyle(.plain)
          .help("Delete")
          .transition(.opacity)
        }
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(hovering ? Color.primary.opacity(0.05) : Color.clear)
    .contentShape(Rectangle())
    .onHover { hovering = $0 }
    .onTapGesture {
      if confirmingDelete {
        confirmingDelete = false
      } else {
        copy()
      }
    }
    .contextMenu {
      Button("Copy Code") { copy() }
      Divider()
      Button("Delete", role: .destructive) { confirmingDelete = true }
    }
    .animation(.easeInOut(duration: 0.15), value: hovering)
    .animation(.easeInOut(duration: 0.15), value: confirmingDelete)
    .onAppear { refresh() }
    .onReceive(timer) { _ in refresh() }
  }

  private func refresh() {
    guard let secret = store.secret(for: account) else {
      code = "ERROR"
      return
    }
    let newCode = TOTP.code(
      secret: secret,
      period: account.period,
      digits: account.digits
    )
    code = newCode
    remaining = TOTP.remaining(period: account.period)
  }

  private func copy() {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(code, forType: .string)
    copied = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
    let captured = code
    DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
      if NSPasteboard.general.string(forType: .string) == captured {
        NSPasteboard.general.clearContents()
      }
    }
  }

  private func formatted(_ s: String) -> String {
    guard s.count == 6 else { return s }
    let mid = s.index(s.startIndex, offsetBy: 3)
    return String(s[s.startIndex..<mid]) + " " + String(s[mid..<s.endIndex])
  }
}
