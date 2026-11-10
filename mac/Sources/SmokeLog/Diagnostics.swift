import AppKit

/// 轻量日志：写到 ~/Library/Logs/SmokeLog.log，方便在别的机器上排查"没图标/连不上"
enum Diagnostics {
    static var logPath: String {
        let dir = (NSHomeDirectory() as NSString).appendingPathComponent("Library/Logs")
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        return (dir as NSString).appendingPathComponent("SmokeLog.log")
    }

    static func log(_ text: String) {
        let fmt = DateFormatter()
        fmt.dateFormat = "MM-dd HH:mm:ss"
        let line = "[\(fmt.string(from: Date()))] \(text)\n"

        // 超过 200KB 就重置，避免无限增长
        if let attrs = try? FileManager.default.attributesOfItem(atPath: logPath),
           let size = attrs[.size] as? Int, size > 200_000 {
            try? FileManager.default.removeItem(atPath: logPath)
        }

        if let handle = FileHandle(forWritingAtPath: logPath) {
            handle.seekToEndOfFile()
            handle.write(Data(line.utf8))
            handle.closeFile()
        } else {
            try? line.write(toFile: logPath, atomically: true, encoding: .utf8)
        }
    }

    static func logLaunch(statusButton: NSStatusBarButton?, image: NSImage?) {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        var arch = "unknown"
        #if arch(arm64)
        arch = "arm64"
        #elseif arch(x86_64)
        arch = "x86_64"
        #endif

        log("—— 启动 —— macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion) · \(arch)"
            + " · app \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?")")
        log("菜单栏按钮：\(statusButton == nil ? "nil（创建失败）" : "ok")"
            + " · 图标：\(image.map { "\(Int($0.size.width))x\(Int($0.size.height))" } ?? "nil")")

        if let screen = NSScreen.main {
            log("屏幕：\(Int(screen.frame.width))x\(Int(screen.frame.height)) 可见菜单栏宽 \(Int(screen.visibleFrame.width))")
        }
        if let button = statusButton {
            log("按钮：title=「\(button.title)」 可见=\(button.isHidden ? "否" : "是") 宽度=\(Int(button.frame.width))")
        }
        log("服务器：\(Settings.endpoint) · 密码：\(Settings.password.isEmpty ? "未设置" : "已设置")")
    }
}
