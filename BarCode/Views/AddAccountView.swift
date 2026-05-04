import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct AddAccountView: View {
  @EnvironmentObject var store: AccountStore
  let onDone: () -> Void

  @State private var name = ""
  @State private var issuer = ""
  @State private var secretInput = ""
  @State private var error = ""
  @State private var migrationPreview: [MigrationURL.ParsedAccount]?
  @FocusState private var focused: Field?

  enum Field { case name, issuer, secret }

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      ScrollView {
        if let preview = migrationPreview {
          migrationView(preview)
        } else {
          formView
        }
      }
    }
    .onAppear {
      focused = .name
      // Keep the popover visible while the user fetches a QR
      // screenshot from another app.
      PopoverDismisser.shared.suspend()
    }
    .onDisappear {
      PopoverDismisser.shared.resume()
    }
  }

  private var header: some View {
    HStack {
      Button(action: leftAction) {
        Image(systemName: "chevron.left")
        Text(migrationPreview != nil ? "Back" : "Cancel")
      }
      .buttonStyle(.borderless)
      .keyboardShortcut(.cancelAction)
      Spacer()
      if let preview = migrationPreview {
        let importable = preview.filter(\.isTOTP).count
        Button("Import \(importable)") { importMigration(preview) }
          .keyboardShortcut(.defaultAction)
          .buttonStyle(.borderedProminent)
          .disabled(importable == 0)
      } else {
        Button("Save") { save() }
          .keyboardShortcut(.defaultAction)
          .buttonStyle(.borderedProminent)
          .disabled(secretInput.isEmpty || (!isMigrationURL && name.isEmpty))
      }
    }
    .padding(10)
    .overlay(
      Text(migrationPreview != nil ? "Import Authenticator" : "Add Account")
        .font(.headline)
    )
  }

  private var formView: some View {
    VStack(alignment: .leading, spacing: 14) {
      labeled("Name") {
        TextField("e.g. User", text: $name)
          .focused($focused, equals: .name)
      }
      labeled("Issuer (optional)") {
        TextField("e.g. Amazon", text: $issuer)
          .focused($focused, equals: .issuer)
      }
      labeled("Seed key, otpauth URL, or migration URL") {
        TextField("key, otpauth://..., or otpauth-migration://...", text: $secretInput, axis: .vertical)
          .lineLimit(1...3)
          .font(.system(.body, design: .monospaced))
          .focused($focused, equals: .secret)
      }
      Button {
        chooseQRImage()
      } label: {
        Label("Read QR from image…", systemImage: "qrcode.viewfinder")
      }
      .buttonStyle(.bordered)
      .controlSize(.small)
      if !error.isEmpty {
        Text(error)
          .font(.caption)
          .foregroundStyle(.red)
      }
      Text("Pick a QR screenshot (e.g. Google Authenticator's Export QR) and BarCode fills the field for you. You can also paste a Base32 seed, an otpauth:// URL, or an otpauth-migration:// URL.")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.top, 4)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private func migrationView(_ accounts: [MigrationURL.ParsedAccount]) -> some View {
    let importable = accounts.filter(\.isTOTP).count
    let skipped = accounts.count - importable

    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text("\(importable) account\(importable == 1 ? "" : "s") ready to import")
          .font(.subheadline.weight(.semibold))
        if skipped > 0 {
          Text("\(skipped) HOTP account\(skipped == 1 ? "" : "s") will be skipped — BarCode supports TOTP only.")
            .font(.caption2)
            .foregroundStyle(.orange)
        }
      }

      VStack(spacing: 0) {
        ForEach(Array(accounts.enumerated()), id: \.offset) { idx, acc in
          HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
              Text(acc.name.isEmpty ? "(no name)" : acc.name)
                .font(.body)
                .lineLimit(1)
              if !acc.issuer.isEmpty {
                Text(acc.issuer)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .lineLimit(1)
              }
            }
            Spacer()
            if !acc.isTOTP {
              Text("HOTP")
                .font(.caption2)
                .foregroundStyle(.orange)
            }
          }
          .padding(.vertical, 6)
          if idx < accounts.count - 1 { Divider() }
        }
      }

      if !error.isEmpty {
        Text(error).font(.caption).foregroundStyle(.red)
      }
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var isMigrationURL: Bool {
    secretInput
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
      .hasPrefix("otpauth-migration://")
  }

  private func leftAction() {
    if migrationPreview != nil {
      migrationPreview = nil
      // Clear the URL — it contains every secret in plaintext.
      secretInput = ""
      error = ""
    } else {
      onDone()
    }
  }

  @ViewBuilder
  private func labeled<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(label)
        .font(.caption)
        .foregroundStyle(.secondary)
      content()
        .textFieldStyle(.roundedBorder)
    }
  }

  private func save() {
    let trimmed = secretInput.trimmingCharacters(in: .whitespacesAndNewlines)

    // Migration URL → switch to preview mode rather than committing
    if trimmed.lowercased().hasPrefix("otpauth-migration://") {
      guard let parsed = MigrationURL.parse(trimmed), !parsed.isEmpty else {
        error = "Invalid migration URL"
        return
      }
      error = ""
      migrationPreview = parsed
      return
    }

    let trimmedName = name.trimmingCharacters(in: .whitespaces)
    guard !trimmedName.isEmpty else {
      error = "Please enter a name"
      return
    }
    let parsed = parseSecret(secretInput)
    guard let secret = parsed.secret, !secret.isEmpty else {
      error = "Invalid Base32 seed key"
      return
    }
    let finalIssuer = parsed.issuer ?? issuer.trimmingCharacters(in: .whitespaces)
    let finalName = parsed.name ?? trimmedName
    do {
      try store.add(name: finalName, issuer: finalIssuer, secret: secret)
      onDone()
    } catch let saveError {
      error = saveError.localizedDescription
    }
  }

  private func importMigration(_ accounts: [MigrationURL.ParsedAccount]) {
    let items = accounts
      .filter(\.isTOTP)
      .map { acc -> (name: String, issuer: String, secret: Data, digits: Int, period: TimeInterval) in
        (
          name: acc.name.isEmpty ? "Imported" : acc.name,
          issuer: acc.issuer,
          secret: acc.secret,
          digits: acc.digits,
          period: 30
        )
      }
    guard !items.isEmpty else {
      error = "Nothing to import"
      return
    }
    let added = store.addBatch(items)
    if added == 0 {
      error = "Failed to save any account to the Keychain"
    } else {
      onDone()
    }
  }

  // MARK: - QR image picker

  private func chooseQRImage() {
    // LSUIElement apps need to activate before showing a panel,
    // otherwise the panel never receives focus on macOS 14+.
    NSApp.activate(ignoringOtherApps: true)

    let panel = NSOpenPanel()
    panel.title = "Choose a QR image"
    panel.message = "Pick a QR screenshot saved on this Mac."
    panel.allowedContentTypes = [.image]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.level = .modalPanel

    panel.begin { response in
      guard response == .OK, let url = panel.url else { return }
      guard let image = NSImage(contentsOf: url) else {
        error = "Could not read the selected image"
        return
      }
      processQRImage(image)
    }
  }

  private func processQRImage(_ image: NSImage) {
    guard let payload = QRReader.extractText(from: image) else {
      error = "No QR code found in the image"
      return
    }
    error = ""
    secretInput = payload

    let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.lowercased().hasPrefix("otpauth-migration://") {
      if let parsed = MigrationURL.parse(trimmed), !parsed.isEmpty {
        migrationPreview = parsed
      } else {
        error = "Migration URL detected but could not be parsed"
      }
    } else if trimmed.lowercased().hasPrefix("otpauth://") {
      let parsed = parseSecret(trimmed)
      if let labelName = parsed.name, name.isEmpty { name = labelName }
      if let labelIssuer = parsed.issuer, issuer.isEmpty { issuer = labelIssuer }
    }
  }

  private func parseSecret(_ raw: String) -> (secret: Data?, name: String?, issuer: String?) {
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.lowercased().hasPrefix("otpauth://"),
       let url = URL(string: trimmed),
       let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
      let items = comps.queryItems ?? []
      let secretRaw = items.first(where: { $0.name.lowercased() == "secret" })?.value ?? ""
      let issuerFromQuery = items.first(where: { $0.name.lowercased() == "issuer" })?.value
      let path = comps.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
      var labelIssuer: String?
      var labelName: String?
      if let colonIdx = path.firstIndex(of: ":") {
        labelIssuer = String(path[..<colonIdx]).removingPercentEncoding
        labelName = String(path[path.index(after: colonIdx)...]).removingPercentEncoding
      } else {
        labelName = path.removingPercentEncoding
      }
      return (Base32.decode(secretRaw), labelName, issuerFromQuery ?? labelIssuer)
    }
    return (Base32.decode(trimmed), nil, nil)
  }
}
