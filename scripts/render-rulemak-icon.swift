import AppKit
import Foundation

func drawIcon(size: CGFloat, path: String) {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fputs("could not create bitmap for \(path)\n", stderr)
        exit(1)
    }

    guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
        fputs("could not create graphics context for \(path)\n", stderr)
        exit(1)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.shouldAntialias = true

    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    let scale = size / 64.0
    let badgeRect = NSRect(x: 0.5 * scale, y: 5.0 * scale, width: 63.0 * scale, height: 54.0 * scale)
    let radius = 9.0 * scale
    let badge = NSBezierPath(roundedRect: badgeRect, xRadius: radius, yRadius: radius)

    NSColor(calibratedWhite: 0.90, alpha: 1.0).setFill()
    badge.fill()

    badge.lineWidth = max(0.65 * scale, 0.5)
    NSColor(calibratedWhite: 0.78, alpha: 1.0).setStroke()
    badge.stroke()

    let fontSize = 34.0 * scale
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
        .foregroundColor: NSColor(calibratedWhite: 0.08, alpha: 1.0),
    ]

    let label = "RU" as NSString
    let labelSize = label.size(withAttributes: attrs)
    let labelPoint = NSPoint(
        x: badgeRect.midX - labelSize.width / 2.0,
        y: badgeRect.midY - labelSize.height / 2.0 - 1.2 * scale
    )
    label.draw(at: labelPoint, withAttributes: attrs)

    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: .png, properties: [:]) else {
        fputs("could not render png for \(path)\n", stderr)
        exit(1)
    }
    try! png.write(to: URL(fileURLWithPath: path), options: .atomic)
}

let args = CommandLine.arguments
guard args.count == 2 else {
    fputs("usage: render-rulemak-icon <iconset-dir>\n", stderr)
    exit(64)
}

let outDir = args[1]
do {
    try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
} catch {
    fputs("mkdir failed: \(error.localizedDescription)\n", stderr)
    exit(1)
}

let files: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for (file, size) in files {
    drawIcon(size: size, path: (outDir as NSString).appendingPathComponent(file))
}
drawIcon(size: 256, path: (outDir as NSString).appendingPathComponent("preview.png"))
