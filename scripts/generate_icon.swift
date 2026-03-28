import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    fputs("Usage: generate_icon.swift <output-png-path>\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: arguments[1])
let size = NSSize(width: 1024, height: 1024)

let image = NSImage(size: size)
image.lockFocus()

let rect = NSRect(origin: .zero, size: size)

let background = NSBezierPath(roundedRect: rect, xRadius: 230, yRadius: 230)
NSColor(calibratedRed: 0.0, green: 0.38, blue: 0.58, alpha: 1.0).setFill()
background.fill()

let chevron = NSBezierPath()
chevron.lineWidth = 86
chevron.lineCapStyle = .round
chevron.lineJoinStyle = .round
chevron.move(to: NSPoint(x: 290, y: 660))
chevron.line(to: NSPoint(x: 470, y: 512))
chevron.line(to: NSPoint(x: 290, y: 364))
NSColor.white.setStroke()
chevron.stroke()

let promptLine = NSBezierPath()
promptLine.lineWidth = 86
promptLine.lineCapStyle = .round
promptLine.move(to: NSPoint(x: 545, y: 364))
promptLine.line(to: NSPoint(x: 760, y: 364))
NSColor(calibratedRed: 0.31, green: 0.86, blue: 0.78, alpha: 1.0).setStroke()
promptLine.stroke()

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Failed to render PNG data.\n", stderr)
    exit(1)
}

try pngData.write(to: outputURL)
