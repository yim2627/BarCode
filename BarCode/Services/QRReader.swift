import AppKit
import Vision

/// Pulls the first QR payload out of an image using the Vision framework.
/// Returns nil if no QR is present or the image can't be decoded.
enum QRReader {
  static func extractText(from image: NSImage) -> String? {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return nil
    }
    return extractText(from: cgImage)
  }

  static func extractText(fromFileURL url: URL) -> String? {
    guard let image = NSImage(contentsOf: url) else { return nil }
    return extractText(from: image)
  }

  private static func extractText(from cgImage: CGImage) -> String? {
    let request = VNDetectBarcodesRequest()
    request.symbologies = [.qr]
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
      try handler.perform([request])
    } catch {
      return nil
    }
    guard let observations = request.results else { return nil }
    for obs in observations {
      if let payload = obs.payloadStringValue, !payload.isEmpty {
        return payload
      }
    }
    return nil
  }
}
