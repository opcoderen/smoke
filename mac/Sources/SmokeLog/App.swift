import AppKit
import SwiftUI

@main
struct SmokeLogMain {
    @MainActor
    static func main() {
        if CommandLine.arguments.contains("--selftest") {
            SelfTest.run()
            exit(0)
        }

        // 诊断用：把面板离屏渲染成 PNG，方便在没有截屏权限时检查布局
        if CommandLine.arguments.contains("--render-panel") {
            let host = NSHostingView(rootView: PanelView().environmentObject(Store.shared))
            host.frame = NSRect(x: 0, y: 0, width: 320, height: 470)
            let win = NSWindow(
                contentRect: host.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            win.contentView = host
            win.orderFront(nil)
            RunLoop.main.run(until: Date().addingTimeInterval(1.5))
            if let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) {
                host.cacheDisplay(in: host.bounds, to: rep)
                if let png = rep.representation(using: .png, properties: [:]) {
                    try? png.write(to: URL(fileURLWithPath: "/tmp/panel_render.png"))
                    print("rendered \(png.count) bytes")
                }
            }
            exit(0)
        }

        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
