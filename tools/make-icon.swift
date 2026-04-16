#!/usr/bin/env swift
import AppKit

let outputDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"

let slices: [(name: String, size: Int)] = [
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

func render(size: Int) -> Data {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    // Rounded square background
    let cornerRadius = s * 0.2237  // Apple squircle-ish
    let bgRect = NSRect(x: 0, y: 0, width: s, height: s)
    let bg = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.13, alpha: 1.0),
        NSColor(calibratedRed: 0.04, green: 0.04, blue: 0.05, alpha: 1.0),
    ])!
    gradient.draw(in: bg, angle: -90)

    // Bar chart: 4 bars, rightmost in accent green
    let barCount = 4
    let margin = s * 0.22
    let gap = s * 0.055
    let chartW = s - margin * 2
    let barW = (chartW - gap * CGFloat(barCount - 1)) / CGFloat(barCount)
    let maxH = s * 0.52
    let baseY = s * 0.24
    let heights: [CGFloat] = [0.42, 0.68, 0.32, 1.0]
    let accent = NSColor(calibratedRed: 0.35, green: 0.86, blue: 0.48, alpha: 1.0)
    let barR = barW * 0.22

    for i in 0..<barCount {
        let h = maxH * heights[i]
        let x = margin + CGFloat(i) * (barW + gap)
        let rect = NSRect(x: x, y: baseY, width: barW, height: h)
        let path = NSBezierPath(roundedRect: rect, xRadius: barR, yRadius: barR)
        if i == barCount - 1 {
            accent.setFill()
        } else {
            NSColor.white.withAlphaComponent(0.86).setFill()
        }
        path.fill()
    }

    // Live dot above the accent bar
    let dotSize = s * 0.085
    let lastX = margin + CGFloat(barCount - 1) * (barW + gap)
    let dotRect = NSRect(
        x: lastX + (barW - dotSize) / 2,
        y: baseY + maxH + s * 0.025,
        width: dotSize, height: dotSize
    )
    accent.setFill()
    NSBezierPath(ovalIn: dotRect).fill()

    image.unlockFocus()
    let tiff = image.tiffRepresentation!
    let rep = NSBitmapImageRep(data: tiff)!
    return rep.representation(using: .png, properties: [:])!
}

let fm = FileManager.default
try? fm.removeItem(atPath: outputDir)
try fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

for (name, size) in slices {
    let data = render(size: size)
    let path = "\(outputDir)/\(name)"
    try data.write(to: URL(fileURLWithPath: path))
    print("  \(name) (\(size)px)")
}

print("Wrote iconset: \(outputDir)")
