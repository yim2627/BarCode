import AppKit

func makeIcon(size px: Int) -> Data {
  let s = CGFloat(px)
  let img = NSImage(size: NSSize(width: s, height: s))
  img.lockFocus()

  // Background — rounded square with vertical gradient (deep navy → near black)
  let bgPath = NSBezierPath(
    roundedRect: NSRect(x: 0, y: 0, width: s, height: s),
    xRadius: s * 0.225, yRadius: s * 0.225
  )
  bgPath.setClip()

  let gradient = NSGradient(colors: [
    NSColor(srgbRed: 0.20, green: 0.24, blue: 0.40, alpha: 1.0),
    NSColor(srgbRed: 0.05, green: 0.07, blue: 0.14, alpha: 1.0)
  ])!
  gradient.draw(in: NSRect(x: 0, y: 0, width: s, height: s), angle: -90)

  // Subtle inner highlight at the top
  let highlight = NSGradient(colors: [
    NSColor(white: 1, alpha: 0.10),
    NSColor(white: 1, alpha: 0.0)
  ])!
  highlight.draw(in: NSRect(x: 0, y: s * 0.6, width: s, height: s * 0.4), angle: -90)

  // Key glyph — bow (ring) on top, shaft + teeth below, centered
  NSColor.white.set()

  let cx = s / 2
  let bowOuter = s * 0.30
  let bowInner = s * 0.12
  let bowCenterY = s * 0.65

  let bowOuterRect = NSRect(
    x: cx - bowOuter / 2,
    y: bowCenterY - bowOuter / 2,
    width: bowOuter, height: bowOuter
  )
  NSBezierPath(ovalIn: bowOuterRect).fill()

  // Bow hole (knock out by drawing background color)
  let bowInnerRect = NSRect(
    x: cx - bowInner / 2,
    y: bowCenterY - bowInner / 2,
    width: bowInner, height: bowInner
  )
  NSColor(srgbRed: 0.07, green: 0.10, blue: 0.18, alpha: 1.0).set()
  NSBezierPath(ovalIn: bowInnerRect).fill()

  // Shaft + teeth in white
  NSColor.white.set()

  let shaftWidth = s * 0.10
  let shaftTop = bowCenterY - bowOuter / 2
  let shaftBottom = s * 0.16
  let shaftRect = NSRect(
    x: cx - shaftWidth / 2,
    y: shaftBottom,
    width: shaftWidth,
    height: shaftTop - shaftBottom
  )
  NSBezierPath(rect: shaftRect).fill()

  // Two teeth jutting to the right
  let toothW = s * 0.10
  let toothH = s * 0.05
  let toothX = cx + shaftWidth / 2
  NSBezierPath(rect: NSRect(
    x: toothX, y: shaftBottom + s * 0.05,
    width: toothW, height: toothH
  )).fill()
  NSBezierPath(rect: NSRect(
    x: toothX, y: shaftBottom + s * 0.14,
    width: toothW * 0.7, height: toothH
  )).fill()

  img.unlockFocus()

  let tiff = img.tiffRepresentation!
  let rep = NSBitmapImageRep(data: tiff)!
  return rep.representation(using: .png, properties: [:])!
}

let sizes: [(String, Int)] = [
  ("16x16", 16),
  ("16x16@2x", 32),
  ("32x32", 32),
  ("32x32@2x", 64),
  ("128x128", 128),
  ("128x128@2x", 256),
  ("256x256", 256),
  ("256x256@2x", 512),
  ("512x512", 512),
  ("512x512@2x", 1024),
]

guard let outDir = CommandLine.arguments.dropFirst().first else {
  FileHandle.standardError.write("usage: swift generate-icon.swift <output-iconset-dir>\n".data(using: .utf8)!)
  exit(1)
}

let fm = FileManager.default
try? fm.removeItem(atPath: outDir)
try fm.createDirectory(atPath: outDir, withIntermediateDirectories: true)

for (name, px) in sizes {
  let data = makeIcon(size: px)
  let url = URL(fileURLWithPath: "\(outDir)/icon_\(name).png")
  try data.write(to: url)
  print("wrote \(url.lastPathComponent)")
}
