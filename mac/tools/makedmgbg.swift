import AppKit
import Foundation

// DMG 背景图：660×420 pt，@2x 输出 1320×840 px
// 左侧留给 SmokeLog.app 图标位（170,210），右侧留给 Applications（490,210），中间画一个橙色箭头

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "dmg-bg.png"

let W: CGFloat = 660, H: CGFloat = 420
let s: CGFloat = 2                       // Retina 2x
let pxW = Int(W * s), pxH = Int(H * s)

let image = NSImage(size: NSSize(width: pxW, height: pxH))
image.lockFocus()

func p(_ v: CGFloat) -> CGFloat { v * s }

// ---- 背景：深色竖向渐变 ----
NSGradient(colors: [
    NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.14, alpha: 1),
    NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.08, alpha: 1),
])!.draw(in: NSRect(x: 0, y: 0, width: p(W), height: p(H)), angle: -90)

// 顶部微光，避免死板
NSGradient(colors: [
    NSColor(calibratedWhite: 1.0, alpha: 0.06),
    NSColor(calibratedWhite: 1.0, alpha: 0.0),
])!.draw(in: NSRect(x: 0, y: p(H - 150), width: p(W), height: p(150)), angle: -90)

// ---- 标题 ----
let title = "SmokeLog" as NSString
let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: p(22), weight: .semibold),
    .foregroundColor: NSColor(calibratedWhite: 0.96, alpha: 1),
    .kern: p(0.3),
]
let titleSize = title.size(withAttributes: titleAttrs)
title.draw(at: NSPoint(x: (p(W) - titleSize.width) / 2, y: p(H - 62)), withAttributes: titleAttrs)

// ---- 副标题 ----
let sub = "把左边的 App 拖到右边的 Applications 文件夹" as NSString
let subAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: p(12), weight: .regular),
    .foregroundColor: NSColor(calibratedWhite: 1.0, alpha: 0.45),
]
let subSize = sub.size(withAttributes: subAttrs)
sub.draw(at: NSPoint(x: (p(W) - subSize.width) / 2, y: p(H - 84)), withAttributes: subAttrs)

// ---- 中间箭头（从图标位指向 Applications）----
let accent = NSColor(calibratedRed: 0.85, green: 0.35, blue: 0.19, alpha: 1)
let yMid = p(210)
let x0 = p(258), x1 = p(400)
let shaftH = p(3)

// 箭杆
let shaft = NSBezierPath(roundedRect: NSRect(x: x0, y: yMid - shaftH / 2,
                                             width: x1 - x0 - p(10), height: shaftH),
                         xRadius: shaftH / 2, yRadius: shaftH / 2)
accent.setFill()
shaft.fill()

// 箭头
let head = NSBezierPath()
head.move(to: NSPoint(x: x1, y: yMid))
head.line(to: NSPoint(x: x1 - p(14), y: yMid + p(9)))
head.line(to: NSPoint(x: x1 - p(14), y: yMid - p(9)))
head.close()
accent.setFill()
head.fill()

// 箭头下方的提示文字
let hint = "装好后从 Applications 打开" as NSString
let hintAttrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: p(10.5), weight: .regular),
    .foregroundColor: NSColor(calibratedWhite: 1.0, alpha: 0.28),
]
let hintSize = hint.size(withAttributes: hintAttrs)
hint.draw(at: NSPoint(x: (p(W) - hintSize.width) / 2, y: p(150)), withAttributes: hintAttrs)

// ---- 底部分隔线 ----
NSColor(calibratedWhite: 1.0, alpha: 0.06).setFill()
NSRect(x: p(40), y: p(40), width: p(W - 80), height: p(1)).fill()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("background render failed\n".utf8))
    exit(1)
}
try? png.write(to: URL(fileURLWithPath: outPath))
print("background written to \(outPath) (\(pxW)x\(pxH))")
