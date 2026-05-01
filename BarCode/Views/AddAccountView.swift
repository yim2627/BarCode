import SwiftUI

struct AddAccountView: View {
  @EnvironmentObject var store: AccountStore
  let onDone: () -> Void

  @State private var name = ""
  @State private var issuer = ""
  @State private var secretInput = ""
  @State private var error = ""
  @FocusState private var focused: Field?

  enum Field { case name, issuer, secret }

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          labeled("Name") {
            TextField("e.g. User", text: $name)
              .focused($focused, equals: .name)
          }
          labeled("Issuer (optional)") {
            TextField("e.g. Amazon", text: $issuer)
              .focused($focused, equals: .issuer)
          }
          labeled("Seed key or otpauth URL") {
            TextField("key or otpauth://...", text: $secretInput, axis: .vertical)
              .lineLimit(1...3)
              .font(.system(.body, design: .monospaced))
              .focused($focused, equals: .secret)
          }
          if !error.isEmpty {
            Text(error)
              .font(.caption)
              .foregroundStyle(.red)
          }
          Text("Right-click a Passwords app entry → \"Copy Setup Code\" and paste it here. otpauth URLs are auto-parsed.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .onAppear { focused = .name }
  }

  private var header: some View {
    HStack {
      Button(action: onDone) {
        Image(systemName: "chevron.left")
        Text("Cancel")
      }
      .buttonStyle(.borderless)
      .keyboardShortcut(.cancelAction)
      Spacer()
      Button("Save") { save() }
        .keyboardShortcut(.defaultAction)
        .buttonStyle(.borderedProminent)
        .disabled(name.isEmpty || secretInput.isEmpty)
    }
    .padding(10)
    .overlay(
      Text("Add Account").font(.headline)
    )
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
