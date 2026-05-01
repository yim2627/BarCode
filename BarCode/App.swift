import SwiftUI
import AppKit

@main
struct BarCodeApp: App {
  @StateObject private var store = AccountStore()
  @State private var unlocked = false

  var body: some Scene {
    MenuBarExtra {
      ContentView(unlocked: $unlocked)
        .environmentObject(store)
        .frame(width: 320, height: 420, alignment: .top)
        .background(
          WindowAccessor { window in
            PopoverDismisser.shared.attachIfNeeded(to: window)
          }
        )
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.screensDidSleepNotification)) { _ in
          unlocked = false
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.sessionDidResignActiveNotification)) { _ in
          unlocked = false
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.willSleepNotification)) { _ in
          unlocked = false
        }
        .onReceive(DistributedNotificationCenter.default().publisher(for: Notification.Name("com.apple.screenIsLocked"))) { _ in
          unlocked = false
        }
    } label: {
      Image(systemName: "key.fill")
    }
    .menuBarExtraStyle(.window)
  }
}

struct ContentView: View {
  @Binding var unlocked: Bool
  @EnvironmentObject var store: AccountStore
  @AppStorage("requireAuth") private var requireAuth = false
  @State private var route: Route = .list

  enum Route { case list, add, settings }

  var body: some View {
    if requireAuth && !unlocked {
      LockView(unlocked: $unlocked)
    } else {
      switch route {
      case .list:
        CodeListView(
          requireAuth: requireAuth,
          onAdd: { route = .add },
          onSettings: { route = .settings },
          onLock: { unlocked = false }
        )
      case .add:
        AddAccountView(onDone: { route = .list })
      case .settings:
        SettingsView(onDone: { route = .list })
      }
    }
  }
}
