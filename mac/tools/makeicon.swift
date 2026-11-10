import AppKit
import Foundation

// App 图标：深色圆角底 + 一支斜放的香烟（白色烟身、橙色过滤嘴、红色烟头）+ 两缕飘烟
let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func render(_ px: Int) -> Data {
    let size = NSSize(width: px, height: px)
    let image = NSImage(size: size)
    image.lockFocus()

    let s = CGFloat(px) / 1024.0
    let r = { (v: CGFloat) -> CGFloat in v * s }

    // ---- 背景：深色圆角方 ----
    let inset = r(46)
    let bgRect = NSRect(x: inset, y: inset, width: CGFloat(px) - inset * 2, height: CGFloat(px) - inset * 2)
    let bg = NSBezierPath(roundedRect: bgRect, xRadius: r(225), yRadius: r(225))
    NSGradient(colors: [
        NSColor(calibratedRed: 0.13, green: 0.15, blue: 0.20, alpha: 1),
        NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.11, alpha: 1),
    ])!.draw(in: bg, angle: -90)

    // ---- 香烟（以 1024 画布坐标绘制，整体旋转 12°）----
    NSGraphicsContext.saveGraphicsState()
    let t = NSAffineTransform()
    t.translateX(by: r(512), yBy: r(470))
    t.rotate(byDegrees: 12)
    t.translateX(by: -r(512), yBy: -r(470))
    t.concat()

    let bodyRect = NSRect(x: r(200), y: r(415), width: r(630), height: r(110))
    let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: r(16), yRadius: r(16))

    // 微弱投影
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
    shadow.shadowOffset = NSSize(width: 0, height: -r(14))
    shadow.shadowBlurRadius = r(28)
    NSGraphicsContext.current!.saveGraphicsState()
    shadow.set()

    // 烟身：米白
    NSColor(calibratedRed: 0.96, green: 0.94, blue: 0.90, alpha: 1).setFill()
    bodyPath.fill()

    // 过滤嘴：橙色（右端，带圆角），与烟身分隔线
    let filterRect = NSRect(x: r(630), y: r(415), width: r(200), height: r(110))
    let filterPath = NSBezierPath(roundedRect: filterRect, xRadius: r(16), yRadius: r(16))
    NSGradient(colors: [
        NSColor(calibratedRed: 0.93, green: 0.55, blue: 0.25, alpha: 1),
        NSColor(calibratedRed: 0.80, green: 0.36, blue: 0.14, alpha: 1),
    ])!.draw(in: filterPath, angle: -90)
    // 分隔线
    NSColor(calibratedRed: 0.55, green: 0.33, blue: 0.18, alpha: 1).setFill()
    NSRect(x: r(622), y: r(415), width: r(12), height: r(110)).fill()

    // 烟头：左端深红 + 灰白烟灰圈
    NSColor(calibratedRed: 0.72, green: 0.20, blue: 0.09, alpha: 1).setFill()
    NSRect(x: r(200), y: r(415), width: r(26), height: r(110))
        .fill(using: .sourceOver)
    NSColor(calibratedRed: 0.85, green: 0.83, blue: 0.78, alpha: 1).setFill()
    NSRect(x: r(226), y: r(415), width: r(20), height: r(110)).fill()

    NSGraphicsContext.current!.restoreGraphicsState()

    // 烟头火光（未旋转坐标：先算烟头位置）
    let tipX = r(512) - r(280) * cos(12 * .pi / 180)
    let tipY = r(470) - r(280) * sin(12 * .pi / 180)
    for (radius, alpha) in [(70.0, 0.16), (40.0, 0.28), (20.0, 0.5)] {
        let glow = NSBezierPath(ovalIn: NSRect(x: tipX - r(radius), y: tipY - r(radius),
                                               width: r(radius) * 2, height: r(radius) * 2))
        NSColor(calibratedRed: 1.0, green: 0.45, blue: 0.15, alpha: alpha).setFill()
        glow.fill()
    }

    NSGraphicsContext.restoreGraphicsState()

    // ---- 两缕飘烟（从烟头向上）----
    func wisp(_ p0: NSPoint, _ c1: NSPoint, _ c2: NSPoint, _ p1: NSPoint, width: CGFloat, alpha: CGFloat) {
        let path = NSBezierPath()
        path.move(to: p0)
        path.curve(to: p1, controlPoint1: c1, controlPoint2: c2)
        path.lineWidth = r(width)
        path.lineCapStyle = .round
        NSColor(calibratedWhite: 1.0, alpha: alpha).setStroke()
        path.stroke()
    }
    wisp(NSPoint(x: r(268), y: r(445)),
         NSPoint(x: r(210), y: r(520)), NSPoint(x: r(320), y: r(555)),
         NSPoint(x: r(262), y: r(640)), width: 26, alpha: 0.42)
    wisp(NSPoint(x: r(316), y: r(445)),
         NSPoint(x: r(280), y: r(505)), NSPoint(x: r(370), y: r(540)),
         NSPoint(x: r(330), y: r(615)), width: 18, alpha: 0.26)

    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write(Data("render failed at \(px)\n".utf8))
        return Data()
    }
    return png
}

let variants: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

for (px, name) in variants {
    let data = render(px)
    try? data.write(to: URL(fileURLWithPath: outDir).appendingPathComponent(name))
}

print("iconset written to \(outDir)")
