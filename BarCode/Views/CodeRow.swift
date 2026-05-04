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
  @State private var cachedSecret: Data?
  @State private var lastCounter: UInt64 = .max
  @State private var isAppActive: Bool = NSApp.isActive

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
    .onAppear { refresh(force: true) }
    .onReceive(timer) { _ in if isAppActive { refresh() } }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
      isAppActive = true
      refresh(force: true)
    }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
      isAppActive = false
    }
  }

  /// Recomputes the displayed code and the countdown.
  ///
  /// HMAC + Keychain access only happen when the time-step counter
  /// rolls over (every `period` seconds) or when explicitly forced.
  /// In between, we only update `remaining` — cheap arithmetic — so
  /// the ring keeps animating without burning the CPU.
  private func refresh(force: Bool = false) {
    if cachedSecret == nil {
      cachedSecret = store.secret(for: account)
    }
    guard let secret = cachedSecret else {
      code = "ERROR"
      return
    }
    let now = Date()
    let counter = UInt64(now.timeIntervalSince1970 / account.period)
    if force || counter != lastCounter {
      code = TOTP.code(
        secret: secret,
        time: now,
        period: account.period,
        digits: account.digits
      )
      lastCounter = counter
    }
    remaining = TOTP.remaining(time: now, period: account.period)
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
