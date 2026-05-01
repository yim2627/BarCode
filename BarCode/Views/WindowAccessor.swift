import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
  let configure: (NSWindow) -> Void

  func makeNSView(context: Context) -> NSView {
    let view = NSView()
    DispatchQueue.main.async { [weak view] in
      if let window = view?.window {
        configure(window)
      }
    }
    return view
  }

  func updateNSView(_ nsView: NSView, context: Context) {}
}

final class PopoverDismisser {
  static let shared = PopoverDismisser()
  static let didClose = Notification.Name("BarCode.popoverDidClose")
  private var attached = Set<ObjectIdentifier>()

  func attachIfNeeded(to window: NSWindow) {
    let id = ObjectIdentifier(window)
    guard !attached.contains(id) else { return }
    attached.insert(id)

    let close: (NSWindow?) -> Void = { window in
      guard let window, window.isVisible else { return }
      window.orderOut(nil)
      NotificationCenter.default.post(name: PopoverDismisser.didClose, object: nil)
    }

    NotificationCenter.default.addObserver(
      forName: NSWindow.didResignKeyNotification,
      object: window,
      queue: .main
    ) { [weak window] _ in close(window) }

    NotificationCenter.default.addObserver(
      forName: NSApplication.didResignActiveNotification,
      object: nil,
      queue: .main
    ) { [weak window] _ in close(window) }
  }
}
