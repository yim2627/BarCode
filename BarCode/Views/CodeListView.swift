import SwiftUI

struct CodeListView: View {
  @EnvironmentObject var store: AccountStore
  let requireAuth: Bool
  let onAdd: () -> Void
  let onSettings: () -> Void
  let onLock: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      content
      Divider()
      footer
    }
  }

  private var header: some View {
    HStack(spacing: 4) {
      VStack(alignment: .leading, spacing: 2) {
        Text("Codes").font(.title2.bold())
        Text("\(store.accounts.count) verification \(store.accounts.count == 1 ? "code" : "codes")")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Button(action: onSettings) {
        Image(systemName: "gearshape")
          .font(.title3)
      }
      .buttonStyle(.borderless)
      Button(action: onAdd) {
        Image(systemName: "plus.circle")
          .font(.title2)
      }
      .buttonStyle(.borderless)
    }
    .padding()
  }

  @ViewBuilder
  private var content: some View {
    if store.accounts.isEmpty {
      VStack(spacing: 8) {
        Image(systemName: "key.horizontal")
          .font(.system(size: 36))
          .foregroundStyle(.secondary)
        Text("No accounts yet")
          .font(.subheadline)
          .foregroundStyle(.secondary)
        Text("Tap the + button to add one")
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      ScrollView {
        LazyVStack(spacing: 0) {
          ForEach(store.accounts) { account in
            CodeRow(account: account)
            Divider()
          }
        }
      }
    }
  }

  private var footer: some View {
    HStack(spacing: 12) {
      if requireAuth {
        Button(action: onLock) {
          Label("Lock", systemImage: "lock")
            .font(.caption)
        }
        .buttonStyle(.borderless)
      }
      Spacer()
      Button {
        NSApp.terminate(nil)
      } label: {
        Text("Quit")
          .font(.caption)
      }
      .buttonStyle(.borderless)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
  }
}
