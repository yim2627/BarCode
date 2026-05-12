import Foundation
import ServiceManagement

/// Wraps `SMAppService.mainApp` — Apple's macOS 13+ replacement for
/// the old `SMLoginItemSetEnabled`. Registering adds the running
/// `.app` bundle to the system's login items; macOS then launches it
/// on every login until it's unregistered or the user removes it from
/// System Settings → General → Login Items.
enum LaunchAtLogin {
  /// True if the running app is registered as a login item.
  static var isEnabled: Bool {
    SMAppService.mainApp.status == .enabled
  }

  /// Tries to toggle the login-item registration. Returns `true` on
  /// success. On failure the caller should re-read `isEnabled` to
  /// reflect the actual system state.
  @discardableResult
  static func setEnabled(_ enabled: Bool) -> Bool {
    do {
      if enabled {
        if SMAppService.mainApp.status != .enabled {
          try SMAppService.mainApp.register()
        }
      } else {
        if SMAppService.mainApp.status != .notRegistered {
          try SMAppService.mainApp.unregister()
        }
      }
      return true
    } catch {
      return false
    }
  }
}
