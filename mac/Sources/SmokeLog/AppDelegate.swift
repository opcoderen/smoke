import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMainMenu()
        controller = StatusBarController()
    }

    /// .accessory 模式默认没有 App 菜单，⌘Q 不生效。这里补一个最小菜单，
    /// 让 App 处于激活状态（面板/设置窗口打开）时可以用 ⌘Q 退出。
    private func buildMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(
            withTitle: "退出 抽烟记录",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}
