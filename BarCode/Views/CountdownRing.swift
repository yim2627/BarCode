import SwiftUI

struct CountdownRing: View {
  let remaining: TimeInterval
  let period: TimeInterval

  private var progress: Double {
    max(0, min(1, remaining / period))
  }

  private var color: Color {
    if remaining < 5 { return .red }
    if remaining < 10 { return .orange }
    return .green
  }

  var body: some View {
    ZStack {
      Circle()
        .stroke(color.opacity(0.2), lineWidth: 3)
      Circle()
        .trim(from: 0, to: progress)
        .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .animation(.linear(duration: 0.1), value: progress)
    }
  }
}
