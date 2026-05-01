import SwiftUI

struct SettingsView: View {
	let onDone: () -> Void
	@AppStorage("requireAuth") private var requireAuth = false
	
	var body: some View {
		VStack(alignment: .center) {
			header
			Divider()
			VStack(spacing: 0) {
				VStack(alignment: .leading, spacing: 18) {
					section("Security") {
						HStack(alignment: .center, spacing: 12) {
							VStack(alignment: .leading, spacing: 2) {
								Text("Require Touch ID")
									.font(.body)
								Text("Authenticate when opening the app. Auto-locks on screen lock or sleep.")
									.font(.caption)
									.foregroundStyle(.secondary)
									.fixedSize(horizontal: false, vertical: true)
							}
							Spacer()
							Toggle("", isOn: $requireAuth)
								.toggleStyle(.switch)
								.labelsHidden()
						}
					}
					section("About") {
						HStack {
							Text("BarCode")
							Spacer()
							Text("v1.0").foregroundStyle(.secondary)
						}
						.font(.caption)
					}
				}
				.padding()
				.frame(maxWidth: .infinity, alignment: .leading)
				Spacer()
			}
		}
	}
	
	private var header: some View {
		HStack {
			Button(action: onDone) {
				Image(systemName: "chevron.left")
			}
			.buttonStyle(.borderless)
			.keyboardShortcut(.cancelAction)
			Spacer()
		}
		.padding(10)
		.overlay(
			Text("Settings").font(.headline)
		)
	}
	
	@ViewBuilder
	private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(title)
				.font(.caption.weight(.semibold))
				.foregroundStyle(.secondary)
			content()
		}
	}
}
