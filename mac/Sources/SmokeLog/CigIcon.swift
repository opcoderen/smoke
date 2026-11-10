import AppKit

// 自绘香烟图标（SF Symbols 里没有香烟，smoke.fill 是云朵）
// 画法：火头薄片 | 烟身 | 过滤嘴 三段直角拼接，段间留细缝，上方两缕飘烟
enum CigIcon {
    /// 菜单栏用：18pt 模板图（黑+alpha，系统自动适配明暗菜单栏）
    static func statusBarTemplate() -> NSImage {
        let px = 36  // 2x
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        )!
        // 注意：rep.size 保持 = 像素数（用户坐标 1 单位 = 1 像素），
        // NSImage 尺寸另设 18pt，36px 位图即 2x 高清
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        defer { NSGraphicsContext.restoreGraphicsState() }

        NSColor.black.setFill()

        // 火头薄片（最左，点燃端）
        NSBezierPath(roundedRect: NSRect(x: 4.8, y: 12, width: 1.8, height: 5),
                     xRadius: 0.9, yRadius: 0.9).fill()
        // 烟身（直角拼接）
        NSRect(x: 7.3, y: 12, width: 16.6, height: 5).fill()
        // 过滤嘴：直角矩形 + 右端半圆头
        NSRect(x: 24.6, y: 12, width: 4.0, height: 5).fill()
        NSBezierPath(ovalIn: NSRect(x: 26.1, y: 12, width: 5, height: 5)).fill()

        // 飘烟：主缕 S 形 + 侧缕（半透明）
        let s1 = NSBezierPath()
        s1.move(to: NSPoint(x: 7.5, y: 19.5))
        s1.curve(to: NSPoint(x: 10.5, y: 26.5),
                 controlPoint1: NSPoint(x: 4.5, y: 22),
                 controlPoint2: NSPoint(x: 10, y: 23))
        s1.curve(to: NSPoint(x: 9, y: 33.5),
                 controlPoint1: NSPoint(x: 11, y: 30.5),
                 controlPoint2: NSPoint(x: 8, y: 31.5))
        s1.lineWidth = 1.8
        s1.lineCapStyle = .round
        NSColor.black.setStroke()
        s1.stroke()

        let s2 = NSBezierPath()
        s2.move(to: NSPoint(x: 14, y: 20))
        s2.curve(to: NSPoint(x: 16, y: 26),
                 controlPoint1: NSPoint(x: 12.5, y: 22.5),
                 controlPoint2: NSPoint(x: 16, y: 23.5))
        s2.lineWidth = 1.5
        s2.lineCapStyle = .round
        NSColor.black.withAlphaComponent(0.65).setStroke()
        s2.stroke()

        let img = NSImage(size: NSSize(width: 18, height: 18))
        img.addRepresentation(rep)
        img.isTemplate = true
        return img
    }
}
